local Sudoku = {}

local function shuffle(t)
    for i=#t,2,-1 do
        local j=math.random(i)
        t[i],t[j]=t[j],t[i]
    end
    return t
end

local function index(r,c)
    return (r-1)*9+c
end

function Sudoku.allowed(board,i,n)
    local r,c=math.floor((i-1)/9)+1,(i-1)%9+1
    local br,bc=math.floor((r-1)/3)*3+1,math.floor((c-1)/3)*3+1
    for k=1,9 do
        local block=index(br+math.floor((k-1)/3),bc+(k-1)%3)
        if (index(r,k)~=i and board[index(r,k)]==n)
            or (index(k,c)~=i and board[index(k,c)]==n)
            or (block~=i and board[block]==n) then return false end
    end
    return true
end

local function solutions(board,limit)
    local best, candidates
    for i=1,81 do
        if board[i]==0 then
            local set={}
            for n=1,9 do if Sudoku.allowed(board,i,n) then set[#set+1]=n end end
            if #set==0 then return 0 end
            if not candidates or #set<#candidates then best,candidates=i,set end
            if #set==1 then break end
        end
    end
    if not best then return 1 end
    local count=0
    for _,n in ipairs(candidates) do
        board[best]=n
        count=count+solutions(board,limit-count)
        board[best]=0
        if count>=limit then break end
    end
    return count
end

function Sudoku.new(level)
    local order={1,2,3,4,5,6,7,8,9}
    shuffle(order)
    local board, fixed, places={}, {}, {}
    for r=1,9 do for c=1,9 do
        local i=index(r,c)
        board[i]=order[((r-1)*3+math.floor((r-1)/3)+c-1)%9+1]
        places[i]=i
    end end
    local removed=0
    for _,i in ipairs(shuffle(places)) do
        local save=board[i]
        board[i]=0
        if solutions(board,2)==1 then removed=removed+1 else board[i]=save end
        if removed>=({32,42,49})[level] then break end
    end
    for i=1,81 do fixed[i]=board[i]~=0 end
    return {board=board,fixed=fixed}
end

return Sudoku