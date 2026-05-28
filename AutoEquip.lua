-- Chờ trò chơi tải xong
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 MOBILE DRAG BACK] Khởi chạy hệ thống Drag cố định SAU LƯNG + Kill Aura...");

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- ====================================================================
-- BẢNG CẤU HÌNH ĐÃ KHÓA VỊ TRÍ SAU LƯNG CHO TWEEN / MOBILE
-- ====================================================================
local CONFIG = {
    FollowDistance = 3.0,      -- Khoảng cách giữ đồ sau lưng (3 studs)
    
    -- Cấu hình Auto Drag
    DragEnabled = true,        
    DetectRange = 10,          
    MaxHoldingItems = 8,       

    -- Cấu hình Kill Aura
    AuraEnabled = true,        
    MaxDistance = 16,          
    AttackDelay = 0.12,        
    MaxTargets = 4,            

    SearchFolders = {
        Workspace:FindFirstChild("Characters"),
        Workspace:FindFirstChild("Structures"),
    },
    DroppedItemsFolder = Workspace:WaitForChild("DroppedItems")
}

local holdingItems = {}
local currentHoldingCount = 0

-- ====================================================================
-- CÁC HÀM BỔ TRỢ AN TOÀN
-- ====================================================================
local function isValidTarget(obj, character)
    if not obj or obj == character or obj:IsAncestorOf(character) then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    if string.find(string.lower(obj.Name), "scrap pile") then return true end
    local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getBatStuff()
    local character = localPlayer.Character
    if character then
        local bat = character:FindFirstChild("Bat")
        local autoTarget = character:FindFirstChild("AutoTargetClient")
        if bat and bat:FindFirstChild("Swing") and bat:FindFirstChild("HitTargets") and autoTarget then
            return bat, autoTarget:FindFirstChild("UpdateNearbyTargets")
        end
    end
    return nil, nil
end

local function getDragRemote()
    local character = localPlayer.Character
    return character and character:FindFirstChild("DragSystem") and character.DragSystem:FindFirstChild("DragItem") or nil
end

local function triggerDragSystem(item, itemPart)
    local dragDetector = item:FindFirstChildWhichIsA("DragDetector") or item:FindFirstChildOfClass("DragDetector")
    if dragDetector and firesignal then firesignal(dragDetector.DragStart, localPlayer) end
    local networkRemote = item:FindFirstChild("ItemDrag") and item.ItemDrag:FindFirstChild("RequestNetworkOwnership")
    if networkRemote then pcall(function() networkRemote:FireServer(itemPart) end) end
end

