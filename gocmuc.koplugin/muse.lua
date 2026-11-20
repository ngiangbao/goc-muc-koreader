return function(App,env)
local Net=dofile(env.root.."/net.lua")
local UI=env.UI
local HEALTH_PROMPT="Tổng hợp thông tin Apple Health mới nhất của tôi: giấc ngủ, nhịp tim nghỉ, "
    .."số bước chân, SpO2, và lưu ý bất thường nếu có. Trả lời ngắn gọn bằng tiếng Việt."
local function bridgeURL(input)
    local a,b,c,d,port=input:match("^http://(%d+)%.(%d+)%.(%d+)%.(%d+):(%d+)/?$")
    if a~="100" or #b>3 or #c>3 or #d>3 or #port>5 then return end
    b,c,d,port=tonumber(b),tonumber(c),tonumber(d),tonumber(port)
    if b<64 or b>127 or c>255 or d>255 or port<1 or port>65535 then return end
    return string.format("http://100.%d.%d.%d:%d",b,c,d,port)
end

function App:museMenu()
    local url=self:read("muse_bridge")
    local entries={
        {"Soạn tin nhắn",function() self:museCompose() end,"muse"},
        {"Kiểm tra kết nối",function() self:musePing() end,"link"},
        {"Thiết lập cầu nối",function() self:museSetup() end,"tools"},
        {"Sức khỏe",function() self:museHealth() end,"health"},
    }
    if self.muse_job then
        table.insert(entries,2,{"Xem tin nhắn gần nhất",function() self:museReply(self.muse_job) end,"book"})
    end
    self:menu("Muse",entries,function() self:home() end,
        {icon="muse",subtitle=url or "Cầu nối Muse Gadget SDK qua Tailscale"})
end

function App:museSetup()
    self:prompt("Địa chỉ cầu nối Muse","Nhập IPv4 Tailscale và cổng, ví dụ http://100.80.10.20:8091.",
        self:read("muse_bridge") or "",function(address)
            local url=bridgeURL(address)
            if not url then self:notice("Cần địa chỉ IPv4 của máy cầu nối trong tailnet."); return end
            self:prompt("Khóa cầu nối","Nhập 64 ký tự hex của cầu nối Góc Mực.", "",function(key)
                if #key~=64 or key:find("[^a-f0-9]") then self:notice("Khóa cầu nối không hợp lệ."); return end
                self:save("muse_bridge",url)
                self:save("muse_bridge_key",key)
                self.muse_job=nil
                self:museMenu()
            end,{action="Lưu"})
        end)
end

function App:museRequest(path,body,completion,quiet)
    local host,tok=self:read("muse_bridge"),self:read("muse_bridge_key")
    if not host or not bridgeURL(host) or type(tok)~="string" or #tok~=64 or tok:find("[^a-f0-9]") then
        if not quiet then self:notice("Mở Thiết lập cầu nối để nhập địa chỉ và khóa.") end
        return
    end
    local function run()
        local payload,err=Net.json(host.."/api/muse/"..path,body,tok)
        if payload then completion(payload)
        elseif not quiet then self:notice(err) end
    end
    if quiet then run() else self:online(run,true) end
end

function App:musePing()
    self:museRequest("status",nil,function(data)
        if data.service=="goc-muc-muse" then self:notice("Kindle đã kết nối với cầu nối qua Tailscale.")
        else self:notice("Máy chủ phản hồi nhưng chưa nhận ra dịch vụ Muse.") end
    end)
end

function App:museCompose()
    if not self:read("muse_bridge") then self:museSetup(); return end
    self:prompt("Nhắn Muse","Tin nhắn sẽ được gửi vào chat phụ Muse của cầu nối.", "",function(prompt)
        if #prompt==0 or #prompt>4000 then self:notice("Nhập tin nhắn dài tối đa 4.000 byte."); return end
        self:museStartJob(prompt)
    end,{multiline=true,action="Gửi"})
end

-- Gửi một câu hỏi qua đúng luồng cầu nối của ô Muse: tạo job rồi xem trả lời.
function App:museStartJob(prompt)
    self:museRequest("jobs",{message=prompt},function(data)
        if type(data.id)~="string" or #data.id~=36 or data.id:find("[^a-f0-9-]") then
            self:notice("Cầu nối trả mã tin nhắn không hợp lệ.")
            return
        end
        self.muse_job={id=data.id,prompt=prompt,started=os.time()}
        self:museReply(self.muse_job)
    end)
end

-- Ô Sức khỏe: hỏi Muse tổng hợp Apple Health rồi hiển thị như ô Muse.
function App:museHealth()
    if not self:read("muse_bridge") then self:museSetup(); return end
    self:museStartJob(HEALTH_PROMPT)
end

function App:museReply(job,result)
    if result then job.result=result end
    result=job.result
    local body="Bạn\n"..job.prompt.."\n\n"
    if not result or result.state=="waiting" then
        body=body.."Muse đang xử lý."
    else
        body=body.."Muse\n"..(result.answer or "")
        if result.message then body=body.."\n\n"..result.message end
    end
    local function refresh(quiet)
        self:museRequest("jobs/"..job.id,nil,function(data)
            if not job.result or data.state~=job.result.state then self:museReply(job,data) end
        end,quiet)
    end
    local buttons={self:button("Làm mới",function() refresh(false) end),
        self:button("Soạn tin",function() self:museCompose() end)}
    self:view("Muse",body,function() self:museMenu() end,{rows={buttons}})
    local window=self.window
    local function poll()
        if self.window~=window then return end
        refresh(true)
        if self.window==window and os.time()-job.started<150 then UI:scheduleIn(6,poll) end
    end
    if not result or result.state=="waiting" then UI:scheduleIn(2,poll) end
end
end
