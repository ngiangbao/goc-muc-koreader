return function(App,env)
local UI=env.UI

function App:utilities()
    local groups={
        {"Việc cần làm","todo","list"},{"Thói quen","habits","calendar"},{"Đồng hồ tập trung","focus","clock"},
        {"Từ vựng Anh–Việt","words","book"},{"Sudoku","sudokuMenu","caro"},{"Ghi chú","notes","news"},
        {"Bấm giờ","stopwatch","clock"},{"Đếm ngược","countdown","clock"},{"Đổi đơn vị","convert","math"},
        {"Máy tính","calculate","math"},{"Xúc xắc","dice","dice"},{"Tung đồng xu","coin","coin"},
        {"Bốc số","randomNumber","dice"},{"Thẻ tự tạo","flashcards","book"},{"Theo dõi nước uống","water","water"},
    }
    local choices={}
    for _,item in ipairs(groups) do
        choices[#choices+1]={item[1],function() self[item[2]](self) end,item[3]}
    end
    self:menu("Tiện ích",choices,function() self:home() end,{icon="tools",style="list"})
end

function App:setList(key,title,kind)
    local items=self:read(key,{})
    local today=os.date("%Y-%m-%d")
    local function back() self:setList(key,title,kind) end
    local choices={{"+ Thêm",function()
        self:prompt("Thêm mục",nil,"",function(label)
            if label=="" then return end
            items[#items+1]={label=label,days={}}
            self:save(key,items)
            back()
        end)
    end}}
    for index,item in ipairs(items) do
        local done=kind=="habit" and item.days[today] or item.done
        choices[#choices+1]={(done and "✓ " or "○ ")..item.label,function()
            local label=done and "Bỏ đánh dấu" or "Đánh dấu hôm nay"
            local opts={{label,function()
                if kind=="habit" then item.days[today]=not done or nil else item.done=not done end
                self:save(key,items)
                back()
            end},{"Đổi tên",function()
                self:prompt("Đổi tên",nil,item.label,function(value)
                    if value~="" then item.label=value; self:save(key,items) end
                    back()
                end)
            end}}
            if kind=="habit" then
                opts[#opts+1]={"Xem 7 ngày qua",function()
                    local result={}
                    local day=os.date("*t")
                    for delta=0,6 do
                        local ts=os.time{year=day.year,month=day.month,day=day.day-delta,hour=12}
                        local date=os.date("%Y-%m-%d",ts)
                        result[#result+1]=(item.days[date] and "✓ " or "○ ")..date
                    end
                    self:view(item.label,table.concat(result,"\n"),back)
                end}
            end
            opts[#opts+1]={"Xóa mục",function()
                self:menu("Xóa «"..item.label.."»?",{{"Xóa",function()
                    table.remove(items,index)
                    self:save(key,items)
                    back()
                end}},back)
            end}
            self:menu(item.label,opts,back)
        end}
    end
    self:menu(title,choices,function() self:utilities() end)
end

function App:todo() self:setList("todo","Việc cần làm","task") end
function App:habits() self:setList("habits","Thói quen","habit") end

local function clock(n)
    n=math.max(0,n)
    return string.format("%02d:%02d:%02d",math.floor(n/3600),math.floor(n/60)%60,n%60)
end

function App:focus()
    local choices={}
    for _,minutes in ipairs({15,25,45}) do
        choices[#choices+1]={minutes.." phút tập trung",function()
            self:timer("Tập trung",os.time()+minutes*60,function() self:focusBreak() end)
        end}
    end
    self:menu("Đồng hồ tập trung",choices,function() self:utilities() end)
end

function App:focusBreak()
    self:menu("Đã xong phiên tập trung",{{"Nghỉ 5 phút",function()
        self:timer("Nghỉ giải lao",os.time()+5*60,function() self:focus() end)
    end}},function() self:focus() end)
end

function App:countdown()
    self:prompt("Đếm ngược","Nhập số phút (0,1–180).","5",function(value)
        local n=tonumber((value:gsub(",",".")))
        if not n or n<0.1 or n>180 then self:notice("Thời lượng không hợp lệ."); return end
        self:timer("Đếm ngược",os.time()+math.floor(n*60),function()
            self:utilities(); self:notice("Đã hết giờ.")
        end)
    end,{number=true,action="Bắt đầu"})
end

function App:timer(title,deadline,done)
    local remain=deadline-os.time()
    if remain<=0 then done(); return end
    local function refresh() self:timer(title,deadline,done) end
    local window=self:show(title.."\n"..clock(remain),
        {{self:button("Làm mới",refresh)}},function() self:utilities() end,{back_text="Dừng"})
    UI:scheduleIn(math.min(10,remain),function() if self.window==window then refresh() end end)
end

function App:stopwatch(state)
    state=state or {elapsed=0}
    local value=state.elapsed+(state.started and os.time()-state.started or 0)
    self:show("Bấm giờ\n"..clock(value),{
        {self:button(state.started and "Tạm dừng" or "Bắt đầu",function()
            if state.started then state.elapsed=state.elapsed+os.time()-state.started; state.started=nil
            else state.started=os.time() end
            self:stopwatch(state)
        end),self:button("Làm mới",function() self:stopwatch(state) end)},
        {self:button("Đặt lại",function() self:stopwatch() end)},
    },function() self:utilities() end)
end

local vocabulary={
    {"book", "quyển sách"},{"learn","học"},{"quiet","yên tĩnh"},{"cloud","đám mây"},
    {"move","nước đi / di chuyển"},{"square","hình vuông / ô vuông"},{"pencil","bút chì"},
    {"solve","giải"},{"mirror","gương"},{"bridge","cây cầu"},{"garden","khu vườn"},
    {"count","đếm"},{"early","sớm"},{"forest","rừng"},{"share","chia sẻ"},
    {"measure","đo lường"},{"between","ở giữa"},{"balance","cân bằng"},{"healthy","khỏe mạnh"},
    {"together","cùng nhau"},
}

function App:words()
    self:menu("Từ vựng Anh–Việt",{
        {"Ôn thẻ",function() self:studyCard(vocabulary,math.random(#vocabulary),false,"words") end},
        {"Tra trong danh sách",function()
            self:prompt("Tìm từ","Nhập một phần từ tiếng Anh hoặc nghĩa tiếng Việt.","",function(query)
                local choices={}
                if query=="" then return end
                query=query:lower()
                for i,pair in ipairs(vocabulary) do
                    if pair[1]:find(query,1,true) or pair[2]:find(query,1,true) then
                        choices[#choices+1]={pair[1],function() self:studyCard(vocabulary,i,true,"words") end}
                    end
                end
                if #choices==0 then self:notice("Chưa có từ này trong bộ từ."); return end
                self:menu("Kết quả",choices,function() self:words() end)
            end)
        end},
    },function() self:utilities() end)
end

function App:studyCard(list,i,reveal,mode)
    local back=function() self[mode](self) end
    self:view(i.."/"..#list,list[i][1]..(reveal and "\n\n"..list[i][2] or ""),back,{
        rows={{self:button(reveal and "Ẩn đáp án" or "Lật thẻ",function() self:studyCard(list,i,not reveal,mode) end),
            self:button("Thẻ kế tiếp",function() self:studyCard(list,i%#list+1,false,mode) end)}},
    })
end

function App:flashcards()
    local data=self:read("cards",{})
    local choices={{"+ Thêm thẻ",function()
        self:prompt("Mặt trước",nil,"",function(front)
            if front=="" then return end
            self:prompt("Mặt sau",nil,"",function(reverse)
                if reverse=="" then return end
                data[#data+1]={front,reverse}
                self:save("cards",data)
                self:flashcards()
            end,{multiline=true})
        end)
    end}}
    if #data>0 then
        choices[#choices+1]={"Ôn "..#data.." thẻ",function() self:studyCard(data,1,false,"flashcards") end}
        choices[#choices+1]={"Quản lý thẻ",function()
            local rows={}
            for i,card in ipairs(data) do
                rows[#rows+1]={card[1],function()
                    self:menu(card[1],{{"Xóa thẻ",function()
                        self:menu("Xóa thẻ này?",{{"Xóa",function()
                            table.remove(data,i); self:save("cards",data); self:flashcards()
                        end}},function() self:flashcards() end)
                    end}},function() self:flashcards() end)
                end}
            end
            self:menu("Quản lý thẻ",rows,function() self:flashcards() end)
        end}
    end
    self:menu("Thẻ tự tạo",choices,function() self:utilities() end)
end

function App:notes()
    local data=self:read("notes",{})
    local function edit(i)
        self:prompt(i and "Sửa ghi chú" or "Ghi chú mới",nil,i and data[i] or "",function(body)
            if body=="" then return end
            data[i or #data+1]=body
            self:save("notes",data)
            self:notes()
        end,{multiline=true,action="Lưu"})
    end
    local choices={{"+ Thêm ghi chú",function() edit() end}}
    for i,note in ipairs(data) do
        choices[#choices+1]={note:match("^[^\n]+") or "Ghi chú",function()
            self:view("Ghi chú "..i,note,function() self:notes() end,{
                rows={{self:button("Sửa",function() edit(i) end),self:button("Xóa",function()
                    self:menu("Xóa ghi chú này?",{{"Xóa",function()
                        table.remove(data,i); self:save("notes",data); self:notes()
                    end}},function() self:notes() end)
                end)}},
            })
        end}
    end
    self:menu("Ghi chú",choices,function() self:utilities() end)
end

function App:convert()
    local cases={
        {"km → dặm",function(n) return n/1.609344 end},
        {"dặm → km",function(n) return n*1.609344 end},
        {"kg → lb",function(n) return n/0.45359237 end},
        {"lb → kg",function(n) return n*0.45359237 end},
        {"°C → °F",function(n) return n*9/5+32 end},
        {"°F → °C",function(n) return (n-32)*5/9 end},
        {"cm → inch",function(n) return n/2.54 end},
        {"inch → cm",function(n) return n*2.54 end},
    }
    local choices={}
    for _,item in ipairs(cases) do choices[#choices+1]={item[1],function()
        self:prompt(item[1],"Nhập giá trị.","",function(value)
            local n=tonumber((value:gsub(",",".")))
            if n and math.abs(n)<=1e12 then self:notice(string.format("%g → %.6g",n,item[2](n)))
            else self:notice("Nhập số hợp lệ.") end
        end,{number=true})
    end} end
    self:menu("Đổi đơn vị",choices,function() self:utilities() end)
end

function App:calculate()
    self:prompt("Máy tính","Nhập hai số và phép tính, ví dụ 12.5 * 4.","",function(text)
        local a,op,b=text:match("^([+-]?[%d.,]+)%s*([+*/^-])%s*([+-]?[%d.,]+)$")
        if a then a,b=tonumber((a:gsub(",","."))),tonumber((b:gsub(",","."))) end
        if not a or not b or (op=="/" and b==0) then self:notice("Biểu thức không hợp lệ."); return end
        local ops={["+"]=function() return a+b end,["-"]=function() return a-b end,
            ["*"]=function() return a*b end,["/"]=function() return a/b end,["^"]=function() return a^b end}
        local result=ops[op]()
        if result~=result or math.abs(result)==math.huge then self:notice("Kết quả ngoài phạm vi."); return end
        self:notice("Kết quả: "..string.format("%.12g",result))
    end)
end

function App:dice()
    local choices={}
    for n=1,3 do choices[#choices+1]={n.." viên",function()
        local values={}
        for i=1,n do values[i]=math.random(1,6) end
        self:notice(table.concat(values,"  ·  "))
    end} end
    self:menu("Xúc xắc",choices,function() self:utilities() end)
end

function App:coin()
    self:show("Đồng xu\n"..(math.random(2)==1 and "Ngửa" or "Sấp"),
        {{self:button("Tung lại",function() self:coin() end)}},function() self:utilities() end)
end

function App:randomNumber()
    self:prompt("Bốc số","Nhập khoảng, ví dụ 1 100.","1 100",function(input)
        local low,high=input:match("^(%-?%d+)%s+(%-?%d+)$")
        low,high=tonumber(low),tonumber(high)
        if not low or not high or low>high or low< -10000000 or high>10000000 then
            self:notice("Khoảng không hợp lệ."); return
        end
        self:notice("Kết quả: "..math.random(low,high))
    end)
end

function App:water(day)
    local date=day or os.date("%Y-%m-%d")
    local data=self:read("water",{})
    local n=data[date] or 0
    local function change(amount)
        data[date]=math.max(0,n+amount)
        self:save("water",data)
        self:water(date)
    end
    self:show("Nước uống · "..date.."\n"..n.." mL",{
        {self:button("+ 250 mL",function() change(250) end),self:button("− 250 mL",function() change(-250) end)},
        {self:button("Xem 7 ngày",function()
            local rows={}
            local today=os.date("*t")
            for delta=0,6 do
                local ts=os.time{year=today.year,month=today.month,day=today.day-delta,hour=12}
                local d=os.date("%Y-%m-%d",ts)
                rows[#rows+1]=d.." · "..(data[d] or 0).." mL"
            end
            self:view("Nước uống · 7 ngày",table.concat(rows,"\n"),function() self:water() end)
        end)},
    },function() self:utilities() end)
end
end
