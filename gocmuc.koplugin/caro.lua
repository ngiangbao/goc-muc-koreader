local Caro = {size=13}
local dirs = {{1,0},{0,1},{1,1},{1,-1}}

function Caro.index(x,y)
    if x>=1 and x<=Caro.size and y>=1 and y<=Caro.size then return (y-1)*Caro.size+x end
end

function Caro.xy(i)
    return (i-1)%Caro.size+1, math.floor((i-1)/Caro.size)+1
end

local function line(board,index,mark,dx,dy)
    local x,y = Caro.xy(index)
    local length, blocked = 1, 0
    for _, direction in ipairs({-1,1}) do
        local step = direction
        local i = Caro.index(x+dx*step,y+dy*step)
        while i and board[i] == mark do
            length, step = length+1, step+direction
            i = Caro.index(x+dx*step,y+dy*step)
        end
        if not i or board[i] then blocked = blocked+1 end
    end
    return length, blocked
end

function Caro.win(board,index,mark)
    for _, d in ipairs(dirs) do
        local length, blocked = line(board,index,mark,d[1],d[2])
        if length >= 5 and blocked < 2 then return true end
    end
    return false
end

local function value(board,i,mark)
    local total = 0
    local patterns = {1,6,37,310}
    for _, d in ipairs(dirs) do
        local n, blocked = line(board,i,mark,d[1],d[2])
        if n >= 5 and blocked < 2 then return 20000 end
        if blocked < 2 then total = total + (patterns[n] or 0) * (2-blocked) end
    end
    return total
end

function Caro.bot(board,mark,level)
    local other = mark == "X" and "O" or "X"
    local best, best_score
    for i=1,Caro.size^2 do
        if not board[i] then
            local attack = value(board,i,mark)
            local defense = value(board,i,other)
            local x,y = Caro.xy(i)
            local noise = ({45,24,12,4,0})[level]
            local score = attack * 1.1 + defense * (0.4 + level * 0.12)
                - (math.abs(x-7)+math.abs(y-7)) * 0.5 + math.random(0,noise)
            if not best or score > best_score then best,best_score = i,score end
        end
    end
    return best
end

return Caro