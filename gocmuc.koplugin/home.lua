local BB = require("ffi/blitbuffer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local TextWidget = require("ui/widget/textwidget")
local UI = require("ui/uimanager")
local Device = require("device")
local Screen = Device.screen
local floor = math.floor

local Home = InputContainer:extend{covers_fullscreen=true}
local pages = {
    {
        {"Cờ vua","chessMenu","knight"}, {"Toán tư duy","mathMenu","math"},
        {"Cờ caro","caroMenu","caro"}, {"Đọc báo","newsMenu","news"},
    },
    {
        {"Lịch để bàn","calendar","calendar"}, {"Hợp âm","chordMenu","music"},
        {"Bé đọc","kidsMenu","book"}, {"Tiện ích","utilities","tools"},
    },
}

-- Original 24-unit icons drawn directly on the E Ink framebuffer.
local icons = {
    knight={
        {4,21,20,21,20,18,17,17,17,11,15,7,11,5,9,2,8,6,4,10,4,13,7,14,11,11,13,12,10,16,7,18,4,18,4,21},
        {10,8,10,8},
    },
    math={
        {5,4,19,4,19,20,5,20,5,4}, {8,8,16,8}, {12,6,12,10},
        {8,13,11,16}, {11,13,8,16}, {14,13,17,13}, {14,16,17,16},
    },
    caro={
        {8,3,8,21}, {16,3,16,21}, {3,8,21,8}, {3,16,21,16},
        {3,3,6,6}, {6,3,3,6}, {10,10,14,14}, {14,10,10,14},
        {18,18,21,18,21,21,18,21,18,18},
    },
    news={
        {4,4,19,4,19,19,17,21,4,21,4,4}, {19,8,22,8,22,19,20,21,17,21},
        {7,8,15,8}, {7,12,15,12}, {7,16,12,16},
    },
    calendar={
        {3,5,21,5,21,21,3,21,3,5}, {7,3,7,7}, {17,3,17,7},
        {3,10,21,10}, {8,14,8,14}, {12,14,12,14}, {16,14,16,14}, {8,17,8,17}, {12,17,12,17},
    },
    music={
        {9,18,9,6,20,3,20,15}, {9,9,20,6},
        {9,18,7,20,4,20,3,18,4,16,7,15,9,16,9,18},
        {20,15,18,17,15,17,14,15,15,13,18,12,20,13,20,15},
    },
    book={
        {12,6,9,4,3,4,3,18,9,18,12,20,15,18,21,18,21,4,15,4,12,6,12,20},
        {6,8,9,8}, {6,11,9,11}, {15,8,18,8}, {15,11,18,11},
    },
    tools={
        {5,3,5,21}, {12,3,12,21}, {19,3,19,21},
        {2,8,8,8}, {9,16,15,16}, {16,10,22,10},
    },
}

local function drawIcon(bb, name, x, y, size)
    local unit=size/24
    local radius=math.max(1,floor(unit*0.65))
    for _,path in ipairs(icons[name]) do
        for i=1,#path-2,2 do
            local ax,ay=path[i],path[i+1]
            local dx,dy=path[i+2]-ax,path[i+3]-ay
            local steps=math.max(1,math.ceil(math.max(math.abs(dx),math.abs(dy))*unit/radius))
            for step=0,steps do
                local px=x+floor((ax+dx*step/steps)*unit+0.5)
                local py=y+floor((ay+dy*step/steps)*unit+0.5)
                bb:paintCircle(px,py,radius,BB.COLOR_BLACK)
            end
        end
    end
end

function Home:label(text,x,y,w,h,px,opts)
    opts=opts or {}
    local font_scale=Screen:scaleBySize(100)/100
    local label=TextWidget:new{
        text=text,face=Font:getFace("ffont",math.max(8,floor(px/font_scale))),
        max_width=w,padding=0,bold=opts.bold,fgcolor=opts.light and BB.COLOR_WHITE or BB.COLOR_BLACK,
    }
    local span=label:getSize()
    local dx=opts.align=="left" and 0 or opts.align=="right" and w-span.w or floor((w-span.w)/2)
    self.labels[#self.labels+1]={widget=label,x=x+dx,y=y+floor((h-span.h)/2)}
end

function Home:build()
    local w,h=Screen:getWidth(),Screen:getHeight()
    self.dimen=Geom:new{w=w,h=h}
    self.labels,self.targets,self.tiles={}, {}, {}
    local unit=math.min(w,h)
    local s=function(fraction) return floor(unit*fraction) end
    local margin=s(0.048)
    local gap=math.max(4,s(0.022))
    local header=floor(h*0.20)
    local footer=floor(h*0.135)
    local side=floor(math.min((w-2*margin-gap)/2,(h-header-footer-2*gap)/2))
    local x0=floor((w-2*side-gap)/2)
    local body_align=floor((h-header-footer-2*side-gap)/2)
    local y0=header+body_align
    local root_width=w-2*margin
    self.line={x=margin,y=header-floor(gap/2),w=root_width,h=math.max(1,s(0.002))}

    local header_height=floor(header*0.32)
    self:label("GÓC MỰC",margin,gap,root_width,header_height,s(0.029),{align="left",bold=true})
    self:label(self.battery,margin,gap,root_width,header_height,s(0.025),{align="right",bold=true})
    local information_y=header_height+gap
    local information_h=header-information_y-gap
    local clock_w=floor(root_width*0.44)
    self:label(self.clock,margin,information_y,clock_w,information_h,
        math.min(s(0.112),floor(information_h*0.75)),{align="left",bold=true})
    self:label(self.date,margin+clock_w,information_y,root_width-clock_w,floor(information_h/2),
        math.min(s(0.038),floor(information_h*0.34)),{align="right",bold=true})
    self:label(self.lunar,margin+clock_w,information_y+floor(information_h/2),root_width-clock_w,
        floor(information_h/2),math.min(s(0.030),floor(information_h*0.30)),{align="right"})

    for index,app in ipairs(pages[self.page]) do
        local x=x0+((index-1)%2)*(side+gap)
        local y=y0+floor((index-1)/2)*(side+gap)
        local tile={x=x,y=y,w=side,h=side,r=floor(side*0.16),action=app[2],icon=app[3],
            shade=index==1 and BB.COLOR_GRAY_E or BB.COLOR_WHITE}
        self.targets[#self.targets+1]=tile
        self.tiles[#self.tiles+1]=tile
        local font_px=math.min(s(0.052),floor(side*0.135))
        self:label(app[1],x+floor(side*0.05),y+floor(side*0.60),floor(side*0.90),floor(side*0.24),
            font_px,{bold=true})
    end

    local nav_y=h-footer
    local nav_h=floor(footer*0.44)
    local nav_w=floor((root_width-gap)/2)
    self.tabs={}
    for i,name in ipairs({"Học & chơi","Hằng ngày"}) do
        local nav={x=margin+(i-1)*(nav_w+gap),y=nav_y,w=nav_w,h=nav_h,page=i}
        self.tabs[i]=nav
        self.targets[#self.targets+1]=nav
        self:label(name,nav.x,nav.y,nav.w,nav.h,math.min(s(0.034),floor(nav_h*0.53)),
            {bold=true,light=i==self.page})
    end

    local actions={{"Cập nhật","updates"},{"Giới thiệu","credits"},{"Về KOReader","close"}}
    local link_w=floor(root_width/3)
    local link_y=nav_y+nav_h+floor(gap/3)
    local link_h=h-link_y-floor(gap/4)
    for i,item in ipairs(actions) do
        local link={x=margin+(i-1)*link_w,y=link_y,w=link_w,h=link_h,action=item[2]}
        self.targets[#self.targets+1]=link
        self:label(item[1],link.x,link.y,link.w,link.h,math.min(s(0.028),floor(link_h*0.50)))
    end
    self.stroke=math.max(1,s(0.003))
    self.radius=s(0.016)
end

function Home:init()
    self:build()
    self.ges_events={
        TileTap={GestureRange:new{ges="tap",range=self.dimen}},
        TileSwipe={GestureRange:new{ges="swipe",range=self.dimen}},
    }
    if Device:hasKeys() then
        self.key_events.CloseHome={{Device.input.group.Back}}
    end
end

function Home:paintTo(bb,x,y)
    bb:paintRect(x,y,self.dimen.w,self.dimen.h,BB.COLOR_WHITE)
    local line=self.line
    bb:paintRect(x+line.x,y+line.y,line.w,line.h,BB.COLOR_GRAY)
    for _,tile in ipairs(self.tiles) do
        bb:paintRoundedRect(x+tile.x,y+tile.y,tile.w,tile.h,tile.shade,tile.r)
        bb:paintBorder(x+tile.x,y+tile.y,tile.w,tile.h,self.stroke,BB.COLOR_BLACK,tile.r,true)
        local icon_size=floor(tile.w*0.36)
        drawIcon(bb,tile.icon,x+tile.x+floor((tile.w-icon_size)/2),y+tile.y+floor(tile.h*0.16),icon_size)
    end
    for i,nav in ipairs(self.tabs) do
        if i==self.page then
            bb:paintRoundedRect(x+nav.x,y+nav.y,nav.w,nav.h,BB.COLOR_BLACK,self.radius)
        else
            bb:paintBorder(x+nav.x,y+nav.y,nav.w,nav.h,self.stroke,BB.COLOR_BLACK,self.radius,true)
        end
    end
    for _,item in ipairs(self.labels) do item.widget:paintTo(bb,x+item.x,y+item.y) end
end

function Home:onTileTap(_,gesture)
    local x,y=gesture.pos.x,gesture.pos.y
    for _,item in ipairs(self.targets) do
        if x>=item.x and x<item.x+item.w and y>=item.y and y<item.y+item.h then
            if item.action then self.app[item.action](self.app)
            elseif item.page~=self.page then self.app:home(item.page) end
            break
        end
    end
    return true
end

function Home:onTileSwipe(_,gesture)
    if gesture.direction=="west" and self.page==1 then self.app:home(2)
    elseif gesture.direction=="east" and self.page==2 then self.app:home(1) end
    return true
end

function Home:onSetDimensions()
    if Screen:getWidth()~=self.dimen.w or Screen:getHeight()~=self.dimen.h then
        UI:nextTick(function()
            if self.app.window==self then self.app:home(self.page) end
        end)
    end
end

function Home:onCloseHome()
    self.app:close()
    return true
end

function Home:onShow()
    UI:setDirty(self,"ui")
end

function Home:onCloseWidget()
    for _,item in ipairs(self.labels) do item.widget:free() end
    UI:setDirty(nil,"ui")
end

return Home
