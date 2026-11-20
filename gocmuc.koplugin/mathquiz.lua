local Quiz = {}
local rand = math.random

local function q(vi,en,answer,why,why_en,diagram)
    return {vi=vi,en=en,answer=answer,why=why,why_en=why_en,diagram=diagram}
end

local function sequence(level)
    local start, step = rand(1,15*level), rand(2,level*3+1)
    local terms = {}
    for index=0,3 do terms[#terms+1] = start+index*step end
    return q("Số tiếp theo trong dãy là bao nhiêu?", "What is the next number?",
        start+4*step, "Mỗi bước cộng "..step..". Cộng vào số cuối.", "Add "..step.." to the last term.",
        table.concat(terms,"  ·  ").."  ·  ?")
end

local function shapes(level)
    local n, m = rand(2,level+2),rand(2,level+2)
    local answer = math.min(n,m)*(n+1)*(m+1) -
        (n+m+2)*math.min(n,m)*(math.min(n,m)+1)/2 +
        math.min(n,m)*(math.min(n,m)+1)*(2*math.min(n,m)+1)/6
    local lines = {}
    for _=1,m do lines[#lines+1] = string.rep("□ ",n) end
    return q("Lưới "..n.." × "..m.." ô có bao nhiêu hình vuông theo đường kẻ? Tính mọi cỡ.",
        "How many squares of any size follow the lines of a "..n.." × "..m.." grid?", answer,
        "Với cạnh k, có ("..n.." − k + 1) × ("..m.." − k + 1) vị trí. Cộng cho mọi k.",
        "For side k, count ("..n.." − k + 1) × ("..m.." − k + 1) positions and sum over k.",
        table.concat(lines,"\n"))
end

local function balance(level)
    local a,b,c = rand(2,level+3),rand(1,level+3),rand(1,8)
    return q("Cân ở trạng thái thăng bằng. Một hộp nặng bao nhiêu kg?",
        "The scale is balanced. How many kg does one box weigh?",c,
        "Bỏ "..b.." kg ở cả hai đĩa. Chia "..(a*c).." kg cho "..a.." hộp.",
        "Remove "..b.." kg from both sides. Divide "..(a*c).." kg by "..a.." boxes.",
        string.rep("□ ",a).." + "..b.." kg = "..(a*c+b).." kg")
end

local function mirror()
    local n = rand(3,8)
    local m = rand(1,2*n)
    return q("Trục gương nằm giữa cột "..n.." và "..(n+1)..". Một chấm ở cột "..m..
        ". Ảnh ở cột nào?", "A mirror lies between columns "..n.." and "..(n+1)..
        ". A dot is in column "..m..". Which column is its reflection in?",
        2*n+1-m, "Hai cột cách trục như nhau, tổng số cột là "..(2*n+1)..".",
        "The column numbers sum to "..(2*n+1).." by symmetry.")
end

local function pyramid(level)
    local a,b,c = rand(1,6*level),rand(1,6*level),rand(1,6*level)
    return q("Mỗi ô là tổng hai ô ngay dưới nó. Số ở đỉnh là bao nhiêu?",
        "Every cell is the sum of the two below it. What number is at the top?",a+2*b+c,
        "Hàng giữa gồm "..(a+b).." và "..(b+c)..". Cộng hai số đó.",
        "The middle row is "..(a+b).." and "..(b+c)..". Add them.",
        "          ?\n      □      □\n   "..a.."      "..b.."      "..c)
end

local function chart(level)
    local a,b,c = rand(2,level+4),rand(2,level+4),rand(2,level+4)
    local unit = rand(1,level)
    return q("Mỗi ô biểu thị "..unit.." quyển. Ba bạn đọc tổng cộng bao nhiêu quyển?",
        "Each block is "..unit.." book(s). How many books did the three children read?",(a+b+c)*unit,
        "Cộng số ô của ba hàng rồi nhân với "..unit..".",
        "Add the blocks across the three rows and multiply by "..unit..".",
        "An  "..string.rep("■",a).."\nBình  "..string.rep("■",b).."\nChi  "..string.rep("■",c))
end

local function arithmetic(level)
    if level==1 then
        local a,b,c=rand(5,18),rand(2,8),rand(1,7)
        return q("Có "..a.." viên bi. Được thêm "..b.." viên rồi cho đi "..c.." viên. Còn bao nhiêu?",
            "You have "..a.." marbles, get "..b.." more, then give "..c.." away. How many remain?",
            a+b-c,"Cộng hai số đầu, được "..(a+b)..". Trừ "..c..".",
            "Add the first two numbers to get "..(a+b)..", then subtract "..c..".")
    end
    local n, a = rand(2,level+6),rand(2,5*level)
    local b = rand(1,math.min(6,n*a))
    return q("Có "..n.." túi, mỗi túi "..a.." viên bi. Cho đi "..b.." viên thì còn bao nhiêu?",
        "There are "..n.." bags of "..a.." marbles. How many remain after giving away "..b.."?", n*a-b,
        "Nhân "..n.." với "..a.." được "..(n*a)..", rồi trừ "..b..".",
        "Multiply "..n.." by "..a.." to get "..(n*a)..", then subtract "..b..".")
end

local function fraction(level)
    local d, multiple = rand(3,level+5),rand(3,level+8)
    local n = rand(1,d-1)
    return q(n.."/"..d.." của "..(d*multiple).." là bao nhiêu?",
        "What is "..n.."/"..d.." of "..(d*multiple).."?",n*multiple,
        "Chia tổng cho "..d.." được "..multiple..". Nhân với "..n..".",
        "Divide by "..d.." to get "..multiple..", then multiply by "..n..".")
end

local function decimal()
    local a,b = rand(11,99),rand(11,99)
    return q("Tổng của "..(a/10).." và "..(b/10).." bằng bao nhiêu?",
        "What is the sum of "..(a/10).." and "..(b/10).."?",(a+b)/10,
        "Đổi sang phần mười: "..a.." + "..b.." = "..(a+b).." phần mười.",
        "In tenths: "..a.." + "..b.." = "..(a+b).." tenths.")
end

local function percent()
    local a,b = rand(2,12),rand(1,9)
    return q((b*10).."% của "..(a*10).." là bao nhiêu?", "What is "..(b*10).."% of "..(a*10).."?",a*b,
        "10% là "..a..". Nhân với "..b..".", "10% is "..a..". Multiply by "..b..".")
end

local function speed()
    local a,b,c = rand(12,45),rand(12,45),rand(2,5)
    return q("Hai xe xuất phát cùng điểm, đi ngược chiều với "..a.." và "..b.." km/h. Sau "..c.." giờ, cách nhau bao nhiêu km?",
        "Two vehicles leave in opposite directions at "..a.." and "..b.." km/h. How far apart after "..c.." hours?",
        (a+b)*c, "Cộng vận tốc, rồi nhân với thời gian.", "Add their speeds and multiply by time.")
end

local function geometry()
    local a,b,c = rand(2,8)*2,rand(5,14)*2,rand(3,12)
    local shape = rand(1,3)
    if shape==1 then
        return q("Hình thang có hai đáy "..a.." cm, "..b.." cm và cao "..c.." cm. Diện tích bằng bao nhiêu cm²?",
            "A trapezoid has bases "..a.." cm and "..b.." cm, height "..c.." cm. What is its area in cm²?",
            (a+b)*c/2,"Cộng hai đáy, nhân chiều cao rồi chia 2.","Add the bases, multiply by height and divide by 2.")
    elseif shape==2 then
        return q("Hình tròn bán kính "..c.." cm. Dùng π = 3, diện tích là bao nhiêu cm²?",
            "A circle has radius "..c.." cm. Use π = 3. What is its area in cm²?",
            3*c*c,"Nhân 3 với bình phương bán kính.","Multiply 3 by the radius squared.")
    end
    return q("Hộp dài "..a.." cm, rộng "..b.." cm, cao "..c.." cm. Thể tích bao nhiêu cm³?",
        "A box measures "..a.." by "..b.." by "..c.." cm. What is its volume in cm³?",
        a*b*c,"Nhân chiều dài, chiều rộng và chiều cao.","Multiply the three dimensions.")
end

local all = {sequence,shapes,balance,pyramid,chart,arithmetic,mirror,fraction,decimal,percent,speed,geometry}
local count = {6,7,8,10,12}

function Quiz.new(grade, mode)
    local total = mode == "Kangaroo" and 24 or mode == "ASMO" and 25 or 10
    local quiz = {items={}, total=total, mode=mode, grade=grade, score=0, possible=0, index=1, started=os.time()}
    local used = {}
    for i=1,total do
        local weight = i <= math.floor(total/3) and 3 or i <= math.floor(total*2/3) and 4 or 5
        local item, key
        repeat
            item = all[rand(1,count[grade])](grade)
            key = item.vi .. (item.diagram or "")
        until not used[key]
        used[key] = true
        item.weight = weight
        local options, answer = {}, item.answer
        local spacing = answer % 1 == 0 and math.max(1,math.min(12,math.floor(answer/12))) or 0.1
        local slot = rand(1,5)
        local offset = math.max(0, answer - (slot-1)*spacing)
        local value = offset
        for j=1,5 do
            if j==slot then options[j] = answer
            else
                while math.abs(value-answer)<0.0001 do value = value+spacing end
                options[j] = value
                value = value+spacing
            end
        end
        item.options = options
        quiz.items[i] = item
        quiz.possible = quiz.possible + weight
    end
    return quiz
end

function Quiz.answer(quiz, selected)
    local item = quiz.items[quiz.index]
    if not item or item.graded then return false end
    item.graded = true
    item.selected = selected
    item.correct = selected and math.abs(item.options[selected] - item.answer) < 0.0001 or false
    if item.correct then quiz.score=quiz.score+item.weight
    elseif selected and quiz.mode=="Kangaroo" then quiz.score=quiz.score-item.weight/4 end
    return item.correct
end

return Quiz
