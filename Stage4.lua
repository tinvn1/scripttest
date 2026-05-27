local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer

-- =========================================================================
-- 🔥 HÀM DÒ TÌM CHÍNH XÁC NÚT BẤM (PROXIMITYPROMPT) CỦA POWER PLANT
-- =========================================================================
local function getPowerBoxPrompt()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if obj.Parent and obj.Parent.Name == "Power Box" then
                return obj
            elseif string.find(string.lower(obj.ObjectText or ""), "power plant") or string.find(string.lower(obj.ActionText or ""), "repair") then
                return obj
            end
        end
    end
    return nil
end

print("[🛠️ STAGE 4] Kích hoạt tự động sửa máy khi lại gần (An Toàn)...")

local repairStarted = false
local startTime = 0
local stage4Connection

stage4Connection = RunService.Heartbeat:Connect(function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local prompt = getPowerBoxPrompt()
        
        if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
            -- Tính khoảng cách giữa nhân vật và hộp điện
            local distance = (root.Position - prompt.Parent.Position).Magnitude
            
            -- Chỉ kích hoạt khi khoảng cách lại gần (dưới 15 studs hoặc tùy bạn chỉnh)
            if distance <= 15 then
                
                -- Cấu hình bypass các giới hạn cơ bản của game một lần duy nhất
                if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end
                
                if not repairStarted then
                    print("[🖱️] Đã đến gần Power Box! Tự động kích hoạt sửa máy...")
                    repairStarted = true
                    startTime = os.clock()
                    
                    -- Kích hoạt giữ nút một cách tự nhiên theo cơ chế của Roblox Engine
                    -- Không dùng vòng lặp spam tránh kích hoạt nhầm bảng mua Robux
                    task.spawn(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                        end
                    end)
                end
                
                -- KIỂM TRA THỜI GIAN HOÀN THÀNH (16 giây)
                if repairStarted and (os.clock() - startTime) >= 16 then
                    print("[🎯 STAGE 4 SUCCESS] Đã sửa máy đủ thời gian quy định!")
                    stage4Connection:Disconnect()
                end
            else
                -- Nếu người chơi chạy ra quá xa khi chưa sửa xong thì reset trạng thái để sẵn sàng cho lần lại gần tiếp theo
                if repairStarted then
                    print("[⚠️] Quá xa mục tiêu, tạm dừng tiến trình sửa.")
                    repairStarted = false
                    pcall(function() prompt:InputHoldEnd() end)
                end
            end
        else
            -- Nếu nút biến mất (đã sửa xong hoặc biến mất khỏi map)
            if repairStarted then
                print("[🎯 STAGE 4 SUCCESS] Nút đã biến mất. Sửa máy thành công!")
                stage4Connection:Disconnect()
            end
        end
    end
end)

-- Treo luồng script Stage 4 tạm thời cho đến khi Connection phía trên tự hủy hoàn toàn
while stage4Connection and stage4Connection.Connected do task.wait() end

-- DỌN DẸP SẠCH SẼ BỘ NHỚ LẬP TỨC
repairStarted = false
local finalPrompt = getPowerBoxPrompt()
if finalPrompt then pcall(function() finalPrompt:InputHoldEnd() end) end

-- CHUYỂN GIAO THẦN TỐC SANG STAGE 5
print("[🚀] Stage 4 hoàn thành sạch sẽ. Kích hoạt chuyển giao sang Stage 5...");
_G.CurrentStage = 5
return true
