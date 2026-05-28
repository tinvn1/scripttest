-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Đang tìm kiếm và tiến về phía máy phát điện...");

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    
    if genPart then
        -- 1. Tính khoảng cách và di chuyển đến máy phát điện
        local distance = (root.Position - genPart.Position).Magnitude
        if distance > 4 then
            print("[STAGE 2] Đang di chuyển tới máy phát điện...")
            tweenToGenerator(root, genPart)
        end
        
        -- 2. Đã đến nơi thành công -> GỌI FILE checkfuel.lua
        print("[🎯 STAGE 2 SUCCESS] Đã đến vị trí máy phát điện. Đang chuyển hướng sang checkfuel.lua!")
        task.wait(0.3) 
        
        -- Gọi file checkfuel.lua
        -- Lưu ý: Đảm bảo tên file chính xác với file trong hệ thống của bạn
        if isfile("checkfuel.lua") then
            loadfile("checkfuel.lua")()
        else
            warn("[⚠️ ERROR] Không tìm thấy file 'checkfuel.lua' để thực thi!")
        end
        
        return true
    else
        -- Trường hợp KHÔNG tìm thấy máy phát điện trên map
        warn("[⚠️ STAGE 2 ERROR] Không tìm thấy máy phát điện trên Map! Quay lại Stage 1...")
        _G.CurrentStage = 1
        return false
    end
else
    warn("[⚠️ STAGE 2 ERROR] Không tìm thấy HumanoidRootPart của nhân vật!")
    return false
end
