-- Vietnamese calendar at UTC+7. Astronomical method documented by Hồ Ngọc Đức.
local Lunar = {}
local floor,sin,pi = math.floor,math.sin,math.pi
local epoch, lunation, tz = 2415021.076998695,29.530588853,7/24

local function jd(d,m,y)
    local a=floor((14-m)/12)
    y,m=y+4800-a,m+12*a-3
    return d+floor((153*m+2)/5)+365*y+floor(y/4)-floor(y/100)+floor(y/400)-32045
end

local function moon(k)
    local t=k/1236.85
    local ta,tb=t*t,t*t*t
    local rad=pi/180
    local m=(359.2242+29.10535608*k-0.0000333*ta-0.00000347*tb)*rad
    local mp=(306.0253+385.81691806*k+0.0107306*ta+0.00001236*tb)*rad
    local f=(21.2964+390.67050646*k-0.0016528*ta-0.00000239*tb)*rad
    local time=2415020.75933+29.53058868*k+0.0001178*ta-0.000000155*tb
        +0.00033*sin((166.56+132.87*t-0.009173*ta)*rad)
    local correction=(0.1734-0.000393*t)*sin(m)+0.0021*sin(2*m)
        -0.4068*sin(mp)+0.0161*sin(2*mp)-0.0004*sin(3*mp)
        +0.0104*sin(2*f)-0.0051*sin(m+mp)-0.0074*sin(m-mp)
        +0.0004*sin(2*f+m)-0.0004*sin(2*f-m)-0.0006*sin(2*f+mp)
        +0.0010*sin(2*f-mp)+0.0005*sin(2*mp+m)
    local dt=t < -11 and (0.001+0.000839*t+0.0002261*ta-0.00000845*tb-0.000000081*ta*ta)
        or (-0.000278+0.000265*t+0.000262*ta)
    return floor(time+correction-dt+0.5+tz)
end

local function solar_sector(day)
    local t=(day-2451545.5-tz)/36525
    local rad=pi/180
    local m=(357.52910+35999.05030*t-0.0001559*t*t-0.00000048*t*t*t)*rad
    local lon=280.46645+36000.76983*t+0.0003032*t*t
        +(1.914600-0.004817*t-0.000014*t*t)*sin(m)
        +(0.019993-0.000101*t)*sin(2*m)+0.000290*sin(3*m)
    return floor((lon%360)/30)
end

local function winter_month(y)
    local k=floor((jd(31,12,y)-2415021)/lunation)
    local d=moon(k)
    return solar_sector(d)>=9 and moon(k-1) or d
end

function Lunar.date(d,m,y)
    local day=jd(d,m,y)
    local k=floor((day-epoch)/lunation)
    local first=moon(k+1)
    if first>day then first=moon(k) end
    local a,b=winter_month(y),winter_month(y)
    local year=y
    if first>=a then b=winter_month(y+1); year=y+1 else a=winter_month(y-1) end
    local delta=floor((first-a)/29)
    local month, leap=delta+11,false
    if b-a>365 then
        local anchor=floor((a-epoch)/lunation+0.5)
        local previous=solar_sector(moon(anchor+1))
        for i=2,14 do
            local sector=solar_sector(moon(anchor+i))
            if sector==previous then
                if delta>=i-1 then month,leap=delta+10,delta==i-1 end
                break
            end
            previous=sector
        end
    end
    if month>12 then month=month-12 end
    if month>=11 and delta<4 then year=year-1 end
    return day-first+1,month,year,leap,day
end

local stems={"Giáp","Ất","Bính","Đinh","Mậu","Kỷ","Canh","Tân","Nhâm","Quý"}
local branches={"Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"}
local lucky={"110100101100","001101001011","110011010010","101100110100","001011001101","010010110011"}

function Lunar.label(d,m,y)
    local day,month,year,leap= Lunar.date(d,m,y)
    return string.format("%02d/%02d%s · %s %s",day,month,leap and " nhuận" or "",
        stems[(year+6)%10+1],branches[(year+8)%12+1])
end

function Lunar.hours(d,m,y)
    local day=jd(d,m,y)
    local pattern=lucky[(day+1)%6+1]
    local result={}
    for i=1,12 do
        if pattern:sub(i,i)=="1" then
            result[#result+1]=string.format("%s (%02d–%02dh)",branches[i],(i*2-3)%24,(i*2-1)%24)
        end
    end
    return table.concat(result,", ")
end

return Lunar