local BB=require("ffi/blitbuffer")
local root=debug.getinfo(1,"S").source:gsub("^@",""):gsub("[/\\]pages%.lua$","")
local Surface=dofile(root.."/surface.lua")
local floor=math.floor

local Menu=Surface:extend{}
local Controls=Surface:extend{}
local Calendar=Surface:extend{}

function Menu:build()
    local w,h=self.dimen.w,self.dimen.h
    local edge,gap=self.margin,self.gap
    local header=floor(h*0.17)
    local footer=floor(h*0.11)
    local area=h-header-footer-gap
    local inner=w-2*edge
    self:header(self.title,self.subtitle,self.icon,header)

    local list=self.style=="list" or (#self.choices>7 and self.style~="tiles")
    if not list and not self.style then
        for _,item in ipairs(self.choices) do
            if #item[1]:gsub("[\128-\191]","")>26 then list=true; break end
        end
    end
    local per_page=list and math.max(3,math.min(7,floor(area/(self.hint_size*3.2)))) or 4
    self.page_count=math.max(1,math.ceil(#self.choices/per_page))
    self.page=math.max(1,math.min(self.page or 1,self.page_count))
    local first=(self.page-1)*per_page+1
    local count=math.min(per_page,#self.choices-first+1)
    if count==0 then
        self:label("Chưa có mục",edge,header,inner,area,self.hint_size)
    elseif list then
        local step=floor((area+gap)/per_page)
        for index=1,count do
            local choice=self.choices[first+index-1]
            local x,y=edge,header+(index-1)*step
            local height=step-gap
            self:area(x,y,inner,height,self.round,BB.COLOR_GRAY_E,choice[2])
            local icon_size=floor(math.min(height*0.38,self.hint_size*1.25))
            local icon_x=x+inner-2*gap-icon_size
            self.glyphs[#self.glyphs+1]={icon=choice[3] or "arrow",x=icon_x,y=y+floor((height-icon_size)/2),size=icon_size}
            self:label(choice[1],x+2*gap,y,icon_x-x-3*gap,height,
                math.min(self.hint_size*1.11,floor(height*0.28)),{align="left",bold=true,wrap=true})
        end
    else
        local side=floor(math.min((inner-gap)/2,(area-gap)/2))
        local x0=floor((w-2*side-gap)/2)
        local rows=math.ceil(count/2)
        local y0=header+floor((area-rows*side-(rows-1)*gap)/2)
        for index=1,count do
            local choice=self.choices[first+index-1]
            local x=x0+((index-1)%2)*(side+gap)
            if index==count and count%2==1 then x=floor((w-side)/2) end
            local y=y0+floor((index-1)/2)*(side+gap)
            self:area(x,y,side,side,floor(side*0.16),index==1 and BB.COLOR_GRAY_E or BB.COLOR_WHITE,choice[2])
            local icon_size=floor(side*0.35)
            self.glyphs[#self.glyphs+1]={icon=choice[3] or self.icon or "arrow",
                x=x+floor((side-icon_size)/2),y=y+floor(side*0.15),size=icon_size}
            self:label(choice[1],x+gap,y+floor(side*0.55),side-2*gap,floor(side*0.34),
                math.min(self.title_size*0.74,floor(side*0.116)),{bold=true,wrap=true})
        end
    end

    local y,h_nav=h-footer+floor(gap/2),footer-floor(gap/2)-edge
    local back_w=self.page_count>1 and floor(inner*0.40) or inner
    self:control("‹ Quay lại",edge,y,back_w,h_nav,function() self:onCloseSurface() end,{bold=true})
    if self.page_count>1 then
        local nav_w=floor((inner-back_w-2*gap)/3)
        local x=edge+back_w+gap
        self:control("‹",x,y,nav_w,h_nav,self.page>1 and function() self:changePage(-1) end or nil)
        self:label(self.page.." / "..self.page_count,x+nav_w,y,nav_w,h_nav,self.hint_size,{bold=true})
        self:control("›",x+2*nav_w,y,nav_w,h_nav,self.page<self.page_count and function() self:changePage(1) end or nil)
    end
end

function Menu:changePage(delta)
    local page=self.page+delta
    if page>=1 and page<=self.page_count then self.redraw(page) end
end

function Menu:onTileSwipe(_,gesture)
    if gesture.direction=="west" or gesture.direction=="north" then self:changePage(1)
    elseif gesture.direction=="east" or gesture.direction=="south" then self:changePage(-1) end
    return true
end

function Menu:onSurfaceResize()
    self.redraw(self.page)
end

function Controls:build()
    local w,h=self.dimen.w,self.dimen.h
    local edge,gap=self.margin,self.gap
    local header=floor(h*0.19)
    local footer=floor(h*0.105)
    local inner=w-2*edge
    self:header(self.title,nil,self.icon,header)
    local n=self.square_count or 0
    local controls=#self.buttons-n
    local row_h=math.min(floor(h*0.085),floor((h-header-footer-gap)/(controls+2)))
    local board_h=0
    local y=header
    if n>0 then
        local cell=floor(math.min(inner,(h-header-footer-controls*(row_h+gap)-gap))/n)
        board_h=cell*n
        local x0=floor((w-board_h)/2)
        for r=1,n do
            for c,item in ipairs(self.buttons[r]) do
                local x,cy=x0+(c-1)*cell,y+(r-1)*cell
                self:area(x,cy,cell,cell,0,item.background or BB.COLOR_WHITE,item.enabled~=false and item.callback or nil)
                self:label(item.text,x+1,cy,cell-2,cell,floor(cell*0.62),
                    {face=item.font_face,bold=item.font_bold})
            end
        end
        y=y+board_h+gap
    elseif controls>0 then
        y=header+floor((h-header-footer-controls*(row_h+gap))/2)
    end
    for r=n+1,#self.buttons do
        local row=self.buttons[r]
        local span=floor((inner-(#row-1)*gap)/#row)
        for index,item in ipairs(row) do
            self:control(item.text,edge+(index-1)*(span+gap),y,span,row_h,
                item.enabled~=false and item.callback or nil,{bold=true,wrap=true})
        end
        y=y+row_h+gap
    end
    if self.back then
        self:control(self.back_text or "‹ Quay lại",edge,h-footer,inner,footer-edge,
            function() self:onCloseSurface() end,{bold=true})
    end
end

function Controls:onSurfaceResize()
    self.redraw()
end

local weekdays={"Chủ nhật","Thứ hai","Thứ ba","Thứ tư","Thứ năm","Thứ sáu","Thứ bảy"}

function Calendar:footer(labels,callbacks,y,h,primary)
    local edge,gap=self.margin,self.gap
    local inner=self.dimen.w-2*edge
    local width=floor((inner-(#labels-1)*gap)/#labels)
    for i,label in ipairs(labels) do
        self:control(label,edge+(i-1)*(width+gap),y,width,h,callbacks[i],
            {bold=true,dark=i==primary,wrap=true})
    end
end

function Calendar:day()
    local w,h=self.dimen.w,self.dimen.h
    local edge,gap=self.margin,self.gap
    local info=self.day_info
    local head=floor(h*0.14)
    self:header("Lịch để bàn",weekdays[info.wday],"calendar",head)
    local inner=w-2*edge
    local side=floor((inner-gap)/2)
    local date_h=floor(h*0.30)
    local x2=edge+side+gap
    self:area(edge,head,side,date_h,self.round*2,BB.COLOR_GRAY_E)
    self:area(x2,head,side,date_h,self.round*2,BB.COLOR_WHITE)
    local text_h=floor(date_h*0.24)
    local number_h=floor(date_h*0.48)
    self:label("DƯƠNG LỊCH",edge+gap,head,side-2*gap,text_h,self.hint_size,{bold=true})
    self:label("ÂM LỊCH",x2+gap,head,side-2*gap,text_h,self.hint_size,{bold=true})
    local big=math.min(floor(date_h*0.40),floor(side*0.42))
    self:label(string.format("%02d",info.day),edge+gap,head+text_h,side-2*gap,number_h,big,{bold=true})
    self:label(string.format("%02d",info.lunar_day),x2+gap,head+text_h,side-2*gap,number_h,big,{bold=true})
    local details_y=head+text_h+number_h
    self:label("Tháng "..info.month.." · "..info.year,edge+gap,details_y,side-2*gap,text_h,
        self.hint_size,{bold=true,wrap=true})
    self:label("Tháng "..info.lunar_month..(info.leap and " nhuận" or "").." · "..info.lunar_year,
        x2+gap,details_y,side-2*gap,text_h,self.hint_size,{wrap=true})
    local hours_y=head+date_h+gap
    local footer_y=floor(h*0.79)
    local hours_h=footer_y-hours_y-gap
    self:area(edge,hours_y,inner,hours_h,self.round,BB.COLOR_WHITE)
    local hour_title=floor(hours_h*0.27)
    self:label("Giờ hoàng đạo",edge+2*gap,hours_y,inner-4*gap,hour_title,
        math.min(self.hint_size*1.24,floor(hour_title*0.53)),{align="left",bold=true})
    local count=math.ceil(#info.hours/2)
    local hour_h=floor((hours_h-hour_title-gap)/math.max(count,1))
    for i,label in ipairs(info.hours) do
        local col=(i-1)%2
        local row=floor((i-1)/2)
        self:label(label,edge+2*gap+col*(side-gap),hours_y+hour_title+row*hour_h,
            side-3*gap,hour_h,math.min(self.hint_size,floor(hour_h*0.43)),{align="left"})
    end
    local row_h=math.min(floor(h*0.078),floor((h-footer_y-edge-2*gap)/2))
    self:footer({"Lịch tháng","Thời tiết","Giá vàng"},{self.open_month,self.weather,self.gold},footer_y,row_h)
    self:footer({"‹ Hôm trước","Hôm nay","Hôm sau ›"},{self.previous,self.today,self.next},
        footer_y+row_h+gap,row_h,2)
    self:label("‹ Quay lại",edge,footer_y+2*row_h+gap,inner,h-footer_y-2*row_h-gap,
        self.hint_size,{bold=true})
    self.targets[#self.targets+1]={x=edge,y=footer_y+2*row_h+gap,w=inner,
        h=h-footer_y-2*row_h-gap,callback=self.back}
end

function Calendar:month()
    local w,h=self.dimen.w,self.dimen.h
    local edge,gap=self.margin,self.gap
    local info=self.month_info
    local head=floor(h*0.15)
    local foot=floor(h*0.12)
    self:header(string.format("Tháng %02d / %d",info.month,info.year),"Dương lịch · Ngày âm ở dòng dưới","calendar",head)
    local inner=w-2*edge
    local step=floor(inner/7)
    local title_h=floor(h*0.058)
    local cell_h=floor((h-head-title_h-foot-gap)/6)
    for i,label in ipairs({"T2","T3","T4","T5","T6","T7","CN"}) do
        self:label(label,edge+(i-1)*step,head,step,title_h,self.hint_size,{bold=true})
    end
    for _,date in ipairs(info.days) do
        local x=edge+(date.index-1)%7*step
        local y=head+title_h+floor((date.index-1)/7)*cell_h
        local selected=date.selected
        self:area(x+2,y+2,step-4,cell_h-4,floor(self.round*0.6),
            selected and BB.COLOR_BLACK or BB.COLOR_GRAY_E,date.open)
        self:label(tostring(date.day),x+3,y,step-6,floor(cell_h*0.58),
            math.min(self.hint_size*1.27,floor(cell_h*0.31)),{bold=true,light=selected})
        self:label(tostring(date.lunar),x+3,y+floor(cell_h*0.55),step-6,floor(cell_h*0.42),
            math.min(self.hint_size*0.75,floor(cell_h*0.22)),{light=selected})
    end
    self:footer({"‹ Tháng trước","Về ngày","Tháng sau ›"},{self.previous,self.back,self.next},
        h-foot,foot-edge,2)
end

function Calendar:build()
    if self.month_info then self:month() else self:day() end
end

function Calendar:onTileSwipe(_,gesture)
    if gesture.direction=="west" then self.next()
    elseif gesture.direction=="east" then self.previous() end
    return true
end

function Calendar:onSurfaceResize()
    self.redraw()
end

return {Menu=Menu,Controls=Controls,Calendar=Calendar}
