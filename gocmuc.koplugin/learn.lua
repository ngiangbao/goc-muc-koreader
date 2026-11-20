return function(App,env)
local Quiz=dofile(env.root.."/mathquiz.lua")
local UI=env.UI

function App:mathMenu()
    local choices={}
    for grade=1,5 do
        choices[#choices+1]={"Lớp "..grade,function() self:mathModes(grade) end,"math"}
    end
    self:menu("Toán tư duy",choices,function() self:home() end,{icon="math",subtitle="Lớp 1–5 · Việt / Anh"})
end

function App:mathModes(grade)
    local choices={}
    for _,mode in ipairs({"Luyện tập","Kangaroo","ASMO"}) do
        local label=({["Luyện tập"]="Luyện tập · 10 câu",Kangaroo="Thi thử Kangaroo · 24 câu",ASMO="Thi thử ASMO · 25 câu"})[mode]
        choices[#choices+1]={label,function()
            local quiz=Quiz.new(grade,mode)
            if mode=="Luyện tập" then self:mathQuestion(quiz); return end
            self:prompt(label,"Thời gian làm bài (phút)","60",function(value)
                local minutes=tonumber(value)
                if not minutes or minutes<1 or minutes>180 then self:notice("Nhập từ 1 đến 180 phút."); return end
                quiz.deadline=os.time()+math.floor(minutes*60)
                self.active_quiz=quiz
                UI:scheduleIn(math.floor(minutes*60),function()
                    if self.active_quiz==quiz then
                        self.active_quiz=nil
                        self:mathResults(quiz)
                    end
                end)
                self:mathQuestion(quiz)
            end,{number=true,action="Bắt đầu"})
        end}
    end
    self:menu("Toán tư duy · Lớp "..grade,choices,function() self:mathMenu() end,{icon="math"})
end

local function duration(seconds)
    seconds=math.max(0,seconds)
    return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
end

function App:mathQuestion(quiz)
    if quiz.index>quiz.total or (quiz.deadline and os.time()>=quiz.deadline) then
        self:mathResults(quiz)
        return
    end
    local item=quiz.items[quiz.index]
    local question=item.vi.."\n"..item.en
    if item.diagram then question=question.."\n\n"..item.diagram end
    local header="Câu "..quiz.index.."/"..quiz.total.." · "..item.weight.." điểm"
    if quiz.deadline then header=header.." · Còn "..duration(quiz.deadline-os.time()) end
    local function next_question()
        quiz.index=quiz.index+1
        self:mathQuestion(quiz)
    end
    local function choose(index)
        if quiz.deadline and os.time()>=quiz.deadline then self:mathResults(quiz); return end
        Quiz.answer(quiz,index)
        if quiz.mode=="Luyện tập" then
            self:mathExplanation(quiz,quiz.index,next_question)
        else
            next_question()
        end
    end
    local rows={{},{},{}}
    for i,option in ipairs(item.options) do
        local row=rows[math.floor((i-1)/2)+1]
        row[#row+1]=self:button(string.char(64+i)..". "..string.format("%g",option),function() choose(i) end)
    end
    rows[3][2]=self:button("Bỏ qua",function() choose(nil) end)
    local function exit()
        self:menu("Dừng làm bài?",{
            {"Tiếp tục",function() self:mathQuestion(quiz) end},
            {"Nộp và xem kết quả",function() self:mathResults(quiz) end},
            {"Thoát bài",function() self:home() end,"exit"},
        },function() self:mathQuestion(quiz) end)
    end
    self:view(header,question,exit,{rows=rows})
end

function App:mathExplanation(quiz,index,back)
    local item=quiz.items[index]
    local state=item.correct and "Đúng" or item.selected and "Sai" or "Chưa trả lời"
    local text=item.vi.."\n"..item.en.."\n\n"
        .."Đáp án / Answer: "..string.format("%g",item.answer).."\n\n"..item.why.."\n\n"..item.why_en
    if item.diagram then text=text.."\n\n"..item.diagram end
    self:view("Câu "..index.." · "..state,text,back)
end

function App:mathResults(quiz)
    self.active_quiz=nil
    local right,attempted=0,0
    for _,item in ipairs(quiz.items) do
        if item.correct then right=right+1 end
        if item.selected then attempted=attempted+1 end
    end
    local title=string.format("%s · %g / %g điểm",quiz.mode,quiz.score,quiz.possible)
    self:menu(title,{
        {right.." đúng · "..attempted.." đã trả lời",function()
            self:notice("Thời gian làm bài: "..duration(os.time()-quiz.started))
        end},
        {"Xem lời giải song ngữ",function()
            local questions={}
            for i,item in ipairs(quiz.items) do
                questions[#questions+1]={"Câu "..i.." · "..(item.correct and "Đúng" or item.selected and "Sai" or "Bỏ trống"),
                    function() self:mathExplanation(quiz,i,function() self:mathResults(quiz) end) end}
            end
            self:menu("Lời giải",questions,function() self:mathResults(quiz) end)
        end},
        {"Chọn đề mới",function() self:mathModes(quiz.grade) end},
    },function() self:mathMenu() end)
end

local reading={
    {"Truyện cổ tích",{
        {"Cây tre trăm đốt","Ngày xưa, một anh làm thuê chăm chỉ được hứa thưởng nếu làm việc tốt. Đến hẹn, chủ nhà sai anh vào rừng kiếm cây tre có một trăm đốt. Anh tìm mãi chỉ thấy từng cây ngắn. Một ông lão bảo anh góp đủ một trăm đốt rồi nói «khắc nhập». Các đốt tre nối liền nhau. Khi chủ nhà chịu giữ lời, anh nói «khắc xuất», tre tách ra để mọi người cùng khiêng về."},
        {"Sự tích trầu cau","Hai anh em thân thiết đến mức ai gặp cũng khó phân biệt. Khi người anh lập gia đình, hiểu lầm khiến người em bỏ đi. Anh tìm em, rồi người vợ cũng đi tìm cả hai. Dân gian kể ba người hóa thành cây cau, dây trầu và hòn đá vôi. Lá trầu cuốn với cau và vôi cho màu đỏ, nhắc người đời về nghĩa tình."},
        {"Ếch ngồi đáy giếng","Một con ếch sống trong giếng. Mỗi ngày nhìn lên, nó chỉ thấy khoảng trời tròn bằng miệng giếng. Một trận mưa to đưa nó ra ngoài. Bấy giờ nó mới thấy trời rộng và biết rằng những gì mình từng nhìn thấy chỉ là một phần rất nhỏ."},
    }},
    {"Ca dao và tục ngữ",{
        {"Công cha, nghĩa mẹ","Công cha như núi Thái Sơn,\nNghĩa mẹ như nước trong nguồn chảy ra.\nMột lòng thờ mẹ kính cha,\nCho tròn chữ hiếu mới là đạo con."},
        {"Một cây làm chẳng nên non","Một cây làm chẳng nên non,\nBa cây chụm lại nên hòn núi cao.\n\nCâu ca dao nhắc ta về sức mạnh của việc cùng nhau góp sức."},
        {"Có công mài sắt","Có công mài sắt, có ngày nên kim.\n\nViệc khó trở nên dễ hơn khi ta kiên nhẫn luyện tập mỗi ngày."},
        {"Lá lành đùm lá rách","Người có điều kiện thuận lợi sẻ chia với người đang gặp khó khăn, như chiếc lá lành bọc lấy chiếc lá rách."},
    }},
    {"Câu đố",{
        {"Càng lấy đi càng lớn. Là gì?","Cái hố."},
        {"Có cổ mà chẳng có đầu. Là gì?","Cái chai."},
        {"Quanh năm có mặt mà chẳng có mũi. Là gì?","Cái đồng hồ."},
        {"Cái gì càng lau lại càng ướt?","Cái khăn."},
    }},
}

function App:kidsMenu()
    local choices={}
    for _,group in ipairs(reading) do
        choices[#choices+1]={group[1],function()
            local list={}
            local function show()
                self:menu(group[1],list,function() self:kidsMenu() end)
            end
            for _,story in ipairs(group[2]) do
                list[#list+1]={story[1],function() self:view(story[1],story[2],show) end}
            end
            show()
        end}
    end
    self:menu("Bé đọc",choices,function() self:home() end,{icon="book"})
end
end
