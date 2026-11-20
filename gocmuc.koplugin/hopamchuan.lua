local HAC={}
local hosts={["hopamchuan.com"]=true,["www.hopamchuan.com"]=true}

function HAC.url(input)
    local host,path=input:match("^https?://([%w.-]+)(/[^?#]+)")
    if not host or not hosts[host:lower()] or #path>220 or path:find("[^%w_./%%-]") then return end
    local encoded=path:lower()
    if encoded:find("%%2[ef]") or encoded:find("%%5c") or encoded:find("%%25") then return end
    local id,tail=path:match("^/song/(%d+)/(.*)$")
    if not id or #id>10 or tail=="" or tail:find("..",1,true) or tail:find("//",1,true) then return end
    return "https://hopamchuan.com"..path
end

function HAC.parse(html,clean)
    local title=html:match('<h1%s+id="song%-title"[^>]*>%s*<span[^>]*>(.-)</span>')
    if not title then return nil,"Trang này chưa có tiêu đề hợp âm." end
    title=clean(title)
    local lines={}
    for line in html:gmatch('<div class="chord_lyric_line[^"]*"[^>]*>(.-)</div>') do
        local chords={}
        for symbol in line:gmatch('<span class="hopamchuan_chord"[^>]*>(.-)</span>') do
            symbol=clean(symbol):gsub("♯","#"):gsub("♭","b")
            if #symbol<=32 and symbol:match("^[A-G][%w#b/()+%-]*$") then
                chords[#chords+1]="["..symbol.."]"
            end
        end
        if #chords>0 then lines[#lines+1]=table.concat(chords,"  ") end
        if #lines>=240 then break end
    end
    if title=="" or #lines==0 then return nil,"Không thấy ký hiệu hợp âm trong phiên bản này." end
    return {title=title,body=table.concat(lines,"\n")}
end

function HAC.searchResults(response,clean)
    local results,seen={},{}
    if type(response)~="table" or response.success~=true or type(response.data)~="table" then return results end
    for _,song in ipairs(response.data) do
        if type(song)=="table" and type(song._url)=="string" and type(song._title)=="string" then
            local url=HAC.url(song._url:sub(1,1)=="/" and "https://hopamchuan.com"..song._url or song._url)
            local title=clean(song._title)
            if url and title~="" and not seen[url] then
                seen[url]=true
                results[#results+1]={title=title,url=url,artist=type(song._singers)=="string" and clean(song._singers) or ""}
            end
        end
        if #results>=20 then break end
    end
    return results
end

return HAC
