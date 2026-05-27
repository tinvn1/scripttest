-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1
-- =========================================================================
print("[STAGE 1] Bắt đầu quét tìm nhặt 2 bình Fuel (Dò đường kỹ lưỡng)...")
local cycle = 1
local stuckCounter = 0

while cycle <= 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelObject = targetFuel.Parent:IsA("Model") and targetFuel.Parent or targetFuel
        local success = walkPathToTarget(root, targetFuel)
        
        if success then
            print(string.format("[🎉] Đã tiếp cận Fuel %d/2 thành công!", cycle))
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            
            ignoredFuels[fuelObject] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.4)
        else
            stuckCounter = stuckCounter + 1
            if stuckCounter >= 3 then
                print("[⚠️] Kẹt góc, bỏ qua tìm bình khác!")
                ignoredFuels[fuelObject] = true
                stuckCounter = 0
            end
            task.wait(0.1)
        end
    else
        print("[-] Đang quét tìm kiếm lại tài nguyên Fuel...")
        ignoredFuels = {}
        task.wait(0.5)
    end
end

print("[STAGE 1] HOÀN THÀNH XUẤT SẮC!")
task.wait(0.1)
_G.StageCompleted = true 
return true
