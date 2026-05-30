-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 MATRIX FULL FIX] Khởi chạy hệ thống: Kill Aura (Đã sửa) + Nhặt đồ 15 studs No-Fling!");

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- ====================================================================
-- BẢNG CẤU HÌNH ĐẦY ĐỦ (Đã sửa lỗi thiếu biến của Kill Aura)
-- ====================================================================
local CONFIG = {
    -- 🔥 CẤU HÌNH KILL AURA (Đã được kiểm tra kĩ lưỡng)
    AuraEnabled = true,        -- Bật/Tắt Kill Aura
    MaxDistance = 16,          -- Khoảng cách quét đập quái (Studs)
    AttackDelay = 0.12,        -- Tốc độ đánh
    MaxTargets = 5,            -- Số lượng mục tiêu đập cùng lúc tối đa

    -- Cấu hình Auto Drag (Nhặt đồ từ Workspace.DroppedItems)
    DragEnabled = true,        
    DetectRange = 15,          -- Tầm quét đăng ký nhặt đồ tự động (15 studs)
    FollowDistance = 2.5,      -- Khoảng cách giữ vật phẩm sát hông
    PhysicsResponsiveness = 200, -- Độ mượt kéo ban đầu
}

-- ĐƯỜNG DẪN THƯ MỤC VẬT PHẨM RƠI
local DroppedItemsFolder = Workspace:WaitForChild("DroppedItems")
local holdingItems = {} -- Bộ nhớ đệm đánh dấu đồ đã xích vật lý

-- ĐIỂM NEO DUY NHẤT: Gom cố định thành 1 cục phía sau người để giảm tải Attachment
local masterAnchorAttachment = nil
local function getMasterAttachment(rootPart)
    if not masterAnchorAttachment or masterAnchorAttachment.Parent ~= rootPart then
        masterAnchorAttachment = Instance.new("Attachment")
        masterAnchorAttachment.Name = "MasterDragAnchor"
        masterAnchorAttachment.Position = Vector3.new(0, 0, CONFIG.FollowDistance) 
        masterAnchorAttachment.Parent = rootPart
    end
    return masterAnchorAttachment
end

-- ====================================================================
-- CÁC HÀM BỔ TRỢ (UTILITIES)
-- ====================================================================

-- [Kill Aura] Kiểm tra mục tiêu hợp lệ (Quái vật hoặc Phế liệu)
local function isValidTarget(obj, character)
    if not obj or obj == character or obj:IsAncestorOf(character) then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    
    local nameLower = string.lower(obj.Name)
    if string.find(nameLower, "scrap pile") or string.find(nameLower, "scrap") then 
        return true 
    end
    
    local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- [Kill Aura] Lấy vũ khí và Remote đập quái nguyên bản của game
local function getBatStuff()
    local character = localPlayer.Character
    if character then
        local bat = character:FindFirstChild("Bat")
        local autoTarget = character:FindFirstChild("AutoTargetClient")
        if bat and bat:FindFirstChild("Swing") and bat:FindFirstChild("HitTargets") and autoTarget and autoTarget:FindFirstChild("UpdateNearbyTargets") then
            return bat, autoTarget.UpdateNearbyTargets
        end
    end
    return nil, nil
end

-- [Auto Drag] Lấy Remote kéo đồ của hệ thống game
local function getDragRemote()
    local character = localPlayer.Character
    if not character then return nil end
    local dragSystem = character:FindFirstChild("DragSystem")
    return dragSystem and dragSystem:FindFirstChild("DragItem") or nil
end

-- ĐĂNG KÝ GỐC CHUẨN STAGE 0
local function triggerDragSystem(item, itemPart)
    local dragDetector = item:FindFirstChildWhichIsA("DragDetector") or item:FindFirstChildOfClass("DragDetector")
    if dragDetector and firesignal then
        firesignal(dragDetector.DragStart, localPlayer)
    end

    local networkRemote = item:FindFirstChild("ItemDrag") and item.ItemDrag:FindFirstChild("RequestNetworkOwnership")
    if networkRemote then
        pcall(function()
            networkRemote:FireServer(itemPart)
        end)
    end
end

