local BB = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local DataStorage = require("datastorage")
local Device = require("device")
local Font = require("ui/font")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local LuaSettings = require("luasettings")
local Network = require("ui/network/manager")
local Size = require("ui/size")
local TextViewer = require("ui/widget/textviewer")
local UI = require("ui/uimanager")
local Widget = require("ui/widget/container/widgetcontainer")
local Screen = Device.screen

local root = debug.getinfo(1,"S").source:gsub("^@",""):gsub("[/\\]main%.lua$","")
local version = dofile(root.."/_meta.lua").version
local App = Widget:extend{name="gocmuc",is_doc_only=false}

function App:init()
    self.data = LuaSettings:open(DataStorage:getSettingsDir().."/gocmuc.lua")
    self.ui.menu:registerToMainMenu(self)
end

function App:addToMainMenu(menu)
    menu.gocmuc={text="Góc Mực",sorting_hint="tools",callback=function()
        UI:nextTick(function() self:home() end)
    end}
end

function App:read(key, default)
    return self.data:readSetting(key,default)
end

function App:save(key, value)
    self.data:saveSetting(key,value)
    self.data:flush()
end

function App:close()
    if self.window then
        local old=self.window
        self.window=nil
        UI:close(old)
    end
end

function App:notice(text)
    UI:show(InfoMessage:new{text=text,timeout=4})
end

function App:button(text,action,fields)
    local item=fields or {}
    item.text,item.callback=text,action
    return item
end

function App:show(title, rows, back, options)
    self:close()
    options=options or {}
    if back then
        rows[#rows+1]={{text=options.back_text or "‹ Quay lại",callback=back}}
    end
    local window=ButtonDialog:new{
        title=title, buttons=rows, width_factor=options.width_factor or 0.94,
        title_face=options.title_face, dismissable=true,
        tap_close_callback=function()
            self.window=nil
            if back then UI:nextTick(back) end
        end,
    }
    self.window=window
    UI:show(window)
    return window
end

function App:menu(title, choices, back)
    local rows={}
    for _,option in ipairs(choices) do
        rows[#rows+1]={{text=option[1],callback=option[2],align="left",font_size=18}}
    end
    return self:show(title,rows,back)
end

function App:view(title,text,back,options)
    self:close()
    options=options or {}
    local window
    local function leave()
        if self.window==window then self.window=nil end
        UI:close(window)
        if back then UI:nextTick(back) end
    end
    local rows=options.rows or {}
    rows[#rows+1]={{text="‹ Quay lại",callback=leave}}
    window=TextViewer:new{title=title,title_multilines=true,text=text,show_menu=false,
        text_format="txt",buttons_table=rows,page_turn_callback_prev=options.prev,page_turn_callback_next=options.next,
        close_callback=function()
            if self.window==window then
                self.window=nil
                if back then UI:nextTick(back) end
            end
        end}
    self.window=window
    UI:show(window)
end

function App:prompt(title, desc, initial, cb, options)
    options=options or {}
    local panel
    panel=InputDialog:new{
        title=title,description=desc,input=initial or "",input_type=options.number and "number" or nil,
        allow_newline=options.multiline or false,buttons={{{text="Hủy",callback=function() UI:close(panel) end},
        {text=options.action or "OK",is_enter_default=not options.multiline,callback=function()
            local value=panel:getInputText():match("^%s*(.-)%s*$")
            UI:close(panel)
            cb(value)
        end}}}
    }
    UI:show(panel)
    panel:onShowKeyboard()
end

function App:online(fn, local_network)
    local window=self.window
    local connect=local_network and Network.runWhenConnected or Network.runWhenOnline
    connect(Network,function()
        if self.window==window then UI:nextTick(function()
            if self.window==window then fn() end
        end) end
    end)
end

function App:grid(size, title, rows, render, back)
    local side=math.min(Screen:getWidth(),Screen:getHeight())
    local cell=math.floor(math.min(side*0.89,Screen:getHeight()*0.73)/size)
    local label_height=math.max(8,cell-2*Size.padding.buttontable)
    local font=math.max(9,math.floor(cell*0.55*160/Screen:getDPI()))
    local grid={}
    for y=1,size do
        grid[y]={}
        for x=1,size do
            local text,callback,shade,symbol=render(x,y)
            grid[y][x]=self:button(text,callback,{
                font_face=symbol and "freefont/FreeSerif.ttf" or nil, font_size=font,
                font_bold=false,height=label_height,background=shade and BB.COLOR_GRAY_D or BB.COLOR_WHITE,
                enabled=callback~=nil,
            })
        end
    end
    for _,row in ipairs(rows) do grid[#grid+1]=row end
    return self:show(title,grid,back,{width_factor=0.96})
end

local Lunar=dofile(root.."/lunar.lua")
local extras={Lunar=Lunar,root=root,UI=UI,version=version}
for _,file in ipairs({"games","learn","daily","utilities","updates"}) do
    dofile(root.."/"..file..".lua")(App,extras)
end

function App:home()
    local date=os.date("*t")
    local ok,power=pcall(function() return Device:getPowerDevice():getCapacity() end)
    local title=os.date("%H:%M").."\nGóc Mực\n"..os.date("%d/%m/%Y").."  ·  "..(ok and power and power.."%" or "Pin —")
        .."\n"..Lunar.label(date.day,date.month,date.year)
    local function b(label,name) return self:button(label,function() self[name](self) end,{font_size=17,height=Screen:scaleBySize(47)}) end
    local window=self:show(title,{
        {b("Cờ vua","chessMenu"),b("Toán tư duy","mathMenu")},
        {b("Cờ caro","caroMenu"),b("Đọc báo","newsMenu")},
        {b("Lịch để bàn","calendar"),b("Hợp âm","chordMenu")},
        {b("Bé đọc","kidsMenu"),b("Tiện ích","utilities")},
        {b("Cập nhật","updates"),b("Giới thiệu","credits")},
        {b("Về KOReader","close")},
    },nil,{title_face=Font:getFace("smalltfont",23)})
    UI:scheduleIn(60-date.sec,function()
        if self.window==window then self:home() end
    end)
end

function App:credits()
    self:view("Giới thiệu Góc Mực",
        "Góc Mực · "..version.."\nDự án của @ngiangbao.\n\nCảm hứng: bài chia sẻ về góc học tập trên Kindle của Nguyễn Việt An.\n\n"
        .."Cờ vua · T4 e-reader OS do Hoàng Tuấn (@hoangtuan2k5) phát triển. Cảm ơn tác giả đã phát hành T4 cho cộng đồng Kindle.\n"
        .."github.com/hoangtuan2k5/t4-e-reader-os-releases\n\n"
        .."Tùy chọn Lichess: Ink Knight của Beater Studios.\n"
        .."Hợp âm: nhập ký hiệu theo URL từ Hợp Âm Chuẩn.\n"
        .."Lịch âm: phương pháp thiên văn do Hồ Ngọc Đức công bố.\nDự báo: Open-Meteo. Giá vàng: Vang.today.",
        function() self:home() end)
end

return App
