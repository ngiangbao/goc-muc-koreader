local root=arg[1] or "gocmuc.koplugin"
local OTA=dofile(root.."/ota.lua")

local function setup(fail_swap)
    local original="plugins/gocmuc.koplugin"
    local dirs={[original]={old="original"}}
    local writes={}
    package.loaded["libs/libkoreader-lfs"]={
        mkdir=function(path) dirs[path]={}; return true end,
        rmdir=function(path) dirs[path]=nil; return true end,
        attributes=function(path) return dirs[path] end,
    }
    io.open=function(path)
        local dir,name=path:match("^(.*)/([^/]+)$")
        local folder=assert(dirs[dir])
        return {write=function(_,data) folder[name]=data; writes[name]=data; return true end,close=function() return true end}
    end
    os.remove=function(path)
        local dir,name=path:match("^(.*)/([^/]+)$")
        if dirs[dir] then dirs[dir][name]=nil end
    end
    os.rename=function(from,to)
        if not dirs[from] or dirs[to] or (fail_swap and from:find(".gocmuc-stage-",1,true)) then return nil end
        dirs[to],dirs[from]=dirs[from],nil
        return true
    end
    return original,dirs,writes
end

local update={version="0.2.1",files={["main.lua"]="return {}",["_meta.lua"]='return {version="0.2.1"}'}}
local path,dirs,writes=setup(false)
assert(OTA.install(path,"0.2.0",update))
assert(writes["main.lua"]==update.files["main.lua"] and dirs[path]["main.lua"]==writes["main.lua"])
local copies=0
for dir,contents in pairs(dirs) do
    if dir:find("gocmuc-backup-0.2.0-",1,true) then
        assert(contents.old=="original")
        copies=copies+1
    end
end
assert(copies==1)

path,dirs=setup(true)
assert(not OTA.install(path,"0.2.0",update))
assert(dirs[path].old=="original")
for dir in pairs(dirs) do assert(dir==path) end

print("OTA install retains a backup on success and restores on a failed swap.")