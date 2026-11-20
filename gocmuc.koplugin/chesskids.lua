local Chess = {}
local files = "abcdefgh"
local start = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
local knight = {-33, -31, -18, -14, 14, 18, 31, 33}
local bishop = {-17, -15, 15, 17}
local rook = {-16, -1, 1, 16}
local king = {-17, -16, -15, -1, 1, 15, 16, 17}
local values = {p=100, n=320, b=330, r=500, q=900, k=0}
local castle_right = {[0]="Q", [7]="K", [112]="q", [119]="k"}

local function valid(s)
    return s >= 0 and s < 120 and s % 16 < 8
end

local function white(p)
    return p == p:upper()
end

function Chess.square(s)
    if type(s) ~= "string" or not s:match("^[a-h][1-8]$") then return nil end
    return (tonumber(s:sub(2)) - 1) * 16 + files:find(s:sub(1,1), 1, true) - 1
end

function Chess.name(s)
    local f = s % 16 + 1
    return files:sub(f,f) .. (math.floor(s / 16) + 1)
end

function Chess.fromFen(fen)
    local fields = {}
    for field in (fen or start):gmatch("%S+") do fields[#fields+1] = field end
    local board = {}
    local r = 7
    for row in fields[1]:gmatch("[^/]+") do
        local f = 0
        for p in row:gmatch(".") do
            local n = tonumber(p)
            if not n then board[r*16+f] = p end
            f = f + (n or 1)
        end
        r = r - 1
    end
    return {board=board, white=fields[2]=="w", rights=fields[3]:gsub("-", ""),
        ep=Chess.square(fields[4]), half=tonumber(fields[5]) or 0, full=tonumber(fields[6]) or 1}
end

function Chess.fen(pos)
    local ranks = {}
    for r = 7, 0, -1 do
        local rank, empty = "", 0
        for f = 0, 7 do
            local p = pos.board[r*16+f]
            if p then
                rank = rank .. (empty > 0 and empty or "") .. p
                empty = 0
            else
                empty = empty + 1
            end
        end
        ranks[#ranks+1] = rank .. (empty > 0 and empty or "")
    end
    return table.concat(ranks,"/") .. " " .. (pos.white and "w" or "b") .. " "
        .. (pos.rights ~= "" and pos.rights or "-") .. " " .. (pos.ep and Chess.name(pos.ep) or "-")
        .. " " .. pos.half .. " " .. pos.full
end

local function attacked(board, s, by_white)
    local direction = by_white and 16 or -16
    local pawn = by_white and "P" or "p"
    for _, d in ipairs({direction-1, direction+1}) do
        if valid(s-d) and board[s-d] == pawn then return true end
    end
    local n = by_white and "N" or "n"
    for _, d in ipairs(knight) do
        if valid(s+d) and board[s+d] == n then return true end
    end
    for _, d in ipairs(king) do
        local t = s + d
        while valid(t) do
            local p = board[t]
            if p then
                if white(p) == by_white then
                    local kind = p:lower()
                    local straight = math.abs(d) == 16 or math.abs(d) == 1
                    if kind == "q" or (kind == "k" and t == s + d)
                        or (kind == "r" and straight) or (kind == "b" and not straight) then return true end
                end
                break
            end
            t = t + d
        end
    end
    return false
end

function Chess.inCheck(pos, side)
    local piece = side and "K" or "k"
    for s, p in pairs(pos.board) do
        if p == piece then return attacked(pos.board, s, not side) end
    end
    return true
end

function Chess.apply(pos, m)
    local board = {}
    for s, p in pairs(pos.board) do board[s] = p end
    local p, captured = board[m.from], board[m.to]
    local rights = pos.rights
    local kind = p:lower()
    local direction = pos.white and 16 or -16
    local ep
    if kind == "p" then
        if m.to == pos.ep and not captured then board[m.to-direction] = nil end
        if math.abs(m.to-m.from) == 32 then ep = m.from + direction end
    elseif kind == "k" then
        rights = rights:gsub(pos.white and "[KQ]" or "[kq]", "")
        if m.to-m.from == 2 then
            board[m.from+1], board[m.from+3] = board[m.from+3], nil
        elseif m.to-m.from == -2 then
            board[m.from-1], board[m.from-4] = board[m.from-4], nil
        end
    end
    if castle_right[m.from] then rights = rights:gsub(castle_right[m.from], "") end
    if castle_right[m.to] then rights = rights:gsub(castle_right[m.to], "") end
    board[m.from] = nil
    board[m.to] = m.promote and (pos.white and m.promote:upper() or m.promote) or p
    return {board=board, white=not pos.white, rights=rights, ep=ep,
        half=(kind == "p" or captured) and 0 or pos.half+1, full=pos.full+(pos.white and 0 or 1)}
end

local function pseudo(pos)
    local out, board, side = {}, pos.board, pos.white
    local function add(s, t, promotion)
        if promotion then
            for c in ("qrbn"):gmatch(".") do out[#out+1] = {from=s,to=t,promote=c} end
        else
            out[#out+1] = {from=s,to=t}
        end
    end
    for r=0,7 do
        for f=0,7 do
            local s = r*16+f
            local p = board[s]
            if p and white(p) == side then
                local kind = p:lower()
                if kind == "p" then
                    local d = side and 16 or -16
                    local promote = r == (side and 6 or 1)
                    if valid(s+d) and not board[s+d] then
                        add(s,s+d,promote)
                        if r == (side and 1 or 6) and not board[s+2*d] then add(s,s+2*d) end
                    end
                    for _, t in ipairs({s+d-1,s+d+1}) do
                        local target = board[t]
                        if valid(t) and ((target and white(target) ~= side and target:lower() ~= "k")
                            or (t == pos.ep and board[t-d] == (side and "p" or "P"))) then
                            add(s,t,promote)
                        end
                    end
                else
                    local dirs = ({n=knight,b=bishop,r=rook,q=king,k=king})[kind]
                    for _, d in ipairs(dirs) do
                        local t = s+d
                        while valid(t) do
                            local target = board[t]
                            if not target or (white(target) ~= side and target:lower() ~= "k") then add(s,t) end
                            if target or kind == "n" or kind == "k" then break end
                            t = t+d
                        end
                    end
                    if kind == "k" and s == (side and 4 or 116) and not attacked(board,s,not side) then
                        local own_rook = side and "R" or "r"
                        if pos.rights:find(side and "K" or "k",1,true) and board[s+3] == own_rook
                            and not board[s+1] and not board[s+2] and not attacked(board,s+1,not side) then add(s,s+2) end
                        if pos.rights:find(side and "Q" or "q",1,true) and board[s-4] == own_rook
                            and not board[s-1] and not board[s-2] and not board[s-3]
                            and not attacked(board,s-1,not side) then add(s,s-2) end
                    end
                end
            end
        end
    end
    return out
end

function Chess.legal(pos)
    local out = {}
    for _, m in ipairs(pseudo(pos)) do
        if not Chess.inCheck(Chess.apply(pos,m),pos.white) then out[#out+1] = m end
    end
    return out
end

function Chess.uci(m)
    return Chess.name(m.from) .. Chess.name(m.to) .. (m.promote or "")
end

function Chess.find(pos, uci)
    for _, move in ipairs(Chess.legal(pos)) do
        if Chess.uci(move) == uci then return move end
    end
end

function Chess.key(pos)
    local board,turn,rights,ep = Chess.fen(pos):match("^(%S+) (%S+) (%S+) (%S+)")
    if pos.ep then
        ep = "-"
        for _,m in ipairs(Chess.legal(pos)) do
            if m.to==pos.ep and pos.board[m.from]:lower()=="p" and m.from%16~=m.to%16 then
                ep=Chess.name(pos.ep)
                break
            end
        end
    end
    return table.concat({board,turn,rights,ep}," ")
end

function Chess.result(pos, legal, history)
    if #legal == 0 then return Chess.inCheck(pos,pos.white) and "Chiếu hết" or "Hòa bí nước" end
    if pos.half >= 100 then return "Hòa theo luật 50 nước" end
    local material, bishop_color = {}, nil
    for s,p in pairs(pos.board) do
        local kind = p:lower()
        if kind ~= "k" then
            material[#material+1] = kind
            if kind == "b" then
                local color = (s%16 + math.floor(s/16))%2
                if bishop_color == nil then bishop_color = color
                elseif bishop_color ~= color then bishop_color = -1 end
            end
        end
    end
    if #material == 0 or (#material == 1 and (material[1]=="n" or material[1]=="b")) then
        return "Hòa do thiếu quân chiếu hết"
    end
    if bishop_color ~= nil and bishop_color >= 0 and not table.concat(material):find("[^b]") then
        return "Hòa do thiếu quân chiếu hết"
    end
    local current, repeats = Chess.key(pos), 1
    for _, earlier in ipairs(history or {}) do
        if Chess.key(earlier) == current then repeats = repeats+1 end
    end
    if repeats >= 3 then return "Hòa do lặp thế cờ" end
end

local function evaluate(pos)
    local score = 0
    for s, p in pairs(pos.board) do
        local kind = p:lower()
        local distance = math.abs(s%16-3.5)+math.abs(math.floor(s/16)-3.5)
        local value = values[kind] + (kind == "k" and 0 or (7-distance)*4)
        score = score + (white(p) and value or -value)
    end
    return pos.white and score or -score
end

local function search(pos, depth, alpha, beta, ply)
    local legal = Chess.legal(pos)
    if #legal == 0 then return Chess.inCheck(pos,pos.white) and -30000+ply or 0 end
    if depth == 0 then return evaluate(pos) end
    for _, m in ipairs(legal) do
        local score = -search(Chess.apply(pos,m),depth-1,-beta,-alpha,ply+1)
        if score >= beta then return score end
        alpha = math.max(alpha,score)
    end
    return alpha
end

function Chess.bot(pos, level, legal)
    local depth = level >= 5 and 2 or 1
    local randomness = ({500, 280, 120, 45, 12, 0})[level] or 0
    local best, score
    for _, m in ipairs(legal) do
        local next_pos = Chess.apply(pos,m)
        local candidate = -search(next_pos,depth-1,-math.huge,math.huge,1) + math.random(0, randomness)
        if not score or candidate > score then best, score = m, candidate end
    end
    return best
end

return Chess
