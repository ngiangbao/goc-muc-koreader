local root=arg[1] or "gocmuc.koplugin"
local adapter={}
local settings={}
local deferred={}
local ui={
    show=function() end, close=function() end,
    nextTick=function(_,cb) cb() end,
    scheduleIn=function(_,_,cb) deferred[#deferred+1]=cb end,
}
local screen={getWidth=function() return 1072 end,getHeight=function() return 1448 end,
    getDPI=function() return 300 end,scaleBySize=function(_,s) return s end}
local widget={new=function(_,t) return t end}
local package_modules={
    ["ffi/blitbuffer"]={COLOR_GRAY_D=1,COLOR_WHITE=0},
    ["ui/widget/buttondialog"]=widget,["ui/widget/textviewer"]=widget,
    ["ui/widget/infomessage"]=widget,
    ["ui/widget/inputdialog"]={new=function(_,t) t.onShowKeyboard=function() end; return t end},
    ["datastorage"]={getSettingsDir=function() return "." end},
    ["device"]={screen=screen,getPowerDevice=function()
        return {getCapacity=function() return 88 end}
    end},
    ["ui/font"]={getFace=function() return {} end},
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
assert(app.window.title:find("Góc Mực",1,true))
assert(app.window.title:find("88%",1,true))

app:chessMenu()
app.window.buttons[1][1].callback()
assert(app.window.text:find("hoangtuan2k5",1,true))
local tab
adapter["t4-e-reader-os"]={open=function(_,name) tab=name end}
app:openChessT4()
assert(tab=="chess" and not app.window)
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
app.window.buttons[2][1].callback()
app.window.buttons_table[1][3].callback()
assert(app.window.text:find("[C#]",1,true))
assert(app.window.text:find("[C#/F]",1,true))

local Net=dofile(root.."/net.lua")
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
