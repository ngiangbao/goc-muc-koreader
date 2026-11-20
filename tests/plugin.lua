local root=arg[1] or "gocmuc.koplugin"
local adapter={}
local settings={}
local deferred={}
local ui={
    show=function() end, close=function() end,
    nextTick=function(_,cb) cb() end,
    scheduleIn=function(_,_,cb) deferred[#deferred+1]=cb end,
}
local screen_w,screen_h=1072,1448
local screen={getWidth=function() return screen_w end,getHeight=function() return screen_h end,
    getDPI=function() return 300 end,scaleBySize=function(_,s) return s end}
local widget={new=function(_,t) return t end}
local input={
    extend=function(_,methods)
        methods.new=function(class,props)
            props=setmetatable(props,{__index=class})
            props:init()
            return props
        end
        return methods
    end,
}
local text={new=function(_,t)
    t.getSize=function(self) return {w=math.min(self.max_width,#self.text*self.face.size/2),h=self.face.size} end
    t.paintTo=function() end
    t.free=function() end
    return t
end}
local package_modules={
    ["ffi/blitbuffer"]={COLOR_BLACK=0,COLOR_GRAY_D=221,COLOR_GRAY_E=238,COLOR_GRAY=128,COLOR_WHITE=255},
    ["ui/widget/buttondialog"]=widget,["ui/widget/textviewer"]=widget,
    ["ui/widget/infomessage"]=widget,["ui/widget/confirmbox"]=widget,
    ["ui/widget/inputdialog"]={new=function(_,t) t.onShowKeyboard=function() end; return t end},
    ["datastorage"]={getSettingsDir=function() return "." end},
    ["device"]={screen=screen,hasKeys=function() return false end,getPowerDevice=function()
        return {getCapacity=function() return 88 end}
    end},
    ["ui/font"]={getFace=function(_,_,size) return {size=size} end},
    ["ui/geometry"]=widget,["ui/gesturerange"]=widget,
    ["ui/widget/container/inputcontainer"]=input,["ui/widget/textwidget"]=text,
    ["ui/size"]={padding={buttontable=6}},
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
    ["ltn12"]={source={string=function() end}},
    ["socketutil"]={set_timeout=function() end},
    ["socket.http"]={request=function(opts)
        opts.sink("<rss><channel><item><title>A &amp; B</title><link>https://example.com/a</link>"
            .."<description><![CDATA[<p>Some notes</p>]]></description></item></channel></rss>")
        return 1,200
    end},
    ["json"]={encode=function() return "{}" end,decode=function() return {} end},
}
for name,module in pairs(package_modules) do package.loaded[name]=module end

local App=dofile(root.."/main.lua")
local app=setmetatable({ui={menu={registerToMainMenu=function() end}}},{__index=App})
app:init()
app:home()
assert(app.window.battery=="Pin 88%" and app.window.page==1)
local seen={}
for page=1,2 do
    app:home(page)
    assert(#app.window.tiles==4)
    for _,tile in ipairs(app.window.tiles) do
        assert(tile.w==tile.h and tile.w>400 and tile.r>0)
        assert(tile.x>=0 and tile.y+tile.h<=screen_h and tile.x+tile.w<=screen_w)
        assert(not seen[tile.icon])
        seen[tile.icon]=true
    end
end
local painted=0
local bb={paintRect=function() end,paintRoundedRect=function() end,
    paintBorder=function() end,paintCircle=function() painted=painted+1 end}
app.window:paintTo(bb,0,0)
assert(painted>100)
app.window:onTileSwipe(nil,{direction="east"})
assert(app.window.page==1)
local first=app.window.tiles[1]
app.window:onTileTap(nil,{pos={x=first.x+5,y=first.y+5}})
assert(app.window.title=="Cờ vua")
app:home(2)
screen_w,screen_h=1448,1072
app.window:onSetDimensions()
assert(app.window.page==2 and app.window.dimen.w==1448)
for _,tile in ipairs(app.window.tiles) do assert(tile.y+tile.h<screen_h) end
screen_w,screen_h=1072,1448

app:chessMenu()
app.window.buttons[1][1].callback()
assert(app.window.text:find("hoangtuan2k5",1,true))
local tab
adapter["t4-e-reader-os"]={open=function(_,name) tab=name end}
app:openT4("chess")
assert(tab=="chess" and not app.window)
app:updates()
app.window.buttons[2][1].callback()
assert(tab=="settings" and not app.window)
local opened=false
adapter.ink_knight={addToMainMenu=function(_,menu) menu.ink_knight={callback=function() opened=true end} end}
app:openInkKnight()
assert(opened)

app:kidsLevels()
app.window.buttons[1][1].callback()
app.window.buttons[7][5].callback()
assert(app.window.buttons[5][5].text=="•")
app.window.buttons[5][5].callback()
app.window.buttons[9][1].callback()
assert(app.window.buttons[7][5].text=="♙")

app:mathModes(4)
app.window.buttons[1][1].callback()
assert(app.window.title:find("Câu 1/10",1,true))
app.window.buttons_table[1][1].callback()
assert(app.window.text:find("Đáp án",1,true))
app.window.buttons_table[1][1].callback()
assert(app.window.title:find("Câu 2/10",1,true))

app:caroMenu()
app.window.buttons[1][1].callback()
for i=3,6 do
    app.window.buttons[7][i].callback()
    app.window.buttons[9][i].callback()
end
app.window.buttons[7][7].callback()
assert(app.window.title:find("X thắng",1,true))

app:chordMenu()
app.window.buttons[3][1].callback()
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
local xml=assert(Net.request("https://example.com/feed"))
local items=Net.rss(xml)
assert(#items==1 and items[1].title=="A & B" and items[1].text=="Some notes")
assert(Net.article("<article><p>Hello <strong>from</strong> a tested article here.</p></article>"))
app:newsMenu()
app.window.buttons[2][1].callback()
app.window.buttons[2][1].callback()
assert(app.window.text:find("Some notes",1,true))

app:utilities()
assert(#app.window.buttons==16)
print("KOReader widget mocks: home, T4 handoff, Lichess handoff, games, quiz, chords, news and tools passed.")
