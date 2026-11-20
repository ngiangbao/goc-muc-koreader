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

    local per_page=20
    self.page_count=math.max(1,math.ceil(#self.choices/per_page))
    self.page=math.max(1,math.min(self.page or 1,self.page_count))
    local first=(self.page-1)*per_page+1
    self.tiles=self:tileGrid(self.choices,first,header,h-footer-gap,4)
    if #self.tiles==0 then
        self:label("Chưa có mục",edge,header,inner,area,self.hint_size)
    end

    local y,h_nav=h-footer+floor(gap/2),footer-floor(gap/2)-edge
    local back_w=self.page_count>1 and floor(inner*0.40) or inner
    self:control("‹ Quay lại",edge,y,back_w,h_nav,self.back,{bold=true})
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
    local top=header
    if self.progress then
        local bar_h=math.max(4,floor(self.hint_size*0.9))
        self:bar(edge,header+gap,inner,bar_h,self.progress)
        top=header+gap+bar_h+gap
    end
    local y=top
    if n>0 then
        local cell=floor(math.min(inner,(h-top-footer-controls*(row_h+gap)-gap))/n)
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
        y=top+floor((h-top-footer-controls*(row_h+gap))/2)
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
            self.back,{bold=true})
    end
end

function Controls:onSurfaceResize()
    self.redraw()
end

local weekdays={"Chủ nhật","Thứ hai","Thứ ba","Thứ tư","Thứ năm","Thứ sáu","Thứ bảy"}

local function footerRow(page,labels,callbacks,y,h,primary)
    local edge,gap=page.margin,page.gap
    local inner=page.dimen.w-2*edge
    local width=floor((inner-(#labels-1)*gap)/#labels)
    for i,label in ipairs(labels) do
        page:control(label,edge+(i-1)*(width+gap),y,width,h,callbacks[i],
            {bold=true,dark=i==primary,wrap=true})
    end
end

function Calendar:footer(labels,callbacks,y,h,primary)
    footerRow(self,labels,callbacks,y,h,primary)
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
    local solar=self:area(edge,head,side,date_h,self.round*2,BB.COLOR_GRAY_E)
    local lunar=self:area(x2,head,side,date_h,self.round*2,BB.COLOR_WHITE)
    local text_h=floor(date_h*0.24)
    local number_h=floor(date_h*0.48)
    self:label("DƯƠNG LỊCH",edge+gap,head,side-2*gap,text_h,self.hint_size,{bold=true})
    self:label("ÂM LỊCH",x2+gap,head,side-2*gap,text_h,self.hint_size,{bold=true})
    local big=math.min(floor(date_h*0.40),floor(side*0.42))
    self:label(string.format("%02d",info.day),edge+gap,head+text_h,side-2*gap,number_h,big,{bold=true})
    self:label(string.format("%02d",info.lunar_day),x2+gap,head+text_h,side-2*gap,number_h,big,{bold=true})
    local details_y=head+text_h+number_h
    self:label("Tháng "..info.month.." · "..info.year,edge+gap,details_y,side-2*gap,text_h,
        self.hint_size,{bold=true,wrap=true,fill=solar.fill})
    self:label("Tháng "..info.lunar_month..(info.leap and " nhuận" or "").." · "..info.lunar_year,
        x2+gap,details_y,side-2*gap,text_h,self.hint_size,{wrap=true,fill=lunar.fill})
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

local Weather=Surface:extend{}

function Weather:build()
    local w,h=self.dimen.w,self.dimen.h
    local edge,gap=self.margin,self.gap
    local head=floor(h*0.17)
    local inner=w-2*edge
    self:header("Thời tiết",self.location,self.condition_icon,head)
    local y=head+gap
    local cur_h=floor(h*0.20)
    local icon_size=math.min(floor(cur_h*0.62),floor(inner*0.30))
    self.glyphs[#self.glyphs+1]={icon=self.condition_icon,x=edge,y=y+floor((cur_h-icon_size)/2),size=icon_size}
    local tx=edge+icon_size+gap*2
    local temp_h=floor(cur_h*0.58)
    self:label(self.temp,tx,y,w-edge-tx,temp_h,
        math.min(self.title_size*2,floor(temp_h*0.72)),{bold=true,align="left"})
    self:label(self.desc,tx,y+temp_h,w-edge-tx,cur_h-temp_h,
        math.min(self.hint_size*1.15,floor((cur_h-temp_h)*0.5)),{align="left"})
    y=y+cur_h+gap
    local label_h=floor(h*0.035)
    self:label(self.today_label,edge,y,inner,label_h,self.hint_size,{bold=true,align="left"})
    y=y+label_h+floor(gap/2)
    local bar_h=math.max(6,floor(self.hint_size*0.9))
    self:rangeBar(edge,y,inner,bar_h,self.today_lo,self.today_hi,self.now_mark)
    y=y+bar_h+floor(h*0.02)
    local days=self.days
    local col_w=floor((inner-(#days-1)*gap)/#days)
    local icon_row=floor(h*0.075)
    local icon_size2=math.min(floor(icon_row*0.85),floor(col_w*0.5))
    local line_h=floor(h*0.033)
    for i,day in ipairs(days) do
        local x=edge+(i-1)*(col_w+gap)
        self.glyphs[#self.glyphs+1]={icon=day.icon,x=x+floor((col_w-icon_size2)/2),y=y,size=icon_size2}
        self:label(day.max,x,y+icon_row,col_w,line_h,
            math.min(self.hint_size*1.15,floor(line_h*0.6)),{bold=true})
        self:label(day.min,x,y+icon_row+line_h,col_w,line_h,self.hint_size)
        self:label(day.rain,x,y+icon_row+2*line_h,col_w,line_h,self.hint_size)
    end
    y=y+icon_row+3*line_h+gap
    local bars_h=floor(h*0.11)
    local values={}
    for _,day in ipairs(days) do values[#values+1]=day.fraction end
    self:columnChart(edge,y,inner,bars_h,values)
    y=y+bars_h+floor(gap/2)
    for i,day in ipairs(days) do
        local x=edge+(i-1)*(col_w+gap)
        self:label(day.label,x,y,col_w,line_h,self.hint_size,{bold=true})
    end
    y=y+line_h+gap
    local foot_y=math.max(floor(h*0.79),y+gap)
    local row_h=math.min(floor(h*0.07),floor((h-foot_y-edge-gap)/2))
    footerRow(self,{"Đổi địa điểm","Cập nhật"},{self.on_location,self.on_refresh},foot_y,row_h)
    footerRow(self,{"‹ Quay lại"},{self.back},foot_y+row_h+gap,row_h)
end

function Weather:onSurfaceResize()
    self.redraw()
end

local Gold=Surface:extend{}

function Gold:build()
    local w,h=self.dimen.w,self.dimen.h
    local edge,gap=self.margin,self.gap
    local head=floor(h*0.17)
    local inner=w-2*edge
    self:header("Giá vàng SJC 9999",self.updated,"coin",head)
    local y=head+gap
    local row_h=floor(h*0.10)
    local label_w=floor(inner*0.30)
    local function priceRow(label,value,fill,ry)
        self:area(edge,ry,inner,row_h,self.round,fill)
        self:label(label,edge+gap,ry,label_w,row_h,
            math.min(self.hint_size*1.2,floor(row_h*0.32)),{bold=true,align="left",fill=fill})
        self:label(value,edge+label_w,ry,inner-label_w-gap,row_h,
            math.min(self.title_size,floor(row_h*0.5)),{bold=true,align="right",fill=fill})
    end
    priceRow("Mua vào",self.buy_text,BB.COLOR_GRAY_E,y)
    y=y+row_h+gap
    priceRow("Bán ra",self.sell_text,BB.COLOR_WHITE,y)
    y=y+row_h+floor(h*0.02)
    local bar_label_h=floor(h*0.033)
    local bar_h=math.max(6,floor(self.hint_size*0.9))
    self:label("Mua vào",edge,y,label_w,bar_label_h,self.hint_size,{bold=true,align="left"})
    self:bar(edge+label_w,y,inner-label_w,bar_h,self.buy_fraction)
    y=y+bar_label_h+gap
    self:label("Bán ra",edge,y,label_w,bar_label_h,self.hint_size,{bold=true,align="left"})
    self:bar(edge+label_w,y,inner-label_w,bar_h,self.sell_fraction)
    y=y+bar_label_h+floor(h*0.02)
    local trend_size=math.min(floor(h*0.05),floor(inner*0.08))
    self.glyphs[#self.glyphs+1]={icon=self.trend_icon,x=edge,y=y,size=trend_size}
    self:label(self.trend_text,edge+trend_size+gap,y,inner-trend_size-gap,
        math.max(trend_size,bar_label_h),self.hint_size,{align="left",wrap=true})
    y=y+math.max(trend_size,bar_label_h)+gap
    self:label("Nguồn: Vang.today · Đơn vị: đồng/lượng",edge,y,inner,bar_label_h,
        self.hint_size,{align="left"})
    y=y+bar_label_h+gap
    local foot_y=math.max(floor(h*0.79),y+gap)
    local row_h2=math.min(floor(h*0.07),floor(h-foot_y-edge-gap))
    footerRow(self,{"Cập nhật","‹ Quay lại"},{self.on_refresh,self.back},foot_y,row_h2)
end

function Gold:onSurfaceResize()
    self.redraw()
end

local Chart=Surface:extend{}

function Chart:build()
    local w,h=self.dimen.w,self.dimen.h
    local edge,gap=self.margin,self.gap
    local head=floor(h*0.17)
    local inner=w-2*edge
    self:header(self.title,self.subtitle,self.icon,head)
    self.chart_columns=self.columns
    local y=head+gap
    local columns=self.columns or {}
    if #columns==0 then
        self:label("Chưa có dữ liệu",edge,y,inner,floor(h*0.1),self.hint_size)
    else
        local col_w=floor((inner-(#columns-1)*gap)/#columns)
        local line_h=floor(h*0.035)
        for i,col in ipairs(columns) do
            local x=edge+(i-1)*(col_w+gap)
            self:label(col.text or "",x,y,col_w,line_h,self.hint_size,{bold=true})
        end
        y=y+line_h+gap
        local bars_h=floor(h*0.34)
        local values={}
        for _,col in ipairs(columns) do values[#values+1]=col.fraction or 0 end
        self:columnChart(edge,y,inner,bars_h,values)
        y=y+bars_h+floor(gap/2)
        for i,col in ipairs(columns) do
            local x=edge+(i-1)*(col_w+gap)
            self:label(col.label or "",x,y,col_w,line_h,self.hint_size,{bold=true})
        end
        y=y+line_h+gap
    end
    local foot_y=math.max(floor(h*0.79),y+gap)
    local row_h=math.min(floor(h*0.07),floor(h-foot_y-edge-gap))
    footerRow(self,{"‹ Quay lại"},{self.back},foot_y,row_h)
end

function Chart:onSurfaceResize()
    self.redraw()
end

return {Menu=Menu,Controls=Controls,Calendar=Calendar,Weather=Weather,Gold=Gold,Chart=Chart}
