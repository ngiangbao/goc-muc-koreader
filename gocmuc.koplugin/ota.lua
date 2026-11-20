local OTA = {}
local url = "https://github.com/ngiangbao/goc-muc-koreader/releases/latest/download/gocmuc-update.json"
local project = "ngiangbao/goc-muc-koreader"

local function version(value)
    if type(value) ~= "string" then return end
    local major,minor,patch=value:match("^(%d+)%.(%d+)%.(%d+)$")
    if major and #major<=4 and #minor<=4 and #patch<=4 then
        return tonumber(major)*100000000+tonumber(minor)*10000+tonumber(patch)
    end
end

local function verify(key,payload,signature)
    local ffi=require("ffi")
    ffi.cdef[[
        void *BIO_new_mem_buf(const void *buf, int len);
        int BIO_free(void *bio);
        void *PEM_read_bio_PUBKEY(void *bio, void *key, void *cb, void *arg);
        void EVP_PKEY_free(void *key);
        int EVP_DigestVerifyInit(void *ctx, void *pctx, const void *md, void *impl, void *key);
        void *EVP_MD_CTX_new(void);
        void EVP_MD_CTX_free(void *ctx);
        const void *EVP_sha256(void);
        int EVP_DigestUpdate(void *ctx, const void *data, size_t len);
        int EVP_DigestVerifyFinal(void *ctx, const unsigned char *sig, size_t len);
    ]]
    local crypto=ffi.loadlib("crypto","57")
    local bio=crypto.BIO_new_mem_buf(key,#key)
    if bio==nil then return false end
    local pub=crypto.PEM_read_bio_PUBKEY(bio,nil,nil,nil)
    crypto.BIO_free(bio)
    if pub==nil then return false end
    local context=crypto.EVP_MD_CTX_new()
    local matches=false
    if context~=nil then
        matches=crypto.EVP_DigestVerifyInit(context,nil,crypto.EVP_sha256(),nil,pub)==1
            and crypto.EVP_DigestUpdate(context,payload,#payload)==1
            and crypto.EVP_DigestVerifyFinal(context,signature,#signature)==1
        crypto.EVP_MD_CTX_free(context)
    end
    crypto.EVP_PKEY_free(pub)
    return matches
end

local function decode(raw)
    local ok,result=pcall(require("json").decode,raw)
    if ok and type(result)=="table" then return result end
end

function OTA.check(root,installed)
    local response,err=dofile(root.."/net.lua").request(url)
    if not response then return nil,err end
    local envelope=decode(response)
    if not envelope or type(envelope.payload)~="string" or type(envelope.signature)~="string"
        or #envelope.signature~=768 or envelope.signature:find("[^a-f0-9]") then
        return nil,"Gói cập nhật không đúng định dạng."
    end
    local signature=envelope.signature:gsub("..",function(hex) return string.char(tonumber(hex,16)) end)
    local key=dofile(root.."/ota_key.lua")
    local verified,matches=pcall(verify,key,envelope.payload,signature)
    if not verified then return nil,"KOReader không mở được thư viện xác minh chữ ký. Bạn có thể cập nhật qua USB." end
    if not matches then return nil,"Chữ ký gói cập nhật không hợp lệ." end

    local update=decode(envelope.payload)
    local latest=update and version(update.version)
    if not latest or update.project~=project or update.schema~=1 or type(update.files)~="table" then
        return nil,"Gói không dành cho Góc Mực."
    end
    if latest<=(version(installed) or 0) then return false end
    local count=0
    local compiler=loadstring or load
    for name,contents in pairs(update.files) do
        count=count+1
        if count>64 or type(name)~="string" or #name>60 or not name:match("^[%w_-]+%.lua$")
            or type(contents)~="string" or #contents>384*1024 or contents:byte(1)==27
            or not compiler(contents,"@"..name) then
            return nil,"Gói cập nhật chứa file Lua không hợp lệ."
        end
    end
    local meta=update.files["_meta.lua"]
    if not (update.files["main.lua"] and update.files["ota.lua"] and update.files["ota_key.lua"]
        and meta and meta:match('version%s*=%s*"([%d.]+)"')==update.version) then
        return nil,"Gói cập nhật thiếu file hoặc thông tin phiên bản."
    end
    return update
end

function OTA.install(root,installed,update)
    local lfs=require("libs/libkoreader-lfs")
    if not root:match("/gocmuc%.koplugin$") then
        return nil,"Thư mục plugin đã đổi tên. Hãy chép bản mới bằng USB."
    end
    local base=root:gsub("/gocmuc%.koplugin$","")
    local stamp=string.format("%d-%06d",os.time(),math.random(0,999999))
    local stage=base.."/.gocmuc-stage-"..stamp
    local backup=base.."/gocmuc-backup-"..installed.."-"..stamp
    if not lfs.mkdir(stage) then return nil,"Không tạo được thư mục cài đặt tạm." end

    local written={}
    local function discard()
        for _,path in ipairs(written) do os.remove(path) end
        lfs.rmdir(stage)
    end
    for name,contents in pairs(update.files) do
        local path=stage.."/"..name
        local file=io.open(path,"wb")
        if not file then discard(); return nil,"Không ghi được file cập nhật." end
        written[#written+1]=path
        local ok=file:write(contents)
        local closed=file:close()
        if not ok or not closed then discard(); return nil,"Không ghi đầy đủ được gói cập nhật." end
    end
    if lfs.attributes(backup) or not os.rename(root,backup) then
        discard()
        return nil,"Không tạo được bản sao của plugin hiện tại."
    end
    if not os.rename(stage,root) then
        local restored=os.rename(backup,root)
        discard()
        if not restored then
            return nil,"Hãy khôi phục qua USB. Đổi tên gocmuc-backup-"..installed.."-"..stamp.." thành gocmuc.koplugin."
        end
        return nil,"Chưa cài được bản mới. Đã khôi phục phiên bản hiện tại."
    end
    return true
end

return OTA