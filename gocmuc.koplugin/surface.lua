local BB=require("ffi/blitbuffer")
local Device=require("device")
local Font=require("ui/font")
local Geom=require("ui/geometry")
local GestureRange=require("ui/gesturerange")
local InputContainer=require("ui/widget/container/inputcontainer")
local TextWidget=require("ui/widget/textwidget")
local TextBoxWidget=require("ui/widget/textboxwidget")
local UI=require("ui/uimanager")
local Screen=Device.screen
local floor=math.floor

local Surface=InputContainer:extend{covers_fullscreen=true}
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
    book={
        {12,6,9,4,3,4,3,18,9,18,12,20,15,18,21,18,21,4,15,4,12,6,12,20},
        {6,8,9,8}, {6,11,9,11}, {15,8,18,8}, {15,11,18,11},
    },
    tools={
        {5,3,5,21}, {12,3,12,21}, {19,3,19,21},
        {2,8,8,8}, {9,16,15,16}, {16,10,22,10},
    },
    arrow={{8,5,15,12,8,19}},
    add={{5,12,19,12},{12,5,12,19}},
    clock={{12,3,18,5,21,11,19,18,13,21,6,19,3,13,5,6,12,3},{12,7,12,12,16,14}},
    cloud={{4,17,20,17,22,14,20,11,17,11,16,7,12,5,8,6,6,10,3,10,2,14,4,17}},
    coin={{6,8,18,8,21,12,18,16,6,16,3,12,6,8},{7,16,7,18,17,18,17,16}},
    list={{5,6,7,8,10,4},{12,6,20,6},{5,12,7,14,10,10},{12,12,20,12},{5,18,20,18}},
    link={{10,8,13,5,18,5,20,9,19,12,16,15},{8,9,4,13,4,17,8,20,13,19,16,16},{9,15,15,9}},
    dice={{4,4,20,4,20,20,4,20,4,4},{8,8,8,8},{12,12,12,12},{16,16,16,16}},
    water={{12,3,17,10,20,15,18,20,12,22,6,20,4,15,7,9,12,3}},
    update={{20,10,18,6,14,4,9,4,5,7,3,12},{20,5,20,10,15,10},{4,14,6,18,10,20,15,20,19,17,21,13},{4,19,4,14,9,14}},
    muse={{4,5,20,5,20,16,11,16,6,20,6,16,4,16,4,5},{8,10,8,10},{12,10,12,10},{16,10,16,10}},
    home={{3,11,12,3,21,11},{5,10,5,21,19,21,19,10},{10,21,10,15,14,15,14,21}},
    sudoku={{3,3,21,3,21,21,3,21,3,3},{9,3,9,21},{15,3,15,21},{3,9,21,9},{3,15,21,15},
        {6,6,6,6},{12,12,12,12},{18,18,18,18}},
    note={{5,3,15,3,20,8,20,21,5,21,5,3},{15,3,15,8,20,8},{8,12,17,12},{8,16,17,16}},
    alarm={{9,2,15,2},{12,2,12,5},{18,6,20,4},{12,5,17,7,20,12,19,17,15,21,9,21,4,17,4,11,7,7,12,5},
        {12,9,12,13,15,14}},
    focus={{8,3,3,3,3,8},{16,3,21,3,21,8},{21,16,21,21,16,21},{8,21,3,21,3,16},
        {10,7,14,7,17,10,17,14,14,17,10,17,7,14,7,10,10,7}},
    help={{12,3,18,5,21,11,19,18,13,21,6,19,3,13,5,6,12,3},{12,7,12,7},{12,11,12,17}},
    exit={{12,3,5,3,5,21,12,21},{9,12,21,12},{17,8,21,12,17,16}},
    health={{5,8,7,4,10,4,12,6,14,4,17,4,19,8,12,20,5,8}},
    sun={{12,4,15,5,17,7,18,10,18,14,17,17,15,19,12,20,9,19,7,17,6,14,6,10,7,7,9,5,12,4},
        {12,12,12,12},{3,3,5,5},{21,3,19,5},{3,21,5,19},{21,21,19,19}},
    rain={{4,17,20,17,22,14,20,11,17,11,16,7,12,5,8,6,6,10,3,10,2,14,4,17},
        {8,19,8,21},{12,19,12,21},{16,19,16,21}},
    storm={{4,17,20,17,22,14,20,11,17,11,16,7,12,5,8,6,6,10,3,10,2,14,4,17},
        {14,17,10,21,13,21,11,23}},
    snow={{4,17,20,17,22,14,20,11,17,11,16,7,12,5,8,6,6,10,3,10,2,14,4,17},
        {7,19,9,21},{9,19,7,21},{12,20,12,20},{16,19,18,21},{18,19,16,21}},
    fog={{4,17,20,17,22,14,20,11,17,11,16,7,12,5,8,6,6,10,3,10,2,14,4,17},
        {6,19,18,19},{8,21,16,21}},
    trend_up={{4,18,10,12,14,15,20,6},{20,6,20,12},{20,6,14,6}},
    trend_down={{4,6,10,12,14,9,20,18},{20,18,20,12},{20,18,14,18}},
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

