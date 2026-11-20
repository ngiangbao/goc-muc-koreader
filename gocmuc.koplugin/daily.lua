return function(App,env)
local Lunar=env.Lunar
local Net=dofile(env.root.."/net.lua")
local sources={
    {"Báo Mới","baomoi.com"},
    {"Tuổi Trẻ","tuoitre.vn","https://tuoitre.vn/rss/tin-moi-nhat.rss"},
    {"Thanh Niên","thanhnien.vn","https://thanhnien.vn/rss/home.rss"},
    {"VnExpress","vnexpress.net","https://vnexpress.net/rss/tin-moi-nhat.rss"},
    {"Znews","znews.vn","https://znews.vn/rss/kinh-doanh-tai-chinh.rss"},
    {"Báo Quốc Tế","baoquocte.vn"},
}

function App:newsMenu()
    local choices={}
    for _,source in ipairs(sources) do
        choices[#choices+1]={source[1],function() self:newsLoad(source) end,"news"}
    end
    self:menu("Đọc báo",choices,function() self:home() end,{style="tiles",icon="news"})
end

function App:newsLoad(source,force)
    local key="news_"..source[2]
    local cached=self:read(key)
    if cached and not force then self:newsList(source,cached); return end
    self:online(function()
        local feed=source[3]
        local raw,err
        if feed then raw,err=Net.request(feed) end
        local entries=raw and Net.rss(raw) or {}
        local via="RSS tòa soạn"
        if #entries==0 then
            raw,err=Net.request("https://news.google.com/rss/search?q="..Net.escape("site:"..source[2])
                .."&hl=vi&gl=VN&ceid=VN:vi")
            entries=raw and Net.rss(raw) or {}
            via="Google Tin tức"
        end
        if #entries==0 then self:notice(err or "Nguồn báo chưa có bài."); return end
        local data={entries=entries,updated=os.time(),via=via}
        self:save(key,data)
        self:newsList(source,data)
    end)
end

function App:newsList(source,data)
    local subtitle=data.via.." · "..os.date("%d/%m %H:%M",data.updated)
    local choices={{"Làm mới bản tin",function() self:newsLoad(source,true) end,"update"}}
    for i,entry in ipairs(data.entries) do
        choices[#choices+1]={entry.title,function() self:newsArticle(source,data,i) end}
    end
    self:menu(source[1],choices,function() self:newsMenu() end,{style="list",icon="news",subtitle=subtitle})
end

function App:newsArticle(source,data,index,full)
    local item=data.entries[index]
    local prev=index>1 and function() self:newsArticle(source,data,index-1) end or nil
    local next_item=index<#data.entries and function() self:newsArticle(source,data,index+1) end or nil
    local rows={{
        self:button("‹ Bài trước",prev,{enabled=prev~=nil}),
        self:button("Bài sau ›",next_item,{enabled=next_item~=nil}),
    }}
    local host=item.url:match("^https://([%w.-]+)/")
    if not full and data.via=="RSS tòa soạn" and (host==source[2] or host=="www."..source[2]) then
        rows[#rows+1]={self:button("Tải nội dung bài",function()
            self:online(function()
                local raw,err=Net.request(item.url)
                local article=raw and Net.article(raw)
                if article then self:newsArticle(source,data,index,article)
                else self:notice(err or "Trang báo chỉ cung cấp bản tóm tắt.") end
            end)
        end)}
    end
    local text=item.date.."\n\n"..(full or (item.text~="" and item.text or item.title))
        .."\n\nNguồn: "..source[1].." · "..data.via
    if item.url~="" then text=text.."\n"..item.url end
    self:view(item.title,text,function() self:newsList(source,data) end,{rows=rows,prev=prev,next=next_item})
end

function App:calendar(ts)
    ts=ts or os.time()
    local date=os.date("*t",ts)
    local function on_day(delta)
        return function()
            self:calendar(os.time{year=date.year,month=date.month,day=date.day+delta,hour=12})
        end
    end
    local lunar_day,lunar_month,_,leap=Lunar.date(date.day,date.month,date.year)
    local lunar_year=Lunar.label(date.day,date.month,date.year):match("·%s*(.+)$")
    local hours={}
    for hour in Lunar.hours(date.day,date.month,date.year):gmatch("[^,]+") do
        hours[#hours+1]=(hour:gsub("^%s+",""))
    end
    self:openPage("Calendar",{
        day_info={day=date.day,month=date.month,year=date.year,wday=date.wday,
            lunar_day=lunar_day,lunar_month=lunar_month,lunar_year=lunar_year,leap=leap,hours=hours},
        back=function() self:home() end,
        today=function() self:calendar() end,
        previous=on_day(-1),next=on_day(1),redraw=function() self:calendar(ts) end,
        open_month=function() self:calendarMonth(date.month,date.year,ts) end,
        weather=function() self:weather(ts) end,
        gold=function() self:gold(ts) end,
    })
end

function App:calendarMonth(month,year,selected)
    selected=selected or os.time()
    local chosen=os.date("*t",selected)
    local first=os.date("*t",os.time{year=year,month=month,day=1,hour=12})
    local last=os.date("*t",os.time{year=year,month=month+1,day=0,hour=12}).day
    local offset=(first.wday+5)%7
    local days={}
    for day=1,last do
        local ts=os.time{year=year,month=month,day=day,hour=12}
        days[#days+1]={index=offset+day,day=day,lunar=Lunar.date(day,month,year),
            selected=chosen.day==day and chosen.month==month and chosen.year==year,
            open=function() self:calendar(ts) end}
    end
    local function go(delta)
        return function()
            local date=os.date("*t",os.time{year=year,month=month+delta,day=1,hour=12})
            self:calendarMonth(date.month,date.year,selected)
        end
    end
    self:openPage("Calendar",{
        month_info={month=month,year=year,days=days},
        back=function() self:calendar(selected) end,
        previous=go(-1),next=go(1),
        redraw=function() self:calendarMonth(month,year,selected) end,
    })
end

function App:calendarThisMonth()
    local date=os.date("*t")
    self:calendarMonth(date.month,date.year)
end

local function description(code)
    if code==0 then return "Trời quang" end
    if code and code<=3 then return "Có mây" end
    if code==45 or code==48 then return "Sương mù" end
    if code and code>=95 then return "Dông" end
    if code==71 or code==73 or code==75 or code==77 or code==85 or code==86 then return "Tuyết" end
    return code and "Có mưa" or "—"
end

function App:weather(ts)
    self:online(function()
        local loc=self:read("weather_location",{name="TP Hồ Chí Minh",lat=10.7769,lon=106.7009})
        local url="https://api.open-meteo.com/v1/forecast?latitude="..loc.lat.."&longitude="..loc.lon
            .."&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_min,temperature_2m_max,precipitation_probability_max&timezone=auto&forecast_days=4"
        local data,err=Net.json(url)
        if not data or not data.current or not data.daily then self:notice(err or "Chưa có dự báo."); return end
        local current,daily=data.current,data.daily
        local body={string.format("%s · %s °C\n%s",loc.name,current.temperature_2m or "—",description(current.weather_code))}
        for i,date in ipairs(daily.time or {}) do
            body[#body+1]=string.format("%s · %s\n%s–%s °C · Mưa %s%%",date,description(daily.weather_code[i]),
                daily.temperature_2m_min[i] or "—",daily.temperature_2m_max[i] or "—",
                daily.precipitation_probability_max[i] or "—")
        end
        self:view("Thời tiết",table.concat(body,"\n\n").."\n\nNguồn: Open-Meteo",function() self:calendar(ts) end,{
            rows={{self:button("Đổi địa điểm",function() self:weatherLocation(ts) end),
                self:button("Cập nhật",function() self:weather(ts) end)}},
        })
    end)
end

function App:weatherLocation(ts)
    self:prompt("Địa điểm","Ví dụ TP Hồ Chí Minh, Hà Nội hoặc Sydney.","",function(query)
        if query=="" then return end
        self:online(function()
            local data,err=Net.json("https://geocoding-api.open-meteo.com/v1/search?count=6&language=vi&name="..Net.escape(query))
            if not data or not data.results then self:notice(err or "Không tìm thấy địa điểm."); return end
            local choices={}
            for _,place in ipairs(data.results) do
                local label=place.name.." · "..(place.admin1 or place.country or "")
                choices[#choices+1]={label,function()
                    self:save("weather_location",{name=label,lat=place.latitude,lon=place.longitude})
                    self:weather(ts)
                end}
            end
            self:menu("Chọn địa điểm",choices,function() self:calendar(ts) end,{icon="cloud",style="list"})
        end)
    end)
end

function App:gold(ts)
    self:online(function()
        local data,err=Net.json("https://www.vang.today/api/prices?type=SJL1L10")
        if not data or not data.success then self:notice(err or "Chưa có bảng giá."); return end
        local function vnd(n)
            return (tostring(n):reverse():gsub("(%d%d%d)","%1."):reverse():gsub("^%.",""))
        end
        self:view("Giá vàng SJC 9999",
            "Mua vào: "..vnd(data.buy).." đ/lượng\nBán ra: "..vnd(data.sell).." đ/lượng\n\n"
            .."Cập nhật "..(data.time or "").." ngày "..(data.date or "—").."\nNguồn: Vang.today",
            function() self:calendar(ts) end,{rows={{self:button("Cập nhật",function() self:gold(ts) end)}}})
    end)
end
end
