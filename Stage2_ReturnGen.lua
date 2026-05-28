-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Đang tìm kiếm và tiến về phía máy phát điện...");

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    
    if genPart then
        -- 1. Di chuyển tới máy phát điện
        local distance = (root.Position - genPart.Position).Magnitude
        if distance > 4 then
            print("[STAGE 2] Đang di chuyển tới máy phát điện...")
            tweenToGenerator(root, genPart)
            -- Đợi một chút sau khi tween để đảm bảo nhân vật đã dừng hẳn
            task.wait(0.5) 
        end
        
        -- 2. Đã đến nơi thành công -> GỌI FILE checkfuel.lua
        print("[🎯 STAGE 2 SUCCESS] Đã đến vị trí máy phát điện. Chuyển sang checkfuel.lua!")
        
        -- Đảm bảo không có lỗi xảy ra khi load file
        local success, result = pcall(function()
            if isfile("checkfuel.lua") then
                return loadfile("checkfuel.lua")()
            else
                error("Không tìm thấy file 'checkfuel.lua'")
            end
        end)

        if not success then
            warn("[⚠️ ERROR] Có lỗi khi thực thi checkfuel.lua: " .. tostring(result))
            return false
        end
        
        return true
    else
        warn("[⚠️ STAGE 2 ERROR] Không tìm thấy máy phát điện trên Map! Quay lại Stage 1...")
        _G.CurrentStage = 1
        return false
    end
else
    warn("[⚠️ STAGE 2 ERROR] Không tìm thấy HumanoidRootPart!")
    return false
end
