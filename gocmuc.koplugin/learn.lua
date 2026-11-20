return function(App,env)
local Quiz=dofile(env.root.."/mathquiz.lua")
local Net=dofile(env.root.."/net.lua")
local HAC=dofile(env.root.."/hopamchuan.lua")
local UI=env.UI

function App:mathMenu()
    local choices={}
    for grade=1,5 do
        choices[#choices+1]={"Lớp "..grade,function() self:mathModes(grade) end}
    end
    self:menu("Toán tư duy · Việt / Anh",choices,function() self:home() end)
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
    self:menu("Toán tư duy · Lớp "..grade,choices,function() self:mathMenu() end)
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
            {"Thoát bài",function() self.active_quiz=nil; self:mathModes(quiz.grade) end},
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
    self:menu("Bé đọc",choices,function() self:home() end)
end

local names={"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}
local flat={Db=2,Eb=4,Gb=7,Ab=9,Bb=11,Cb=12,Fb=5}
local note={}
for i,n in ipairs(names) do note[n]=i end
for n,i in pairs(flat) do note[n]=i end

local function transpose(body,steps)
    return (body:gsub("%[([^%]]+)%]",function(chord)
        local root,suffix=chord:match("^([A-G][#b]?)(.*)$")
        local base=note[root]
        if not base then return "["..chord.."]" end
        suffix=suffix:gsub("/([A-G][#b]?)",function(bass)
            return "/"..(note[bass] and names[(note[bass]-1+steps)%12+1] or bass)
        end)
        return "["..names[(base-1+steps)%12+1]..suffix.."]"
    end))
end

local samples={
    {title="Bài tập vòng hợp âm C",body="[C]  [G]  [Am]  [F]\nGảy bốn phách mỗi hợp âm.\n\n[C/E]  [F]  [G7]  [C]\nThử thay đổi nốt trầm ở hợp âm đầu."},
    {title="Bài tập giọng thứ",body="[Am]  [Dm]  [E7]  [Am]\nGảy xen kẽ dây trầm và ba dây cao."},
}

function App:chordMenu()
    local choices={{"Thêm bài hợp âm",function()
        self:prompt("Tên bài",nil,"",function(title)
            if title=="" then return end
            self:prompt("Nội dung","Dùng [C], [Am], [G/B] quanh các hợp âm.","",function(body)
                if body=="" then return end
                local saved=self:read("chords",{})
                saved[#saved+1]={title=title,body=body}
                self:save("chords",saved)
                self:chordMenu()
            end,{multiline=true})
        end)
    end},{"Nhập từ Hợp Âm Chuẩn",function() self:importChords() end}}
    for _,list in ipairs({samples,self:read("chords",{})}) do
        for _,song in ipairs(list) do
            choices[#choices+1]={song.title,function() self:chordView(song,0) end}
        end
    end
    self:menu("Hợp âm",choices,function() self:home() end)
end

function App:importChords()
    self:prompt("Nhập từ Hợp Âm Chuẩn",
        "Dán link bài hát dạng https://hopamchuan.com/song/…. Góc Mực lưu ký hiệu hợp âm theo dòng.",
        "",function(value)
            local url=HAC.url(value)
            if not url then self:notice("Hãy nhập link một bài hát từ hopamchuan.com."); return end
            self:online(function()
                local html,err=Net.request(url)
                if not html then self:notice(err); return end
                local song,message=HAC.parse(html,Net.clean)
                if not song then self:notice(message); return end
                song.source=url
                local saved=self:read("chords",{})
                local index=#saved+1
                for i,entry in ipairs(saved) do
                    if entry.source==url then index=i; break end
                end
                saved[index]=song
                self:save("chords",saved)
                self:chordView(song,0)
            end)
        end,{action="Nhập hợp âm"})
end

function App:chordView(song,steps)
    local body=transpose(song.body,steps)
    if song.source then body=body.."\n\nNguồn: Hợp Âm Chuẩn\n"..song.source end
    self:view(song.title.." · "..string.format("%+d",steps),body,function() self:chordMenu() end,{
        rows={{self:button("− Nửa tông",function() self:chordView(song,steps-1) end),
            self:button("Giọng gốc",function() self:chordView(song,0) end),
            self:button("+ Nửa tông",function() self:chordView(song,steps+1) end)}},
    })
end
end
