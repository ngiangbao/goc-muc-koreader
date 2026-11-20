return function(App,env)
local UI=env.UI
local Chess=dofile(env.root.."/chesskids.lua")
local Caro=dofile(env.root.."/caro.lua")
local Net=dofile(env.root.."/net.lua")
local Sudoku=dofile(env.root.."/sudoku.lua")
local PluginLoader=require("pluginloader")
local log=require("logger")

local function installed(app,name)
    if PluginLoader.getPluginInstance then
        return PluginLoader:getPluginInstance(name) or app.ui[name]
    end
    return app.ui[name]
end

function App:chessMenu()
    self:menu("Cờ vua",{
        {"Cờ vua T4\nHoàng Tuấn",function() self:openT4("chess") end,"knight"},
        {"Cờ vua cho bé\n6 mức",function() self:kidsChessMenu() end,"book"},
        {"Đấu Lichess\nInk Knight",function() self:openInkKnight() end,"link"},
    },function() self:home() end,{icon="knight",style="tiles"})
end

function App:openT4(tab)
    local function back()
        if tab=="settings" then self:updates() else self:chessMenu() end
    end
    local t4=installed(self,"t4-e-reader-os")
    if not t4 or type(t4.open)~="function" then
        self:view("Cài T4 e-reader OS",
            "Cờ vua T4 do Hoàng Tuấn (@hoangtuan2k5) phát triển.\n\n"
            .."Tải bản Online hoặc Offline từ:\ngithub.com/hoangtuan2k5/t4-e-reader-os-releases/releases/latest\n\n"
            .."Chép t4-e-reader-os.koplugin vào cùng thư mục plugins với Góc Mực. Khởi động lại KOReader và vào lại mục này. "
            .."T4 có Stockfish, kho bài thế, phân tích ván và sảnh cờ trực tuyến.",
            back)
        return
    end
    self:close()
    UI:nextTick(function()
        local ok,err=pcall(t4.open,t4,tab)
        if not ok then
            log.warn("Goc Muc: T4 chess:",err)
            back()
            self:notice("T4 chưa mở được. Xem crash.log hoặc thử mở T4 từ menu KOReader.")
        end
    end)
end

function App:openInkKnight()
    local ink=installed(self,"ink_knight")
    local menu={}
    if ink and type(ink.addToMainMenu)=="function" then ink:addToMainMenu(menu) end
    if menu.ink_knight and menu.ink_knight.callback then
        self:close()
        UI:nextTick(menu.ink_knight.callback)
    else
        self:view("Chơi qua Lichess",
            "Cài Ink Knight của Beater Studios cạnh Góc Mực rồi khởi động lại KOReader. Trong Ink Knight, dùng mục Lichess để kết nối tài khoản. "
            .."Bản T4 có sảnh trực tuyến riêng.\n\ngithub.com/beater-studios/ink_knight.koplugin/releases/latest",
            function() self:chessMenu() end)
    end
end

local pieces={K="♔",Q="♕",R="♖",B="♗",N="♘",P="♙",k="♚",q="♛",r="♜",b="♝",n="♞",p="♟"}

function App:kidsChessMenu()
    self:menu("Cờ vua cho bé",{
        {"Đánh với máy",function() self:kidsLevels() end},
        {"Hai người trên Kindle",function() self:kidsChess({pos=Chess.fromFen(),history={}}) end},
        {"Bài luyện tấn công và phòng thủ",function()
            self:menu("Chọn bài luyện",{
                {"Chiếu hết với Hậu",function()
                    self:kidsChess({pos=Chess.fromFen("7k/8/5KQ1/8/8/8/8/8 w - - 0 1"),history={},
                        answer="g6g7", label="Tấn công · Chiếu hết trong một nước"})
                end},
                {"Giải chiếu bằng cách bắt Xe",function()
                    self:kidsChess({pos=Chess.fromFen("k7/8/8/8/8/4r3/3Q4/4K3 w - - 0 1"),history={},
                        answer="d2e3",label="Phòng thủ · Bắt quân đang chiếu"})
                end},
            },function() self:kidsChessMenu() end)
        end},
    },function() self:chessMenu() end,{icon="knight"})
end

function App:kidsLevels()
    local rows={}
    for level,label in ipairs({"Tập chơi","Rất dễ","Dễ","Vừa","Khó","Thử thách"}) do
        rows[#rows+1]={level.." · "..label,function()
            self:kidsChess({pos=Chess.fromFen(),history={},level=level})
        end}
    end
    self:menu("Chọn độ khó",rows,function() self:kidsChessMenu() end,{icon="knight"})
end

