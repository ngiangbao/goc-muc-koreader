local root=arg[1] or "gocmuc.koplugin"
local adapter={}
local shown
local settings={}
local deferred={}
local ui={
    show=function(_,widget) shown=widget end, close=function() end,
    nextTick=function(_,cb) cb() end,
    scheduleIn=function(_,_,cb) deferred[#deferred+1]=cb end,
}
local screen_w,screen_h=1072,1448
local screen={getWidth=function() return screen_w end,getHeight=function() return screen_h end,
    getDPI=function() return 300 end,scaleBySize=function(_,s) return s end}
local widget={new=function(_,t) return t end}
local input={}
function input:extend(methods)
        methods.new=function(class,props)
            props=setmetatable(props,{__index=class})
            props:init()
            return props
        end
        return setmetatable(methods,{__index=self})
end
local text={new=function(_,t)
    t.getSize=function(self)
        return {w=self.width or math.min(self.max_width,#self.text*self.face.size/2),h=self.face.size}
    end
    t.paintTo=function() end
    t.free=function() end
    return t
end}
local package_modules={
    ["ffi/blitbuffer"]={COLOR_BLACK=0,COLOR_GRAY_D=221,COLOR_GRAY_E=238,COLOR_GRAY=128,COLOR_WHITE=255},
    ["ui/widget/buttondialog"]=widget,["ui/widget/textviewer"]=widget,
    ["ui/widget/infomessage"]=widget,["ui/widget/confirmbox"]=widget,
    ["ui/widget/inputdialog"]={new=function(_,t)
        t.onShowKeyboard=function() end
        t.getInputText=function() return "Ten bai thu" end
        return t
    end},
    ["datastorage"]={getSettingsDir=function() return "." end},
    ["device"]={screen=screen,hasKeys=function() return false end,getPowerDevice=function()
        return {getCapacity=function() return 88 end}
    end},
    ["ui/font"]={getFace=function(_,_,size) return {size=size} end},
    ["ui/geometry"]=widget,["ui/gesturerange"]=widget,
    ["ui/widget/container/inputcontainer"]=input,["ui/widget/textwidget"]=text,["ui/widget/textboxwidget"]=text,
    ["ui/size"]={padding={buttontable=6},border={window=2}},
    ["luasettings"]={open=function() return {
        readSetting=function(_,key,default) return settings[key] or default end,
        saveSetting=function(_,key,value) settings[key]=value end,
        flush=function() end,
    } end},
    ["ui/network/manager"]={runWhenOnline=function(_,fn) fn() end,runWhenConnected=function(_,fn) fn() end},
    ["ui/uimanager"]=ui,
    ["ui/widget/container/widgetcontainer"]={extend=function(_,t) return t end},
    ["logger"]={warn=function() end},
    ["pluginloader"]={getPluginInstance=function(_,name) return adapter[name] end},
    ["ltn12"]={source={string=function(v) return v end}},
    ["socketutil"]={set_timeout=function() end},
    ["socket.http"]={request=function(opts)
        if opts.url=="https://hopamchuan.com/autocomplete" then
            assert(opts.method=="POST" and opts.source=="q=Ten%20bai%20thu")
            assert(opts.headers["content-type"]=="application/x-www-form-urlencoded")
            opts.sink("song_results")
        elseif opts.url=="https://hopamchuan.com/song/123/ten-bai-thu" then
            opts.sink('<h1 id="song-title"><span>Tên bài thử</span></h1>'
                ..'<div class="chord_lyric_line">Một lời thử <span class="hopamchuan_chord">C#m7</span></div>')
        else
            opts.sink("<rss><channel><item><title>A &amp; B</title><link>https://example.com/a</link>"
            .."<description><![CDATA[<p>Some notes</p>]]></description></item></channel></rss>")
        end
        return 1,200
    end},
    ["json"]={encode=function() return "{}" end,decode=function(v)
        if v=="song_results" then
            return {success=true,data={{_title="Tên bài thử",_singers="Tác giả thử",
                _url="/song/123/ten-bai-thu",_lyric="Không lấy đoạn này"}}}
        end
        return {}
    end},
}
for name,module in pairs(package_modules) do package.loaded[name]=module end

local App=dofile(root.."/main.lua")
local app=setmetatable({ui={menu={registerToMainMenu=function() end}}},{__index=App})
app:init()
app:home()
assert(app.window.battery=="Pin 88%" and #app.window.tiles==20)
local seen_x,seen_y={},{}
for _,tile in ipairs(app.window.tiles) do
    assert(tile.w==tile.h and tile.w>190 and tile.r>0)
    assert(tile.x>=0 and tile.y+tile.h<=screen_h and tile.x+tile.w<=screen_w)
    seen_x[tile.x],seen_y[tile.y]=true,true
end
local function labelFor(window,text)
    for _,label in ipairs(window.labels) do
        if label.widget.text==text then return label.widget end
    end
end
assert(labelFor(app.window,"Cờ vua").bgcolor==app.window.tiles[1].fill)
local x_count,y_count=0,0
for _ in pairs(seen_x) do x_count=x_count+1 end
for _ in pairs(seen_y) do y_count=y_count+1 end
assert(x_count==4 and y_count==5)
local painted=0
local bb={paintRect=function() end,paintRoundedRect=function() end,
    paintBorder=function() end,paintCircle=function() painted=painted+1 end}
app.window:paintTo(bb,0,0)
assert(painted>100)
local first=app.window.tiles[1]
app.window:onTileTap(nil,{pos={x=first.x+5,y=first.y+5}})
assert(app.window.title=="Cờ vua")
app:home()
screen_w,screen_h=1448,1072
app.window:onSetDimensions()
assert(#app.window.tiles==20 and app.window.dimen.w==1448)
for _,tile in ipairs(app.window.tiles) do assert(tile.y+tile.h<screen_h) end
screen_w,screen_h=1072,1448

app:chessMenu()
app.window:paintTo(bb,0,0)
assert(labelFor(app.window,"Cờ vua T4\nHoàng Tuấn").bgcolor==app.window.tiles[1].fill)
local nav=app.window.targets[1]
app.window:onTileTap(nil,{pos={x=nav.x+nav.w/2,y=nav.y+nav.h/2}})
assert(#app.window.tiles==20)
app:chessMenu()
app.window.choices[1][2]()
assert(app.window.text:find("hoangtuan2k5",1,true))
local tab
adapter["t4-e-reader-os"]={open=function(_,name) tab=name end}
app:openT4("chess")
assert(tab=="chess" and #app.window.tiles==20)
app:updates()
app.window.choices[2][2]()
assert(tab=="settings" and #app.window.tiles==20)
local opened=false
adapter.ink_knight={addToMainMenu=function(_,menu) menu.ink_knight={callback=function() opened=true end} end}
app:openInkKnight()
assert(opened and #app.window.tiles==20)

app:kidsLevels()
app.window.choices[1][2]()
app.window.buttons[7][5].callback()
assert(app.window.buttons[5][5].text=="•")
app.window.buttons[5][5].callback()
app.window.buttons[9][1].callback()
assert(app.window.buttons[7][5].text=="♙")

app:mathModes(4)
app.window.choices[1][2]()
assert(app.window.title:find("Câu 1/10",1,true))
app.window.buttons_table[1][1].callback()
assert(app.window.text:find("Đáp án",1,true))
app.window.buttons_table[1][1].callback()
assert(app.window.title:find("Câu 2/10",1,true))

app:caroMenu()
app.window.choices[1][2]()
for i=3,6 do
    app.window.buttons[7][i].callback()
    app.window.buttons[9][i].callback()
end
app.window.buttons[7][7].callback()
assert(app.window.title:find("X thắng",1,true))
app.window:onCloseSurface()
assert(#app.window.tiles==20)

app:chordMenu()
app.window.choices[4][2]()
app.window.buttons_table[1][3].callback()
assert(app.window.text:find("[C#]",1,true))
assert(app.window.text:find("[C#/F]",1,true))

local Net=dofile(root.."/net.lua")
local HAC=dofile(root.."/hopamchuan.lua")
assert(not HAC.url("https://hopamchuan.com.evil.test/song/12/example"))
assert(not HAC.url("https://hopamchuan.com/song/12/../../example"))
assert(HAC.url("https://hopamchuan.com/song/123/test/?fbclid=example")=="https://hopamchuan.com/song/123/test/")
local page='<h1 id="song-title"><span>Tên bài thử</span></h1>'
    ..'<div class="chord_lyric_line">Một lời thử <span class="hopamchuan_chord">C#m7</span> '
    ..'<span class="hopamchuan_chord">D/F#</span></div>'
local song=assert(HAC.parse(page,Net.clean))
assert(song.title=="Tên bài thử" and song.body=="[C#m7]  [D/F#]")
app:chordMenu()
app.window.choices[1][2]()
assert(shown.fullscreen)
shown.buttons[1][3].callback()
assert(app.window.title=="Kết quả tìm bài hát")
assert(app.window.choices[2][1]=="Tên bài thử\nTác giả thử")
app.window.choices[2][2]()
assert(app.window.text:find("[C#m7]",1,true))
assert(app.window.covers_fullscreen and not app.window.text:find("Một lời thử",1,true))
assert(#settings.chords==1 and settings.chords[1].body=="[C#m7]")
local xml=assert(Net.request("https://example.com/feed"))
local items=Net.rss(xml)
assert(#items==1 and items[1].title=="A & B" and items[1].text=="Some notes")
assert(Net.article("<article><p>Hello <strong>from</strong> a tested article here.</p></article>"))
app:newsMenu()
assert(app.window.covers_fullscreen and #app.window.tiles==6 and app.window.page_count==1)
app.window.choices[2][2]()
app.window.choices[2][2]()
assert(app.window.text:find("Some notes",1,true))
assert(app.window.covers_fullscreen and app.window.width==screen_w-4)
app.window.close_callback()
assert(#app.window.tiles==20)

app:utilities()
assert(#app.window.tiles==15 and app.window.page_count==1)
local choices={}
for i=1,21 do choices[i]={"Bài "..i,function() end,"news"} end
app:menu("Nhiều bài",choices,function() app:home() end)
assert(#app.window.tiles==20 and app.window.page_count==2)
app.window:onTileSwipe(nil,{direction="west"})
assert(app.window.page==2 and #app.window.tiles==1)
local today=os.time{year=2026,month=11,day=21,hour=12}
app:calendar(today)
app.window:paintTo(bb,0,0)
assert(app.window.covers_fullscreen and app.window.day_info.day==21 and #app.window.day_info.hours==6)
assert(labelFor(app.window,"Hôm nay").bgcolor==require("ffi/blitbuffer").COLOR_BLACK)
assert(labelFor(app.window,"Tháng 11 · 2026").bgcolor==require("ffi/blitbuffer").COLOR_GRAY_E)
app.window.open_month()
app.window:paintTo(bb,0,0)
assert(app.window.month_info.month==11 and #app.window.month_info.days==30)
assert(app.window.month_info.days[21].selected)
app.window.next()
assert(app.window.month_info.month==12)
app.window.month_info.days[4].open()
assert(app.window.day_info.day==4 and app.window.day_info.month==12)
app:museMenu()
assert(app.window.title=="Muse" and app.window.covers_fullscreen)
app.window.choices[3][2]()
assert(shown.title=="Địa chỉ cầu nối Muse" and shown.fullscreen)
shown.buttons[1][2].callback()
assert(#app.window.tiles==20)
print("KOReader widget mocks: 4 × 5 menus, matched text background, app exits, calendar, news, chord search and Muse passed.")
