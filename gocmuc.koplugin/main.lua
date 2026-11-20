local BB = require("ffi/blitbuffer")
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
local Pages = dofile(root.."/pages.lua")
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

function App:openPage(kind,options)
    self:close()
    options.app=self
    local window=Pages[kind]:new(options)
    self.window=window
    UI:show(window)
    return window
end

function App:show(title, rows, back, options)
    options=options or {}
    return self:openPage("Controls",{title=title,buttons=rows,back=back,back_text=options.back_text,
        square_count=options.square_count,icon=options.icon,
        redraw=function() self:show(title,rows,back,options) end})
end

function App:menu(title, choices, back, options, page)
    options=options or {}
    return self:openPage("Menu",{title=title,choices=choices,back=back,style=options.style,
        subtitle=options.subtitle,icon=options.icon,page=page,
        redraw=function(next_page) self:menu(title,choices,back,options,next_page) end})
end

local function styleButtons(table_widget)
    if not table_widget then return end
    for _,row in ipairs(table_widget.buttons_layout or {}) do
        for _,button in pairs(row) do
            if button.frame then
                button.frame.background=BB.COLOR_GRAY_E
                button.frame.radius=Screen:scaleBySize(11)
            end
        end
    end
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
    local rows={}
    for _,row in ipairs(options.rows or {}) do rows[#rows+1]=row end
    rows[#rows+1]={{text="‹ Quay lại",callback=leave}}
    local border=2*Size.border.window
    window=TextViewer:new{title=title,title_multilines=true,title_face=Font:getFace("ffont",24),
        width=Screen:getWidth()-border,height=Screen:getHeight()-border,
        covers_fullscreen=true,text=text,show_menu=false,
        text_format="txt",buttons_table=rows,page_turn_callback_prev=options.prev,page_turn_callback_next=options.next,
        close_callback=function()
            if self.window==window then
                self.window=nil
                if back then UI:nextTick(back) end
            end
        end}
    if window.frame then window.frame.radius=0 end
    styleButtons(window.button_table)
    self.window=window
    UI:show(window)
end

function App:prompt(title, desc, initial, cb, options)
    options=options or {}
    local panel
    panel=InputDialog:new{
        title=title,description=desc,input=initial or "",input_type=options.number and "number" or nil,
        fullscreen=true,
        allow_newline=options.multiline or false,buttons={{{text="Hủy",callback=function() UI:close(panel) end},
        {text=options.action or "OK",is_enter_default=not options.multiline,callback=function()
            local value=panel:getInputText():match("^%s*(.-)%s*$")
            UI:close(panel)
            cb(value)
        end}}}
    }
    UI:show(panel)
    panel:onShowKeyboard()
    styleButtons(panel.button_table)
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
    local grid={}
    for y=1,size do
        grid[y]={}
        for x=1,size do
            local text,callback,shade,symbol=render(x,y)
            grid[y][x]=self:button(text,callback,{
                font_face=symbol and "freefont/FreeSerif.ttf" or nil,
                font_bold=false,background=shade and BB.COLOR_GRAY_D or BB.COLOR_WHITE,
                enabled=callback~=nil,
            })
        end
    end
    for _,row in ipairs(rows) do grid[#grid+1]=row end
    return self:show(title,grid,back,{square_count=size})
end

local Lunar=dofile(root.."/lunar.lua")
local Home=dofile(root.."/home.lua")
local extras={Lunar=Lunar,root=root,UI=UI,version=version}
for _,file in ipairs({"games","learn","daily","utilities","updates","muse"}) do
    dofile(root.."/"..file..".lua")(App,extras)
end

function App:home()
    local date=os.date("*t")
    local ok,power=pcall(function() return Device:getPowerDevice():getCapacity() end)
    self:close()
    local window=Home:new{
        app=self,clock=os.date("%H:%M"),date=os.date("%d/%m/%Y"),
        lunar="Âm "..Lunar.label(date.day,date.month,date.year),
        battery=ok and power and "Pin "..power.."%" or "Pin —",
    }
    self.window=window
    UI:show(window)
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