function App:kidsChess(game)
    local legal=Chess.legal(game.pos)
    local result=game.solved and "Đã giải bài" or Chess.result(game.pos,legal,game.history)
    local function play(m)
        if game.answer and Chess.uci(m)~=game.answer then
            self:notice("Thử một nước khác.")
            return
        end
        game.solved=game.answer~=nil
        game.history[#game.history+1]=game.pos
        game.pos=Chess.apply(game.pos,m)
        game.selected=nil
        local replies=Chess.legal(game.pos)
        if game.level and not Chess.result(game.pos,replies,game.history) then
            local reply=Chess.bot(game.pos,game.level,replies)
            if reply then
                game.history[#game.history+1]=game.pos
                game.pos=Chess.apply(game.pos,reply)
            end
        end
        self:kidsChess(game)
    end
    local destinations={}
    for _,m in ipairs(legal) do
        if m.from==game.selected then
            destinations[m.to]=destinations[m.to] or {}
            table.insert(destinations[m.to],m)
        end
    end
    local board=game.pos.board
    local title=(game.label or (game.level and "Cờ vua cho bé · Mức "..game.level or "Cờ vua · Hai người"))
        .."\n"..(result or ((game.pos.white and "Trắng" or "Đen").." đi"
        ..(Chess.inCheck(game.pos,game.pos.white) and " · Đang bị chiếu" or "")))
    self:grid(8,title,{{
        self:button("Đi lại",function()
            if #game.history==0 then return end
            if game.level and not game.pos.white then
                game.pos=table.remove(game.history)
            else
                if game.level and #game.history>=2 then table.remove(game.history) end
                game.pos=table.remove(game.history)
            end
            game.solved,game.selected=nil,nil
            self:kidsChess(game)
        end),
        self:button("Gợi ý",function()
            if result then return end
            local hint=game.answer and Chess.find(game.pos,game.answer) or Chess.bot(game.pos,6,legal)
            if hint then game.selected=hint.from; self:kidsChess(game); self:notice(Chess.uci(hint)) end
        end),
    }},function(x,y)
        local index=(8-y)*16+x-1
        local p,targets=board[index],destinations[index]
        local mark=p and pieces[p] or (targets and "•" or "")
        local function tap()
            if result then return end
            if targets and #targets==1 then play(targets[1])
            elseif targets then
                local choices={}
                for _,m in ipairs(targets) do
                    choices[#choices+1]={pieces[m.promote],function() play(m) end}
                end
                self:menu("Phong cấp",choices,function() self:kidsChess(game) end)
            else
                game.selected=p and (p==p:upper())==game.pos.white and index or nil
                self:kidsChess(game)
            end
        end
        return mark,tap,(x+y)%2==0 or game.selected==index,true
    end,function() self:kidsChessMenu() end)
end

function App:caroMenu()
    local entries={{"Hai người trên Kindle",function()
        self:caroGame({board={},turn="X",moves={}})
    end},{"Chơi theo mã phòng",function() self:roomMenu() end}}
    for level,title in ipairs({"Tập chơi","Dễ","Vừa","Khó","Cao thủ"}) do
        entries[#entries+1]={title,function() self:caroGame({board={},turn="X",moves={},level=level}) end}
    end
    self:menu("Cờ caro",entries,function() self:home() end,{icon="caro",subtitle="Luật chặn hai đầu"})
end

local function other(mark)
    return mark=="X" and "O" or "X"
end

function App:caroGame(game)
    if game.room then
        game.board={}
        for n,index in ipairs(game.moves) do game.board[index]=n%2==1 and "X" or "O" end
        game.turn=#game.moves%2==0 and "X" or "O"
    end
    local player=game.turn
    local status=game.winner and (game.winner=="draw" and "Hòa" or game.winner.." thắng")
        or (game.room and not game.joined and "Đang chờ O vào phòng" or "Lượt "..player)
    local title=(game.room and "Phòng "..game.room.." · Bạn "..game.mark or "Cờ caro").."\n"..status
    local function move(i)
        if game.winner or game.board[i] then return end
        if game.room then
            if not game.joined or player~=game.mark then return end
            self:roomRequest("/api/rooms/"..game.room.."/move",{index=i,ply=#game.moves},game.token,function(data)
                game.moves,game.winner,game.joined=data.moves,data.winner,data.joined
                self:caroGame(game)
            end)
            return
        end
        local function apply(index)
            game.board[index]=game.turn
            game.moves[#game.moves+1]=index
            if Caro.win(game.board,index,game.turn) then game.winner=game.turn
            elseif #game.moves==Caro.size^2 then game.winner="draw" end
            game.turn=other(game.turn)
        end
        apply(i)
        if game.level and not game.winner then apply(Caro.bot(game.board,game.turn,game.level)) end
        self:caroGame(game)
    end
    local controls
    if game.room then
        controls={{self:button("Làm mới",function() self:refreshRoom(game,true) end)}}
    else
        controls={{self:button("Đi lại",function()
            for _=1,game.level and 2 or 1 do
                if #game.moves==0 then break end
                game.board[table.remove(game.moves)]=nil
                game.turn=other(game.turn)
            end
            game.winner=nil
            self:caroGame(game)
        end)}}
    end
    local window=self:grid(Caro.size,title,controls,function(x,y)
        local i=Caro.index(x,y)
        return game.board[i] or "",function() move(i) end,game.moves[#game.moves]==i
    end,function() self:caroMenu() end)
    if game.room and not game.winner then
        UI:scheduleIn(5,function()
            if self.window==window then self:refreshRoom(game,false) end
        end)
    end
end

function App:roomRequest(path, data, token, callback, quiet)
    local host=self:read("caro_host","")
    if host=="" then self:notice("Hãy nhập địa chỉ máy chủ."); return end
    local function run()
        local reply,err=Net.json(host..path,data,token)
        if reply and not reply.error then callback(reply)
        elseif not quiet then self:notice(reply and reply.error or err) end
    end
    if quiet then run() else self:online(run,true) end
end

function App:refreshRoom(game,force)
    local window=self.window
    local changed=false
    self:roomRequest("/api/rooms/"..game.room,nil,nil,function(data)
        if force or #data.moves~=#game.moves or data.winner~=game.winner or data.joined~=game.joined then
            changed=true
            game.moves,game.winner,game.joined=data.moves,data.winner,data.joined
            self:caroGame(game)
        end
    end,not force)
    if not force and not changed then
        UI:scheduleIn(5,function() if self.window==window then self:refreshRoom(game,false) end end)
    end
end

function App:roomMenu()
    local function join(data)
        self:save("caro_room",{code=data.code,token=data.token,mark=data.mark,host=self:read("caro_host")})
        self:caroGame({room=data.code,token=data.token,mark=data.mark,moves=data.moves,
            winner=data.winner,joined=data.joined})
    end
    local choices={
        {"Tạo phòng",function() self:roomRequest("/api/rooms",{},nil,join) end},
        {"Vào phòng",function()
            self:prompt("Mã phòng","Nhập 6 ký tự được chia sẻ.","",function(code)
                code=code:upper()
                if #code~=6 or not code:match("^%w+$") then self:notice("Mã phòng không hợp lệ."); return end
                self:roomRequest("/api/rooms/"..code.."/join",{},nil,join)
            end)
        end},
        {"Địa chỉ máy chủ",function()
            self:prompt("Máy chủ cờ caro","Ví dụ http://192.168.1.10:8080 (Wi-Fi gia đình).",
                self:read("caro_host",""),function(host)
                    host=host:gsub("/+$","")
                    if not (host:match("^https://[%w.-]+:?%d*$") or
                        host:match("^http://192%.168%.%d+%.%d+:?%d*$") or
                        host:match("^http://10%.%d+%.%d+%.%d+:?%d*$") or
                        host:match("^http://172%.1[6-9]%.%d+%.%d+:?%d*$") or
                        host:match("^http://172%.2%d%.%d+%.%d+:?%d*$") or
                        host:match("^http://172%.3[01]%.%d+%.%d+:?%d*$")) then
                        self:notice("Dùng HTTPS hoặc IP của mạng riêng."); return
                    end
                    self:save("caro_host",host)
                    self:notice("Đã lưu địa chỉ.")
                end)
        end},
    }
    local recent=self:read("caro_room")
    if recent and recent.host==self:read("caro_host") then
        table.insert(choices,1,{"Tiếp tục phòng "..recent.code,function()
            self:roomRequest("/api/rooms/"..recent.code,nil,nil,function(data)
                data.token,data.mark=recent.token,recent.mark
                join(data)
            end)
        end})
    end
    self:menu("Cờ caro theo mã phòng",choices,function() self:caroMenu() end,{icon="link"})
end

function App:sudokuMenu()
    local choices={}
    local saved=self:read("sudoku")
    if saved then choices[#choices+1]={"Tiếp tục",function() self:sudokuGame(saved) end} end
    for level,label in ipairs({"Dễ","Vừa","Khó"}) do
        choices[#choices+1]={"Ván mới · "..label,function()
            local game=Sudoku.new(level)
            self:save("sudoku",game)
            self:sudokuGame(game)
        end}
    end
    self:menu("Sudoku",choices,function() self:utilities() end,{icon="caro"})
end

function App:sudokuGame(game)
    local function select(i)
        if game.fixed[i] then return end
        local rows={}
        for r=0,2 do
            local row={}
            for c=1,3 do
                local n=r*3+c
                row[#row+1]=self:button(tostring(n),function()
                    if not Sudoku.allowed(game.board,i,n) then self:notice("Số bị trùng."); return end
                    game.board[i]=n
                    self:save("sudoku",game)
                    self:sudokuGame(game)
                end)
            end
            rows[#rows+1]=row
        end
        rows[#rows+1]={self:button("Xóa ô",function()
            game.board[i]=0; self:save("sudoku",game); self:sudokuGame(game)
        end)}
        self:show("Điền số",rows,function() self:sudokuGame(game) end)
    end
    local complete=true
    for i=1,81 do if game.board[i]==0 then complete=false; break end end
    self:grid(9,complete and "Sudoku · Đã giải" or "Sudoku",{{
        self:button("Chọn ván khác",function() self:sudokuMenu() end)
    }},function(x,y)
        local i=(y-1)*9+x
        return game.board[i]>0 and tostring(game.board[i]) or "",function() select(i) end,
            (math.floor((x-1)/3)+math.floor((y-1)/3))%2==0
    end,function() self:sudokuMenu() end)
end
end
