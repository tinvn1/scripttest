local Workspace = game:GetService("Workspace")
local localPlayer = game:GetService("Players").LocalPlayer

-- =========================================================================
-- 🔥 HÀM DÒ TÌM CHÍNH XÁC NÚT BẤM (PROXIMITYPROMPT) CỦA POWER PLANT
-- =========================================================================
local function getPowerBoxPrompt()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            -- Điều kiện 1: Nằm trực tiếp trong đối tượng tên "Power Box"
            if obj.Parent and obj.Parent.Name == "Power Box" then
                return obj
            -- Điều kiện 2: Kiểm tra Text hiển thị trên màn hình có chữ "Power Plant" hoặc "Repair"
            elseif string.find(string.lower(obj.ObjectText), "power plant") or string.find(string.lower(obj.ActionText), "repair") then
                return obj
            end
        end
    end
    return nil
end

print("[🛠️ STAGE 4] Chỉ thực hiện tác vụ sửa máy Power Plant...")

local repairStarted = false
local startTime = os.time()

while true do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local prompt = getPowerBoxPrompt()
        
        if prompt then
            -- Khi tìm thấy nút, giả lập nhấn giữ phím E ngay lập tức
            if not repairStarted then
                print("[🖱️] Đã tìm thấy nút tương tác! Tiến hành giữ nút sửa máy...")
                
                task.spawn(function()
                    fireproximityprompt(prompt)
                end)
                
                repairStarted = true
                startTime = os.time() -- Ghi lại thời gian bắt đầu sửa
            end
            
            -- Chờ vòng xoay REPAIR chạy hết 16 giây để hoàn thành nhiệm vụ
            if repairStarted and (os.time() - startTime) >= 16 then
                print("[🎯 STAGE 4 SUCCESS] Đã giữ nút sửa máy hoàn tất thời gian!")
                break
            end
        else
            -- Nếu đang sửa mà nút Prompt biến mất nghĩa là máy đã hoàn thành sửa xong hoàn toàn
            if repairStarted then
                print("[🎯 STAGE 4 SUCCESS] Nút tương tác biến mất. Sửa máy thành công!")
                break
            else
                print("[-] Đang chờ nhân vật đứng sát hoặc chờ nút sửa máy xuất hiện...")
            end
        end
    end
    task.wait(0.5) -- Quét an toàn chống nặng máy
end

print("[🚀] Stage 4 hoàn thành sạch sẽ. Kích hoạt chuyển giao sang Stage 5...");
_G.CurrentStage = 5
return true