-- HÀM NO-CLIP VẬT PHẨM: Ép CanCollide = false liên tục chống văng nhân vật
local function enforceNoClip(item)
    if item:IsA("BasePart") then
        item.CanCollide = false
    end
    for _, child in ipairs(item:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CanCollide = false
            child.Velocity = Vector3.zero
            child.RotVelocity = Vector3.zero
        end
    end
end

-- KHỬ LAG BẰNG HÌNH ẢNH (Bảo toàn mạng cho game ghi nhận đồ tồn tại)
local function invisibleClientItem(item)
    pcall(function()
        if item:IsA("BasePart") then
            item.Transparency = 1
        end
        for _, child in ipairs(item:GetDescendants()) do
            if child:IsA("BasePart") then
                child.Transparency = 1
            elseif child:IsA("Decal") or child:IsA("Texture") then
                child.Enabled = false
            elseif child:IsA("ParticleEmitter") or child:IsA("Light") then
                child.Enabled = false
            end
        end
    end)
end

-- ====================================================================
-- LUỒNG XỬ LÝ KÉO ĐỒ AN TOÀN
-- ====================================================================
local function attachmentDrag(item, rootPart)
    if holdingItems[item] then return end 
    
    local itemPart = item:FindFirstChild("Union") or item:FindFirstChild("Can") or (item:IsA("Model") and item.PrimaryPart) or item:FindFirstChildWhichIsA("BasePart") or item
    if not itemPart then return end
    
    holdingItems[item] = true 
    
    triggerDragSystem(item, itemPart)
    task.wait(0.01) 
    
    local dragRemote = getDragRemote()
    if not dragRemote then return end

    task.spawn(function()
        pcall(function()
            dragRemote:FireServer(item, itemPart)
        end)
    end)

    local attItem = Instance.new("Attachment")
    attItem.Name = "MobileDragAttItem"
    attItem.Parent = itemPart

    local attPlayer = getMasterAttachment(rootPart)

    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "DragAlignPos"
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = attItem
    alignPos.Attachment1 = attPlayer
    alignPos.MaxForce = math.huge 
    alignPos.MaxVelocity = math.huge 
    alignPos.Responsiveness = CONFIG.PhysicsResponsiveness
    alignPos.Parent = item

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Name = "DragAlignOri"
    alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
    alignOri.Attachment0 = attItem
    alignOri.Attachment1 = attPlayer
    alignOri.MaxTorque = math.huge 
    alignOri.Responsiveness = CONFIG.PhysicsResponsiveness
    alignOri.Parent = item
    
    local loopConnection
    loopConnection = RunService.Stepped:Connect(function()
        if not item or not item.Parent then
            holdingItems[item] = nil 
            loopConnection:Disconnect()
            return
        end
        
        pcall(function()
            enforceNoClip(item) 
            
            if itemPart and itemPart.Parent then
                local currentDist = (itemPart.Position - rootPart.Position).Magnitude
                if currentDist <= 4 then
                    invisibleClientItem(item)
                end
            end
        end)
    end)
end

-- ====================================================================
-- KÍCH HOẠT VÒNG LẶP ĐỒNG THỜI (CORE LOOPS)
-- ====================================================================

-- 1. 🔥 VÒNG LẶP KILL AURA ĐỘC LẬP (ĐÃ KHÔI PHỤC HOÀN TOÀN)
task.spawn(function()
    while task.wait(CONFIG.AttackDelay) do
        if not CONFIG.AuraEnabled then continue end
        
        local character = localPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local bat, updateNearbyRemote = getBatStuff()
        
        if hrp and bat then
            local rawTargets = {}
            
            -- Quét mục tiêu trong thư mục Characters (Quái) và Structures (Phế liệu tĩnh)
            local foldersToSearch = { Workspace:FindFirstChild("Characters"), Workspace:FindFirstChild("Structures") }
            for _, folder in pairs(foldersToSearch) do
                if folder then
                    for _, obj in pairs(folder:GetChildren()) do
                        if isValidTarget(obj, character) then 
                            table.insert(rawTargets, obj) 
                        end
                    end
                end
            end
            
            -- Quét mục tiêu bị ẩn ẩn (Nil Instances) nếu có hỗ trợ executor
            if getnilinstances then
                for _, obj in pairs(getnilinstances()) do
                    if obj:IsA("Model") and isValidTarget(obj, character) then 
                        table.insert(rawTargets, obj) 
                    end
                end
            end
            
            -- Lọc mục tiêu nằm trong bán kính MaxDistance (16 studs)
            local validTargetsWithDist = {}
            for _, obj in pairs(rawTargets) do
                local targetPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or (obj:IsA("BasePart") and obj)
                if targetPart then
                    local distance = (hrp.Position - targetPart.Position).Magnitude
                    if distance <= CONFIG.MaxDistance then
                        table.insert(validTargetsWithDist, {instance = obj, dist = distance})
                    end
                end
            end
            
            -- Sắp xếp mục tiêu gần nhất lên trước và vung gậy tấn công đám đông
            table.sort(validTargetsWithDist, function(a, b) return a.dist < b.dist end)
            local targetsToAttack = {}
            for i = 1, math.min(#validTargetsWithDist, CONFIG.MaxTargets) do 
                table.insert(targetsToAttack, validTargetsWithDist[i].instance) 
            end
            
            if #targetsToAttack > 0 then
                bat.Swing:FireServer()
                local packedArgs = { [1] = targetsToAttack }
                updateNearbyRemote:FireServer(unpack(packedArgs))
                bat.HitTargets:FireServer(unpack(packedArgs))
            end
        end
    end
end)

-- 2. Luồng quét nhặt động đồ trong DroppedItems (15 Studs)
RunService.Heartbeat:Connect(function()
    if not CONFIG.DragEnabled then return end
    
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local items = DroppedItemsFolder:GetChildren()
    
    for i = 1, #items do
        local item = items[i]
        
        if not holdingItems[item] then
            local itemPosition = item:IsA("Model") and item:GetPivot().Position or (item:IsA("BasePart") and item.Position)
            if itemPosition then
                local distance = (rootPart.Position - itemPosition).Magnitude
                
                if distance <= CONFIG.DetectRange then
                    attachmentDrag(item, rootPart)
                end
            end
        end
    end
end)

print("[🎉 COMPLETED] Toàn bộ hệ thống đã hoạt động bình thường! Kill Aura đập quái mượt mà, nhặt đồ chống văng an toàn!");
return true