function Surface:label(text,x,y,w,h,px,opts)
    opts=opts or {}
    local face_name=opts.face or "ffont"
    local face=Font:getFace(face_name,math.max(8,floor(px*100/Screen:scaleBySize(100))))
    local props={text=text,face=face,padding=0,bold=opts.bold,
        fgcolor=opts.light and BB.COLOR_WHITE or BB.COLOR_BLACK}
    local widget
    if opts.wrap then
        props.width,props.height=w,h
        props.bgcolor=opts.fill or BB.COLOR_WHITE
        props.height_adjust=true
        props.height_overflow_show_ellipsis=true
        props.alignment=opts.align or "center"
        props.line_height=0
        widget=TextBoxWidget:new(props)
    else
        props.max_width=w
        widget=TextWidget:new(props)
    end
    local span=widget:getSize()
    local dx=opts.align=="left" and 0 or opts.align=="right" and w-span.w or floor((w-span.w)/2)
    self.labels[#self.labels+1]={widget=widget,x=x+dx,y=y+floor((h-span.h)/2)}
end

function Surface:drawGlyph(bb,name,x,y,size)
    drawIcon(bb,icons[name] and name or "arrow",x,y,size)
end

-- Hình đồ họa vẽ thẳng lên framebuffer (chỉ đen/trắng/xám cho màn e-ink):
-- thanh tiến trình ngang, biểu đồ cột đứng và thanh khoảng min-max.
function Surface:bar(x,y,w,h,fraction)
    self.shapes[#self.shapes+1]={kind="bar",x=x,y=y,w=w,h=h,
        fraction=math.max(0,math.min(1,fraction or 0))}
end

function Surface:columnChart(x,y,w,h,values)
    self.shapes[#self.shapes+1]={kind="columns",x=x,y=y,w=w,h=h,values=values}
end

function Surface:rangeBar(x,y,w,h,lo,hi,mark)
    self.shapes[#self.shapes+1]={kind="range",x=x,y=y,w=w,h=h,
        lo=math.max(0,math.min(1,lo or 0)),hi=math.max(0,math.min(1,hi or 0)),
        mark=mark and math.max(0,math.min(1,mark)) or nil}
end

function Surface:paintShapes(bb,x,y)
    for _,shape in ipairs(self.shapes) do
        local sx,sy=x+shape.x,y+shape.y
        if shape.kind=="bar" then
            bb:paintRect(sx,sy,shape.w,shape.h,BB.COLOR_GRAY_E)
            local fill_w=floor(shape.w*shape.fraction)
            if fill_w>0 then bb:paintRect(sx,sy,fill_w,shape.h,BB.COLOR_BLACK) end
            bb:paintBorder(sx,sy,shape.w,shape.h,self.stroke,BB.COLOR_BLACK,0,true)
        elseif shape.kind=="columns" then
            local values=shape.values
            local n=#values
            if n>0 then
                local col_w=floor((shape.w-(n-1)*self.gap)/n)
                for i,v in ipairs(values) do
                    local col_h=floor(shape.h*math.max(0,math.min(1,v or 0)))
                    local cx=sx+(i-1)*(col_w+self.gap)
                    if col_h>0 then bb:paintRect(cx,sy+shape.h-col_h,col_w,col_h,BB.COLOR_BLACK) end
                end
                bb:paintRect(sx,sy+shape.h-1,shape.w,1,BB.COLOR_BLACK)
            end
        elseif shape.kind=="range" then
            bb:paintRect(sx,sy,shape.w,shape.h,BB.COLOR_GRAY_E)
            local x0=floor(shape.w*shape.lo)
            local x1=floor(shape.w*shape.hi)
            if x1>x0 then bb:paintRect(sx+x0,sy,x1-x0,shape.h,BB.COLOR_BLACK) end
            if shape.mark then
                local mx=sx+floor(shape.w*shape.mark)
                bb:paintRect(mx-1,sy-2,3,shape.h+4,BB.COLOR_BLACK)
            end
            bb:paintBorder(sx,sy,shape.w,shape.h,self.stroke,BB.COLOR_BLACK,0,true)
        end
    end
end

function Surface:paintLabels(bb,x,y)
    for _,item in ipairs(self.labels) do item.widget:paintTo(bb,x+item.x,y+item.y) end
end

function Surface:area(x,y,w,h,r,fill,callback)
    local card={x=x,y=y,w=w,h=h,r=r,fill=fill,callback=callback}
    self.cards[#self.cards+1]=card
    if callback then self.targets[#self.targets+1]=card end
    return card
end

function Surface:control(text,x,y,w,h,callback,options)
    options=options or {}
    local card=self:area(x,y,w,h,options.radius or self.round,options.dark and BB.COLOR_BLACK or
        options.fill or BB.COLOR_GRAY_E,callback)
    local pad=options.pad or math.floor(w*0.07)
    local text_x=x+pad
    if options.icon then
        local size=floor(math.min(h*0.43,w*0.19))
        self.glyphs[#self.glyphs+1]={icon=options.icon,x=text_x,y=y+floor((h-size)/2),size=size}
        text_x=text_x+size+floor(pad/2)
    end
    self:label(text,text_x,y,x+w-pad-text_x,h,options.font or math.min(math.floor(h*0.34),self.hint_size),
        {bold=options.bold,light=options.dark,align=options.align,wrap=options.wrap,fill=card.fill})
    return card
end

function Surface:tileGrid(choices,first,top,bottom,primary_count)
    local w=self.dimen.w
    local gap=self.gap
    local side=floor(math.min((w-2*self.margin-3*gap)/4,(bottom-top-4*gap)/5))
    local x0=floor((w-4*side-3*gap)/2)
    local y0=top+floor((bottom-top-5*side-4*gap)/2)
    local tiles={}
    for index=first,math.min(first+19,#choices) do
        local choice=choices[index]
        local offset=index-first
        local x=x0+offset%4*(side+gap)
        local y=y0+floor(offset/4)*(side+gap)
        local fill=index<first+primary_count and BB.COLOR_GRAY_E or BB.COLOR_WHITE
        local tile=self:area(x,y,side,side,floor(side*0.17),fill,choice[2])
        tile.icon=choice[3] or self.icon or "arrow"
        tiles[#tiles+1]=tile
        local size=floor(side*0.35)
        self.glyphs[#self.glyphs+1]={icon=tile.icon,x=x+floor((side-size)/2),y=y+floor(side*0.11),size=size}
        local pad=floor(side*0.075)
        local font=math.min(self.hint_size,floor(side*0.123))
        self:label(choice[1],x+pad,y+floor(side*0.49),side-2*pad,floor(side*0.44),
            font,{bold=true,wrap=true,fill=fill})
    end
    return tiles
end

function Surface:header(title,subtitle,glyph,header_h)
    local edge=self.margin
    local size=math.min(self.hint_size*2,math.floor(header_h*0.35))
    local left=glyph and edge+size+self.gap or edge
    local body=header_h-edge-self.gap
    local title_h=subtitle and math.floor(body*0.62) or body
    local home_w=floor((self.dimen.w-2*edge)*0.21)
    local home_h=math.min(body,floor(self.hint_size*2.55))
    local right=self.dimen.w-edge-home_w-self.gap
    self:control("Trang chủ",right+self.gap,edge+floor((title_h-home_h)/2),home_w,home_h,
        function() self.app:home() end,{icon="home",font=floor(self.hint_size*0.9),bold=true,wrap=true})
    if glyph then
        self.glyphs[#self.glyphs+1]={icon=glyph,x=edge,y=edge+floor((title_h-size)/2),size=size}
    end
    self:label(title,left,edge,right-left,title_h,
        math.min(math.floor(title_h*0.47),self.title_size),{bold=true,align="left",wrap=true})
    if subtitle then
        self:label(subtitle,left,edge+title_h,right-left,body-title_h,
            math.min(self.hint_size,math.floor((body-title_h)*0.58)),{align="left"})
    end
end

function Surface:init()
    self.dimen=Geom:new{w=Screen:getWidth(),h=Screen:getHeight()}
    self.labels,self.targets,self.cards,self.glyphs,self.shapes={},{},{},{},{}
    local unit=math.min(self.dimen.w,self.dimen.h)
    self.margin=floor(unit*0.048)
    self.gap=math.max(3,floor(unit*0.018))
    self.round=floor(unit*0.026)
    self.stroke=math.max(1,floor(unit*0.0025))
    self.hint_size=floor(unit*0.028)
    self.title_size=floor(unit*0.057)
    self:build()
    self.ges_events={
        TileTap={GestureRange:new{ges="tap",range=self.dimen}},
        TileSwipe={GestureRange:new{ges="swipe",range=self.dimen}},
    }
    if Device:hasKeys() then
        self.key_events=self.key_events or {}
        self.key_events.CloseSurface={{Device.input.group.Back}}
    end
end

function Surface:paintTo(bb,x,y)
    bb:paintRect(x,y,self.dimen.w,self.dimen.h,BB.COLOR_WHITE)
    for _,card in ipairs(self.cards) do
        if card.fill then
            if card.r>0 then bb:paintRoundedRect(x+card.x,y+card.y,card.w,card.h,card.fill,card.r)
            else bb:paintRect(x+card.x,y+card.y,card.w,card.h,card.fill) end
        end
        if not card.no_border then
            bb:paintBorder(x+card.x,y+card.y,card.w,card.h,self.stroke,BB.COLOR_BLACK,card.r,true)
        end
    end
    for _,glyph in ipairs(self.glyphs) do self:drawGlyph(bb,glyph.icon,x+glyph.x,y+glyph.y,glyph.size) end
    self:paintShapes(bb,x,y)
    self:paintLabels(bb,x,y)
end

function Surface:onTarget(item)
    if item.callback then item.callback() end
end

function Surface:onTileTap(_,gesture)
    local x,y=gesture.pos.x,gesture.pos.y
    for _,item in ipairs(self.targets) do
        if x>=item.x and x<item.x+item.w and y>=item.y and y<item.y+item.h then
            self:onTarget(item)
            break
        end
    end
    return true
end

function Surface:onTileSwipe()
    return true
end

function Surface:onSetDimensions()
    if Screen:getWidth()~=self.dimen.w or Screen:getHeight()~=self.dimen.h then
        UI:nextTick(function()
            if self.app.window==self then self:onSurfaceResize() end
        end)
    end
end

function Surface:onCloseSurface()
    self.app:home()
    return true
end

function Surface:onShow()
    UI:setDirty(self,"ui")
end

function Surface:onCloseWidget()
    for _,item in ipairs(self.labels) do item.widget:free() end
    UI:setDirty(nil,"ui")
end

return Surface
