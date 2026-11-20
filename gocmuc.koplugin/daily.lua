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
    self:menu("Đọc báo",choices,function() self:home() end,{icon="news"})
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
    self:menu(source[1],choices,function() self:newsMenu() end,{icon="news",subtitle=subtitle})
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

local function weatherIcon(code)
    if code==0 then return "sun" end
    if code and code<=3 then return "cloud" end
    if code==45 or code==48 then return "fog" end
    if code and code>=95 then return "storm" end
    if code==71 or code==73 or code==75 or code==77 or code==85 or code==86 then return "snow" end
    return code and "rain" or "cloud"
end

local function shortDate(date)
    return date and #date>=10 and date:sub(9,10).."/"..date:sub(6,7) or "—"
end

function App:weather(ts)
    self:online(function()
        local loc=self:read("weather_location",{name="TP Hồ Chí Minh",lat=10.7769,lon=106.7009})
        local url="https://api.open-meteo.com/v1/forecast?latitude="..loc.lat.."&longitude="..loc.lon
            .."&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_min,temperature_2m_max,precipitation_probability_max&timezone=auto&forecast_days=4"
        local data,err=Net.json(url)
        if data and data.current and data.daily then
            self:save("weather_cache",{location=loc,current=data.current,daily=data.daily,updated=os.time()})
            self:weatherShow(ts,loc,data.current,data.daily,false)
            return
        end
        local cached=self:read("weather_cache")
        if cached and cached.current and cached.daily then
            self:weatherShow(ts,cached.location or loc,cached.current,cached.daily,true)
            return
        end
        self:notice(err or "Chưa có dự báo.")
    end)
end

function App:weatherShow(ts,loc,current,daily,stale)
    local days={}
    local gmin,gmax
    for i in ipairs(daily.time or {}) do
        local mn,mx=daily.temperature_2m_min[i],daily.temperature_2m_max[i]
        if mn and (not gmin or mn<gmin) then gmin=mn end
        if mx and (not gmax or mx>gmax) then gmax=mx end
    end
    if #(daily.time or {})==0 then self:notice("Chưa có dự báo."); return end
    gmin,gmax=gmin or 0,gmax or 40
    for i,date in ipairs(daily.time or {}) do
        local mx=daily.temperature_2m_max[i]
        local mn=daily.temperature_2m_min[i]
        days[#days+1]={
            label=shortDate(date),icon=weatherIcon(daily.weather_code[i]),
            max=(mx and math.floor(mx+0.5) or "—").."°",
            min=(mn and math.floor(mn+0.5) or "—").."°",
            rain="Mưa "..(daily.precipitation_probability_max[i] or "—").."%",
            fraction=mx and math.max(0,math.min(1,mx/40)) or 0,
        }
    end
    local today_min,today_max=daily.temperature_2m_min[1],daily.temperature_2m_max[1]
    local span=(gmax-gmin)>0 and (gmax-gmin) or 1
    self:openPage("Weather",{
        location=loc.name..(stale and " · Dữ liệu cũ" or ""),
        condition_icon=weatherIcon(current.weather_code),
        temp=(current.temperature_2m and math.floor(current.temperature_2m+0.5) or "—").." °C",
        desc=description(current.weather_code).." · Nguồn: Open-Meteo",
        today_label="Hôm nay · "..(today_min and math.floor(today_min+0.5) or "—").."–"
            ..(today_max and math.floor(today_max+0.5) or "—").." °C",
        today_lo=today_min and (today_min-gmin)/span or 0,
        today_hi=today_max and (today_max-gmin)/span or 0,
        now_mark=current.temperature_2m and (current.temperature_2m-gmin)/span or nil,
        days=days,
        back=function() self:calendar(ts) end,
        on_location=function() self:weatherLocation(ts) end,
        on_refresh=function() self:weather(ts) end,
        redraw=function() self:weatherShow(ts,loc,current,daily,stale) end,
        icon="cloud",
    })
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
            self:menu("Chọn địa điểm",choices,function() self:calendar(ts) end,{icon="cloud"})
        end)
    end)
end

function App:gold(ts)
    self:online(function()
        local data,err=Net.json("https://www.vang.today/api/prices?type=SJL1L10")
        if data and data.success then
            self:save("gold_cache",{buy=data.buy,sell=data.sell,time=data.time,date=data.date,updated=os.time()})
            self:goldShow(ts,data.buy,data.sell,data.time,data.date,false)
            return
        end
        local cached=self:read("gold_cache")
        if cached and cached.buy and cached.sell then
            self:goldShow(ts,cached.buy,cached.sell,cached.time,cached.date,true)
            return
        end
        self:notice(err or "Chưa có bảng giá.")
    end)
end

function App:goldShow(ts,buy,sell,time,date,stale)
    local function vnd(n)
        return (tostring(n):reverse():gsub("(%d%d%d)","%1."):reverse():gsub("^%.",""))
    end
    local prev=self:read("gold_prev")
    local trend_icon,trend_text="trend_up","Chưa có lần đo trước để so sánh."
    if prev and prev.buy and prev.sell then
        local diff=sell-prev.sell
        if diff>0 then trend_icon="trend_up"; trend_text="Tăng "..vnd(diff).." đ so với lần trước."
        elseif diff<0 then trend_icon="trend_down"; trend_text="Giảm "..vnd(-diff).." đ so với lần trước."
        else trend_text="Không đổi so với lần trước." end
    end
    self:save("gold_prev",{buy=buy,sell=sell,time=time,date=date})
    local top=math.max(buy or 0,sell or 0,1)
    self:openPage("Gold",{
        buy_text=vnd(buy).." đ",sell_text=vnd(sell).." đ",
        buy_fraction=(buy or 0)/top,sell_fraction=(sell or 0)/top,
        trend_icon=trend_icon,trend_text=trend_text,
        updated="Cập nhật "..(time or "").." ngày "..(date or "—")..(stale and " · Dữ liệu cũ" or ""),
        back=function() self:calendar(ts) end,
        on_refresh=function() self:gold(ts) end,
        redraw=function() self:goldShow(ts,buy,sell,time,date,stale) end,
        icon="coin",
    })
end
end
