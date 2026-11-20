return function(App,env)
local UI=env.UI
local ConfirmBox=require("ui/widget/confirmbox")
local OTA=dofile(env.root.."/ota.lua")

function App:updates()
    self:menu("Cập nhật qua Wi-Fi",{
        {"Kiểm tra Góc Mực · "..env.version,function() self:checkGocMucUpdate() end,"update"},
        {"Cập nhật T4 · Hoàng Tuấn",function() self:openT4("settings") end,"knight"},
        {"Cập nhật Ink Knight",function()
            self:view("Ink Knight · Beater Studios",
                "Tải bản mới từ GitHub của tác giả. Thoát KOReader rồi cập nhật thư mục ink_knight.koplugin qua USB.\n\n"
                .."github.com/beater-studios/ink_knight.koplugin/releases/latest",
                function() self:updates() end)
        end,"link"},
    },function() self:home() end,{icon="update",style="tiles"})
end

function App:checkGocMucUpdate()
    self:online(function()
        local update,err=OTA.check(env.root,env.version)
        if update==false then self:notice("Góc Mực đang ở bản mới nhất."); return end
        if not update then self:notice(err); return end
        UI:show(ConfirmBox:new{
            text="Tìm thấy Góc Mực "..update.version..". Cài đặt và khởi động lại KOReader?",
            ok_text="Cài và khởi động lại",cancel_text="Để sau",
            ok_callback=function()
                local done,message=OTA.install(env.root,env.version,update)
                if not done then self:notice(message); return end
                self:close()
                UI:nextTick(function() UI:restartKOReader() end)
            end,
        })
    end)
end
end
