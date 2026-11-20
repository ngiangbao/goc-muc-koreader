local Net = {}
local http = require("socket.http")
local ltn12 = require("ltn12")
local socketutil = require("socketutil")
local json = require("json")

function Net.escape(s)
    return (s:gsub("[^%w%-._~]",function(c) return string.format("%%%02X",c:byte()) end))
end

function Net.request(url, values, token)
    local chunks, length = {}, 0
    local options = {url=url, redirect=not token, headers={["user-agent"]="GocMuc/0.1 KOReader"}}
    if token then options.headers.authorization="Bearer "..token end
    if values then
        local body=json.encode(values)
        options.method="POST"
        options.headers["content-type"]="application/json"
        options.headers["content-length"]=#body
        options.source=ltn12.source.string(body)
    end
    options.sink=function(chunk)
        if chunk then
            length=length+#chunk
            if length>2*1024*1024 then return nil,"Dữ liệu quá lớn" end
            chunks[#chunks+1]=chunk
        end
        return 1
    end
    local old_block,old_total=socketutil.block_timeout,socketutil.total_timeout
    socketutil:set_timeout(4,9)
    local ok,success,code=pcall(http.request,options)
    socketutil:set_timeout(old_block,old_total)
    if not ok or not success then
        return nil,"Không kết nối được với máy chủ."
    end
    if tonumber(code)~=200 then
        if values then
            local decoded,data=pcall(json.decode,table.concat(chunks))
            if decoded and type(data)=="table" and type(data.error)=="string" then
                return nil,data.error
            end
        end
        return nil,"Không tải được dữ liệu ("..tostring(code or success)..")."
    end
    return table.concat(chunks)
end

function Net.json(url, values, token)
    local body,err=Net.request(url,values,token)
    if not body then return nil,err end
    local ok,data=pcall(json.decode,body)
    if ok and type(data)=="table" then return data end
    return nil,"Máy chủ trả dữ liệu không hợp lệ."
end

local names={amp="&",lt="<",gt=">",quot='"',apos="'",nbsp=" ",ldquo="“",rdquo="”",ndash="–",mdash="—",hellip="…"}
local function codepoint(n)
    if not n or n<32 or n>0x10ffff or (n>=0xd800 and n<=0xdfff) then return " " end
    if n<128 then return string.char(n) end
    if n<2048 then return string.char(192+math.floor(n/64),128+n%64) end
    if n<65536 then return string.char(224+math.floor(n/4096),128+math.floor(n/64)%64,128+n%64) end
    return string.char(240+math.floor(n/262144),128+math.floor(n/4096)%64,128+math.floor(n/64)%64,128+n%64)
end

local function entities(s)
    return (s:gsub("&(#?[%w]+);",function(e)
        if e:sub(1,2)=="#x" then return codepoint(tonumber(e:sub(3),16)) end
        if e:sub(1,1)=="#" then return codepoint(tonumber(e:sub(2))) end
        return names[e] or "&"..e..";"
    end))
end

function Net.clean(s)
    s=s:gsub("<!%[CDATA%[(.-)%]%]>","%1")
    s=entities(s)
    s=s:gsub("<[sS][cC][rR][iI][pP][tT][^>]*>.-</[sS][cC][rR][iI][pP][tT]>","")
    s=s:gsub("<style[^>]*>.-</style>",""):gsub("</p>","\n\n"):gsub("<br[^>]*>","\n")
    return (entities(s:gsub("<[^>]+>","")):gsub("[ \t\r]+"," "):gsub("\n\n\n+","\n\n"):match("^%s*(.-)%s*$"))
end

local function tag(s,name)
    return s:match("<"..name..">(.-)</"..name..">") or s:match("<"..name.."%s[^>]*>(.-)</"..name..">")
end

function Net.rss(raw)
    local entries={}
    for stanza in raw:gmatch("<item[^>]*>(.-)</item>") do
        local title=Net.clean(tag(stanza,"title") or "")
        local link=entities((tag(stanza,"link") or ""):gsub("<!%[CDATA%[(.-)%]%]>","%1")):match("^%s*(.-)%s*$")
        if title~="" then
            entries[#entries+1]={title=title,url=link,date=Net.clean(tag(stanza,"pubDate") or ""),
                text=Net.clean(tag(stanza,"content:encoded") or tag(stanza,"description") or "")}
        end
        if #entries>=18 then break end
    end
    return entries
end

function Net.article(raw)
    local article=raw:match("<article[^>]*>(.-)</article>") or raw:match("<main[^>]*>(.-)</main>")
    if not article then return nil end
    local paras={}
    for attributes,para in article:gmatch("<p([^>]*)>(.-)</p>") do
        if attributes=="" or attributes:match("^%s") then
            local s=Net.clean(para)
            if #s>=25 then paras[#paras+1]=s end
            if #paras>=65 then break end
        end
    end
    if #paras>0 then return table.concat(paras,"\n\n") end
end

return Net
