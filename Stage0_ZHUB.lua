-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 COMBINED SCRIPT] Đang khởi chạy hệ thống Tự động hóa: Kill Aura + Auto Drag...");

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- ====================================================================
-- [PHẦN 1] CẤU HÌNH HỆ THỐNG
-- ====================================================================
local CONFIG = {
    -- Cấu hình Kill Aura
    AuraEnabled = true,        -- Bật/Tắt Kill Aura
    MaxDistance = 16,          -- Khoảng cách quét quái (Studs)
    AttackDelay = 0.1,         -- Tốc độ đánh (Giây)
    MaxTargets = 4,            -- Tối đa số mục tiêu đánh cùng lúc

    -- Cấu hình Auto Drag
    DragEnabled = true,        -- Bật/Tắt Auto Drag
    DetectRange = 12,          -- Phạm vi tự động quét nhặt đồ (Studs)
    FollowDistance = 3,        -- Khoảng cách giữ đồ lơ lửng sau lưng (Studs)

    -- Thư mục quét của hệ thống
    SearchFolders = {
        Workspace:FindFirstChild("Characters"),
        Workspace:FindFirstChild("Structures"),
    },
    DroppedItemsFolder = Workspace:WaitForChild("DroppedItems")
}

-- Bảng lưu trạng thái khóa vật phẩm của Auto Drag
local holdingItems = {}

-- ====================================================================
-- [PHẦN 2] CÁC HÀM BỔ TRỢ (UTILITIES)
-- ====================================================================

-- [Kill Aura] Kiểm tra mục tiêu hợp lệ
local function isValidTarget(obj, character)
    if not obj or obj == character or obj:IsAncestorOf(character) then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end -- Né người chơi khác
    
    -- Nếu là Scrap Pile (Phế liệu) -> Hợp lệ
    if string.find(string.lower(obj.Name), "scrap pile") then
        return true
    end
    
    -- Nếu là Quái vật (Có Humanoid và còn sống) -> Hợp lệ
    local humanoid = obj:FindFirstChildWhichIsA("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return true
    end
    
    return false
end

-- [Kill Aura] Lấy vũ khí và Remote liên quan
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

-- [Auto Drag] Lấy Remote Event tương tác
local function getDragRemote()
    local character = localPlayer.Character
    if not character then return nil end
    local dragSystem = character:FindFirstChild("DragSystem")
    return dragSystem and dragSystem:FindFirstChild("DragItem") or nil
end

-- [Auto Drag] Kích hoạt hệ thống DragDetector vật lý
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

-- [Auto Drag] Bật No-Clip (Tắt va chạm) để tránh văng nhân vật
local function noClipItem(item)
    if item:IsA("BasePart") then
        item.CanCollide = false
    end
    for _, child in ipairs(item:GetDescendants()) do
        if child:IsA("BasePart") then
            child.CanCollide = false
        end
    end
end

-- [Auto Drag] Xử lý liên kết kéo vật phẩm sau lưng
local function attachmentDrag(item, rootPart)
    if holdingItems[item] then return end
    
    local itemPart = item:FindFirstChild("Union") or item:FindFirstChild("Can") or (item:IsA("Model") and item.PrimaryPart) or item:FindFirstChildWhichIsA("BasePart") or item
    if not itemPart then return end
    
    triggerDragSystem(item, itemPart)
    task.wait(0.05)
    
    local dragRemote = getDragRemote()
    if not dragRemote then return end

    holdingItems[item] = true
    noClipItem(item)

    task.spawn(function()
        pcall(function()
            dragRemote:FireServer(item, itemPart)
        end)
    end)

    -- Tạo liên kết vật lý giữ khoảng cách an toàn
    local attItem = Instance.new("Attachment")
    attItem.Name = "DragAttachmentItem"
    attItem.Parent = itemPart

    local attPlayer = Instance.new("Attachment")
    attPlayer.Name = "DragAttachmentPlayer"
    attPlayer.Position = Vector3.new(0, 1.5, CONFIG.FollowDistance)
    attPlayer.Parent = rootPart

    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "DragAlign"
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = attItem
    alignPos.Attachment1 = attPlayer
    alignPos.MaxForce = 99999
    alignPos.Responsiveness = 25
    alignPos.Parent = item
    
    -- Khóa No-Clip liên tục theo chu kỳ vật lý
    local noClipConnection
    noClipConnection = RunService.Stepped:Connect(function()
        if not item or not item.Parent or not holdingItems[item] then
            noClipConnection:Disconnect()
            return
        end
        noClipItem(item)
    end)
end

-- ====================================================================
-- [PHẦN 3] KÍCH HOẠT VÒNG LẶP ĐỒNG THỜI (CORE LOOPS)
-- ====================================================================

-- 1. Khởi chạy Luồng Kill Aura (Chạy ngầm tách biệt)
task.spawn(function()
    print("[⚔️] Tiến trình Kill Aura đã kích hoạt thành công.");
    while task.wait(CONFIG.AttackDelay) do
        if not CONFIG.AuraEnabled then continue end
        
        local character = localPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local bat, updateNearbyRemote = getBatStuff()
        
        if hrp and bat then
            local rawTargets = {}
            
            -- Quét mục tiêu thông thường
            for _, folder in pairs(CONFIG.SearchFolders) do
                if folder then
                    for _, obj in pairs(folder:GetChildren()) do
                        if isValidTarget(obj, character) then
                            table.insert(rawTargets, obj)
                        end
                    end
                end
            end
            
            -- Quét mục tiêu ẩn (Nil Instances)
            if getnilinstances then
                for _, obj in pairs(getnilinstances()) do
                    if obj:IsA("Model") and isValidTarget(obj, character) then
                        table.insert(rawTargets, obj)
                    end
                end
            end
            
            -- Sàng lọc khoảng cách
            local validTargetsWithDist = {}
            for _, obj in pairs(rawTargets) do
                local targetPart = obj:FindFirstChild("HumanoidRootPart") 
                    or obj:FindFirstChild("Torso") 
                    or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) 
                    or (obj:IsA("BasePart") and obj)
                
                if targetPart then
                    local distance = (hrp.Position - targetPart.Position).Magnitude
                    if distance <= CONFIG.MaxDistance then
                        table.insert(validTargetsWithDist, {instance = obj, dist = distance})
                    end
                end
            end
            
            table.sort(validTargetsWithDist, function(a, b) return a.dist < b.dist end)
            
            -- Tấn công cụm mục tiêu gần nhất
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

-- 2. Khởi chạy Luồng Auto Drag (Dựa trên khung hình Heartbeat)
RunService.Heartbeat:Connect(function()
    if not CONFIG.DragEnabled then return end
    
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart
    
    for _, item in ipairs(CONFIG.DroppedItemsFolder:GetChildren()) do
        if holdingItems[item] then continue end
        
        local itemPosition = item:IsA("Model") and item:GetPivot().Position or (item:IsA("BasePart") and item.Position)
        if itemPosition then
            local distance = (rootPart.Position - itemPosition).Magnitude
            if distance <= CONFIG.DetectRange then
                attachmentDrag(item, rootPart)
            end
        end
    end
end)

print("[🎉 SUCCESS] Toàn bộ hệ thống tính năng đã chạy thay thế hoàn toàn Stage 0!");
return true
