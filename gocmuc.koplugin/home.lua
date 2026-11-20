local root = debug.getinfo(1,"S").source:gsub("^@",""):gsub("[/\\]home%.lua$","")
local Surface = dofile(root.."/surface.lua")
local Home = Surface:extend{}
local floor=math.floor
local apps={
    {"Cờ vua","chessMenu","knight"}, {"Toán tư duy","mathMenu","math"},
    {"Cờ caro","caroMenu","caro"}, {"Đọc báo","newsMenu","news"},
    {"Lịch để bàn","calendar","calendar"}, {"Hợp âm","chordMenu","music"},
    {"Bé đọc","kidsMenu","book"}, {"Tiện ích","utilities","tools"},
    {"Tìm hợp âm","chordSearch","search"}, {"Lịch tháng","calendarThisMonth","calendar"},
    {"Thời tiết","weather","cloud"}, {"Giá vàng","gold","coin"},
    {"Sudoku","sudokuMenu","sudoku"}, {"Việc cần làm","todo","list"},
    {"Thói quen","habits","calendar"}, {"Tập trung","focus","focus"},
    {"Từ vựng","words","book"}, {"Ghi chú","notes","note"},
    {"Bấm giờ","stopwatch","alarm"}, {"Muse","museMenu","muse"},
}

function Home:build()
    local w,h=self.dimen.w,self.dimen.h
    local margin,gap=self.margin,self.gap
    local inner=w-2*margin
    local header=floor(h*0.165)
    local footer=floor(h*0.085)
    local side=floor(math.min((inner-3*gap)/4,(h-header-footer-5*gap)/5))
    local x0=floor((w-4*side-3*gap)/2)
    local y0=header+floor((h-header-footer-5*side-4*gap)/2)
    local title_h=floor(header*0.34)
    self:label("GÓC MỰC",margin,gap,inner,title_h,self.hint_size,{align="left",bold=true})
    self:label(self.battery,margin,gap,inner,title_h,self.hint_size,{align="right",bold=true})
    local date_y=title_h+gap
    local date_h=header-date_y-gap
    local clock_w=floor(inner*0.44)
    self:label(self.clock,margin,date_y,clock_w,date_h,math.min(self.title_size*2,floor(date_h*0.68)),
        {align="left",bold=true})
    self:label(self.date,margin+clock_w,date_y,inner-clock_w,floor(date_h/2),
        math.min(self.hint_size*1.28,floor(date_h*0.36)),{align="right",bold=true})
    self:label(self.lunar,margin+clock_w,date_y+floor(date_h/2),inner-clock_w,floor(date_h/2),
        math.min(self.hint_size,floor(date_h*0.31)),{align="right"})

    local choices={}
    for index,item in ipairs(apps) do
        choices[index]={item[1],function() self.app:openFeature(item[2],item[3]) end,item[3]}
    end
    self.tiles=self:tileGrid(choices,1,header,h-footer,8)

    local actions={{"Cập nhật","updates","update"},{"Giới thiệu","credits","help"},{"Về KOReader","close","exit"}}
    local action_w=floor((inner-2*gap)/3)
    local action_h=math.min(floor(footer*0.66),self.hint_size*3)
    for i,item in ipairs(actions) do
        self:control(item[1],margin+(i-1)*(action_w+gap),h-footer+floor((footer-action_h)/2),
            action_w,action_h,function() self.app:openFeature(item[2],item[3]) end,{wrap=true,icon=item[3]})
    end
end

function Home:onCloseSurface()
    self.app:close()
    return true
end

function Home:onSurfaceResize()
    self.app:home()
end

return Home
