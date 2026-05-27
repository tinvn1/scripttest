-- 1. Định nghĩa chuỗi JSON cấu hình chuẩn của bạn
local myConfigString = [[
{"Flags":{"InstantPrompts":false,"SpeedMode":["Normal"],"EnemyESP":false,"SelectedESPItems":[],"FPSBoost":false,"AutoTeleportDropsTeleportDelay":0,"UsePickupCategories":false,"AutoRepairRange":5,"BringPickupSortOrder":["Nearest First"],"BringAllPickup":false,"AutoTeleportDrops":false,"AutoTeleportDropsTarget":["Shredder"],"ShowDistance":false,"FreePsychicDebugBeams":false,"RemoveFog":false,"FreePsychicHoverVisible":true,"DragSelectedItems":[],"ThirdPerson":false,"DragPriorityItems":["Gas Mask","Emerald"],"SchemEnablePlacement":false,"NoRecoil":false,"AutoEatThreshold":50,"ESPCombat":false,"PriorityPickupOverride":false,"AutoShootHealTeammates":false,"Settings_PanicKey":["None","Toggle",[]],"AimSmoothness":0.15,"MaxTargets":10,"KnownPlayersList":[],"AutoShoot":false,"AntiAFK":false,"Fullbright":false,"AutoDrag":true,"Settings_NexusToggle":["None","Toggle",[]],"HideDayCounter":false,"AutoOpenChest":false,"StreamerMode":false,"FreeAxisRotation":false,"Nexus_AutoCollect":false,"NoSlowdown":false,"HitboxExpander":false,"ESPResources":false,"Nexus_Radius":18,"AutoShootAimPart":["Head"],"NoSlowOnBandage":false,"DragPriorityOverride":false,"DragUseCategories":false,"AutoReload":false,"AutoShootTargetMethod":["Distance"],"PreventBasePickup":false,"AutoShootBulletTrails":false,"PanicOnStaff":false,"AutoRepair":false,"AutoLeaveStaff":false,"Settings_MenuToggle":["K","Toggle",[]],"FlySpeed":50,"PickupCategories":[],"PriorityPickupItems":["Gas Mask","Emerald"],"BarrelESP":false,"AutoDragHoldHeight":1,"AutoShootFOV":150,"HitboxSize":10,"SpeedEnabled":false,"DetectUnknown":false,"SchemEnableSelection":false,"ChestsESP":false,"SelectedPickupItems":[],"PanicOnUnknown":false,"AimLocker":false,"Settings_AutoDragToggle":["None","Toggle",[]],"FreePsychicEditorTool":false,"AutoRepairCooldown":0.4 Ram","DragSelectivePickup":false,"AttackSpeedOffset":0,"LockFloatingIcon":false,"MinimapEnabled":false,"AutoDragOrbitAngle":0,"AutoShootRange":100,"ShowLogo":true,"ItemESPFilter":false,"AimPart":["Head"],"Settings_AutoShootToggle":["None","Toggle",[]],"DetectStaff":false,"ConsumeFood":false,"AutoShootUseFOV":false,"AutoEat":false,"FreePsychicPerWeaponTarget":false,"AutoHealThreshold":50,"AutoHeal":false,"SpeedValue":16,"Nexus_Mode":["Radius"],"AutoDragRange":12,"StoreMedicalInBag":false,"TargetingPriorityEnabled":false,"UnlockRotation":false,"AutoRearmTrapRange":10,"NoSpread":false,"DetectionRadius":500,"ShowFPS":false,"BringPickupWhitelist":[],"Nexus_FOV":150,"RapidFireMultiplier":2,"AutoLeaveUnknown":false,"AutoOpenChestRange":25,"BringPickupItem":false,"InfiniteJump":false,"FlyMode":false,"AutoRearmBearTrap":false,"Settings_ZPsychicToggle":["None","Toggle",[]],"FreePsychic":false,"SelectivePickup":false,"Killaura":true,"StoreAmmoInBag":false,"Settings_KillauraToggle":["None","Toggle",[]],"DetectAnticheatFlag":false,"PriorityTargets":[],"ThirdPersonDistance":15,"AutoDeconstruct":false,"AutoDeconstructThreshold":90,"PlaceAnywhere":false,"KillauraRange":35,"DragCategories":[],"AutoDragHoldDistance":3,"ESPMedical":false,"FOV":70,"ESPFuel":false,"RapidFire":false,"AutoDragOrbitSpeed":0 ram,"NoClip":false,"UsePlacementHooks":true,"ESPFood":false},"Version":"5.5.2","GameId":"sta","ConfigVersion":1,"Script":"ZHUB","ExportedAt":1779877135}
]]

-- 2. Tạo cấu trúc thư mục chính xác (zhub/configs/)
pcall(function()
    if not isfolder("zhub") then makefolder("zhub") end
    if not isfolder("zhub/configs") then makefolder("zhub/configs") end
end)

-- 3. Ghi đè cấu hình vào đúng file default.json
local success, err = pcall(function()
    writefile("zhub/configs/default.json", myConfigString)
end)

if success then
    print("[Delta Workspace] Đã chuẩn bị file default.json thành công!")
else
    warn("[Delta Workspace] Thất bại khi ghi file: ", err)
end

-- Tối ưu hóa: Chờ 0.5 giây để Delta hoàn tất việc ghi file vật lý vào bộ nhớ máy
task.wait(0.5)

-- 4. Kích chạy Script gốc của ZHUB
loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()

-- 5. ÉP BUỘC ĐỒNG BỘ (Bảo hiểm): Đề phòng ZHUB không chịu tự đọc file lúc khởi động
-- Đoạn này sẽ chạy ngầm, đợi menu hiện lên rồi ép các nút trên menu bật theo file JSON
task.spawn(function()
    task.wait(4.5) -- Đợi menu ZHUB hoàn thành thiết lập UI
    
    local HttpService = game:GetService("HttpService")
    local configData = HttpService:JSONDecode(myConfigString)
    local flags = configData.Flags
    
    -- Tìm bảng chứa dữ liệu đang chạy của Script
    local targetFlags = getgenv().Flags or _G.Flags or getgenv().Settings or getgenv().Config
    
    if targetFlags then
        for key, value in pairs(flags) do
            targetFlags[key] = value
        end
        print("[Delta Workspace] Đã kích hoạt cơ chế Ép đồng bộ cấu hình thành công!")
    else
        -- Nếu script giấu kín bảng cấu hình, tạo môi trường ảo để đánh lừa thư viện UIX
        if not getgenv().Flags then getgenv().Flags = {} end
        for key, value in pairs(flags) do
            getgenv().Flags[key] = value
            getgenv()[key] = value
        end
        print("[Delta Workspace] Đã nạp cấu hình cưỡng bức vào Môi trường Toàn cục!")
    end
    
    -- Gọi các hàm cập nhật giao diện nếu có
    if getgenv().UpdateSliders then pcall(getgenv().UpdateSliders) end
    if getgenv().UpdateToggles then pcall(getgenv().UpdateToggles) end
end)