local function noClipItem(item)
    if item:IsA("BasePart") then item.CanCollide = false end
    for _, child in ipairs(item:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CanCollide = false
            child.Velocity = Vector3.zero
            child.RotVelocity = Vector3.zero
        end
    end
end

-- ====================================================================
-- 🔥 LUỒNG XỬ LÝ ÉP ĐỒ ĐI SAU LƯNG KHÔNG BỊ TRỄ (ANTI-LAG TWEEN)
-- ====================================================================
local function attachmentDrag(item, rootPart)
    if holdingItems[item] or currentHoldingCount >= CONFIG.MaxHoldingItems then return end
    
    local itemPart = item:FindFirstChild("Union") or item:FindFirstChild("Can") or (item:IsA("Model") and item.PrimaryPart) or item:FindFirstChildWhichIsA("BasePart") or item
    if not itemPart then return end
    
    triggerDragSystem(item, itemPart)
    task.wait(0.02)
    
    local dragRemote = getDragRemote()
    if not dragRemote then return end

    holdingItems[item] = true
    currentHoldingCount = currentHoldingCount + 1
    noClipItem(item)

    task.spawn(function()
        pcall(function() dragRemote:FireServer(item, itemPart) end)
    end)

    -- Tạo điểm kết nối gốc trên vật phẩm
    local attItem = Instance.new("Attachment")
    attItem.Name = "CustomDragAttItem"
    attItem.Parent = itemPart

    -- Tạo điểm hút trong thế giới World
    local attPlayer = Instance.new("Attachment")
    attPlayer.Name = "CustomDragAttPlayer"
    attPlayer.Parent = Workspace.Terrain 

    -- Cài đặt lực kéo siêu tốc để đồ không bị tụt lại khi Tween quá nhanh
    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = attItem
    alignPos.Attachment1 = attPlayer
    alignPos.MaxForce = math.huge        
    alignPos.Responsiveness = 200        -- Phản hồi ngay lập tức, không có độ nhún đàn hồi
    alignPos.Parent = item

    -- Khóa góc xoay của đồ vật
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
    alignOri.Attachment0 = attItem
    alignOri.Attachment1 = attPlayer
    alignOri.MaxTorque = math.huge
    alignOri.Responsiveness = 200
    alignOri.Parent = item
    
    -- Vòng lặp liên tục ép điểm hút nằm đúng vị trí SAU LƯNG
    local dragConnection
    dragConnection = RunService.PreSimulation:Connect(function()
        if not item or not item.Parent or not holdingItems[item] or not rootPart or not rootPart.Parent then
            if holdingItems[item] then
                holdingItems[item] = nil
                currentHoldingCount = math.max(0, currentHoldingCount - 1)
            end
            attPlayer:Destroy()
            dragConnection:Disconnect()
            return
        end
        
        -- Khử va chạm liên tục
        if itemPart and itemPart.Parent then itemPart.CanCollide = false end
        
        -- TÍNH TOÁN VỊ TRÍ SAU LƯNG: Nghịch đảo của hướng nhìn (LookVector)
        local targetCFrame = rootPart.CFrame
        local behindOffset = -targetCFrame.LookVector * CONFIG.FollowDistance
        
        -- Đặt tọa độ điểm neo: Sau lưng + Nâng cao lên 1.5 Studs để tránh quẹt đất
        attPlayer.WorldPosition = rootPart.Position + behindOffset + Vector3.new(0, 1.5, 0)
        attPlayer.WorldCFrame = targetCFrame
    end)
end

-- ====================================================================
-- CÁC VÒNG LẶP CORE CHẠY ĐỒNG THỜI
-- ====================================================================

-- 1. Luồng Auto Drag quét đồ dưới sàn (Heartbeat)
RunService.Heartbeat:Connect(function()
    if not CONFIG.DragEnabled then return end
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart or currentHoldingCount >= CONFIG.MaxHoldingItems then return end
    
    local items = CONFIG.DroppedItemsFolder:GetChildren()
    for i = 1, #items do
        local item = items[i]
        if not holdingItems[item] then
            local itemPosition = item:IsA("Model") and item:GetPivot().Position or (item:IsA("BasePart") and item.Position)
            if itemPosition then
                local distance = (rootPart.Position - itemPosition).Magnitude
                if distance <= CONFIG.DetectRange then
                    attachmentDrag(item, rootPart)
                    if currentHoldingCount >= CONFIG.MaxHoldingItems then break end
                end
            end
        end
    end
end)

-- 2. Luồng Kill Aura (Đập quái/Phế liệu độc lập)
task.spawn(function()
    while task.wait(CONFIG.AttackDelay) do
        if not CONFIG.AuraEnabled then continue end
        local character = localPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local bat, updateNearbyRemote = getBatStuff()
        
        if hrp and bat and updateNearbyRemote then
            local rawTargets = {}
            for _, folder in pairs(CONFIG.SearchFolders) do
                if folder then
                    for _, obj in pairs(folder:GetChildren()) do
                        if isValidTarget(obj, character) then table.insert(rawTargets, obj) end
                    end
                end
            end
            
            local validTargetsWithDist = {}
            for _, obj in pairs(rawTargets) do
                local targetPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or (obj:IsA("Model") and obj.PrimaryPart) or (obj:IsA("BasePart") and obj)
                if targetPart then
                    local distance = (hrp.Position - targetPart.Position).Magnitude
                    if distance <= CONFIG.MaxDistance then
                        table.insert(validTargetsWithDist, {instance = obj, dist = distance})
                    end
                end
            end
            
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

print("[🎉 SUCCESS] Đồ vật đã được khóa cứng cố định SAU LƯNG thành công!");
return true
