local root=arg[1] or "gocmuc.koplugin"
local Chess=dofile(root.."/chesskids.lua")
local Caro=dofile(root.."/caro.lua")
local Quiz=dofile(root.."/mathquiz.lua")
local Lunar=dofile(root.."/lunar.lua")
local Sudoku=dofile(root.."/sudoku.lua")
math.randomseed(202411)

local function perft(pos,depth)
    if depth==0 then return 1 end
    local n=0
    for _,m in ipairs(Chess.legal(pos)) do n=n+perft(Chess.apply(pos,m),depth-1) end
    return n
end
assert(perft(Chess.fromFen(),3)==8902)
assert(perft(Chess.fromFen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"),2)==2039)
local ep=Chess.fromFen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
local used=Chess.apply(ep,assert(Chess.find(ep,"e5d6")))
assert(not used.board[Chess.square("d5")] and used.board[Chess.square("d6")]=="P")

local marks={}
for x=4,8 do marks[Caro.index(x,7)]="X" end
assert(Caro.win(marks,Caro.index(8,7),"X"))
marks[Caro.index(3,7)]="O"
marks[Caro.index(9,7)]="O"
assert(not Caro.win(marks,Caro.index(8,7),"X"))
marks[Caro.index(8,7)]=nil
assert(Caro.bot(marks,"X",5)~=nil)

for _,sample in ipairs({{10,2,2024,1,1,false},{29,1,2025,1,1,false},
    {25,7,2025,1,6,true},{17,2,2026,1,1,false},{6,2,2027,1,1,false}}) do
    local day,month,_,leap=Lunar.date(sample[1],sample[2],sample[3])
    assert(day==sample[4] and month==sample[5] and leap==sample[6],Lunar.label(sample[1],sample[2],sample[3]))
end

for grade=1,5 do
    for mode,count in pairs({["Luyện tập"]=10,Kangaroo=24,ASMO=25}) do
        for _=1,10 do
            local quiz=Quiz.new(grade,mode)
            assert(#quiz.items==count and quiz.possible>0)
            for i,item in ipairs(quiz.items) do
                local correct
                local seen={}
                assert(#item.options==5 and item.vi~="" and item.why_en~="")
                for j,option in ipairs(item.options) do
                    local label=string.format("%g",option)
                    assert(not seen[label],"duplicate option")
                    seen[label]=true
                    if math.abs(item.answer-option)<0.0001 then assert(not correct); correct=j end
                end
                quiz.index=i
                assert(correct and Quiz.answer(quiz,correct))
                assert(not Quiz.answer(quiz,correct))
            end
            assert(quiz.score==quiz.possible)
        end
    end
end

for level=1,3 do
    local game=Sudoku.new(level)
    local empty=0
    for i=1,81 do
        if game.board[i]==0 then empty=empty+1; assert(not game.fixed[i])
        else assert(game.fixed[i] and Sudoku.allowed(game.board,i,game.board[i])) end
    end
    assert(empty>=31)
end

print("Chess perft, Caro, 150 math quizzes, Vietnamese lunar dates and Sudoku passed.")