if not game:IsLoaded() then game.Loaded:Wait() end

print("[🚀 STAGE 0] Khởi chạy ZHUB & Đợi script load hoàn toàn...");

-- Toàn bộ nội dung cấu hình JSON của bạn
local jsonConfig = [[{"Flags":{"InstantPrompts":false,"SpeedMode":["Normal"],"EnemyESP":false,"SelectedESPItems":[],"FPSBoost":false,"AutoTeleportDropsTeleportDelay":0,"UsePickupCategories":false,"AutoRepairRange":5,"BringPickupSortOrder":["Nearest First"],"BringAllPickup":false,"AutoTeleportDrops":false,"AutoTeleportDropsTarget":["Shredder"],"ShowDistance":false,"FreePsychicDebugBeams":false,"RemoveFog":false,"FreePsychicHoverVisible":true,"DragSelectedItems":[],"ThirdPerson":false,"DragPriorityItems":["Gas Mask","Emerald"],"SchemEnablePlacement":false,"NoRecoil":false,"AutoEatThreshold":50,"ESPCombat":false,"PriorityPickupOverride":false,"AutoShootHealTeammates":false,"Settings_PanicKey":["None","Toggle",[]],"AimSmoothness":0.15,"MaxTargets":10,"KnownPlayersList":[],"AutoShoot":false,"AntiAFK":false,"Fullbright":false,"AutoDrag":true,"Settings_NexusToggle":["None","Toggle",[]],"HideDayCounter":false,"AutoOpenChest":false,"StreamerMode":false,"FreeAxisRotation":false,"Nexus_AutoCollect":false,"NoSlowdown":false,"HitboxExpander":false,"ESPResources":false,"Nexus_Radius":18,"AutoShootAimPart":["Head"],"NoSlowOnBandage":false,"DragPriorityOverride":false,"DragUseCategories":false,"AutoReload":false,"AutoShootTargetMethod":["Distance"],"PreventBasePickup":false,"AutoShootBulletTrails":false,"PanicOnStaff":false,"AutoRepair":false,"AutoLeaveStaff":false,"Settings_MenuToggle":["K","Toggle",[]],"FlySpeed":50,"PickupCategories":[],"PriorityPickupItems":["Gas Mask","Emerald"],"BarrelESP":false,"AutoDragHoldHeight":1,"AutoShootFOV":150,"HitboxSize":10,"SpeedEnabled":false,"DetectUnknown":false,"SchemEnableSelection":false,"ChestsESP":false,"SelectedPickupItems":[],"PanicOnUnknown":false,"AimLocker":false,"Settings_AutoDragToggle":["None","Toggle",[]],"FreePsychicEditorTool":false,"AutoRepairCooldown":0.4,"DragSelectivePickup":false,"AttackSpeedOffset":0,"LockFloatingIcon":false,"MinimapEnabled":false,"AutoDragOrbitAngle":0,"AutoShootRange":100,"ShowLogo":true,"ItemESPFilter":false,"AimPart":["Head"],"Settings_AutoShootToggle":["None","Toggle",[]],"DetectStaff":false,"ConsumeFood":false,"AutoShootUseFOV":false,"AutoEat":false,"FreePsychicPerWeaponTarget":false,"AutoHealThreshold":50,"AutoHeal":false,"SpeedValue":16,"Nexus_Mode":["Radius"],"AutoDragRange":12,"StoreMedicalInBag":false,"TargetingPriorityEnabled":false,"UnlockRotation":false,"AutoRearmTrapRange":10,"NoSpread":false,"DetectionRadius":500,"ShowFPS":false,"BringPickupWhitelist":[],"Nexus_FOV":150,"RapidFireMultiplier":2,"AutoLeaveUnknown":false,"AutoOpenChestRange":25,"BringPickupItem":false,"InfiniteJump":false,"FlyMode":false,"AutoRearmBearTrap":false,"Settings_ZPsychicToggle":["None","Toggle",[]],"FreePsychic":false,"SelectivePickup":false,"Killaura":true,"StoreAmmoInBag":false,"Settings_KillauraToggle":["None","Toggle",[]],"DetectAnticheatFlag":false,"PriorityTargets":[],"ThirdPersonDistance":15,"AutoDeconstruct":false,"AutoDeconstructThreshold":90,"PlaceAnywhere":false,"KillauraRange":35,"DragCategories":[],"AutoDragHoldDistance":3,"ESPMedical":false,"FOV":70,"ESPFuel":false,"RapidFire":false,"AutoDragOrbitSpeed":0,"NoClip":false,"UsePlacementHooks":true,"ESPFood":false},"Version":"5.5.2","GameId":"sta","ConfigVersion":1,"Script":"ZHUB","ExportedAt":1779877178}]]

-- 1. Tạo file cấu hình chính xác vào hệ thống thư mục LinoriaLib của Z HUB
pcall(function()
    if makefolder then 
        makefolder("ZHUB")
        makefolder("ZHUB/configs")
    end
    if writefile then
        -- Lưu thành tên "autoload.json" để tí nữa gọi trực tiếp cho chuẩn
        writefile("ZHUB/configs/autoload.json", jsonConfig)
        print("[💾 WORKSPACE] Đã lưu file cấu hình ảo thành công!");
    end
end)

-- 2. Tải mã nguồn Z HUB từ tác giả
local successLoad, errLoad = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

if not successLoad then 
    return warn("[⚠️ STAGE 0] Không thể tải ZHUB: " .. tostring(errLoad)) 
end

-- 3. Tiến trình đợi Script khởi tạo xong UI rồi mới Load Config
task.spawn(function()
    print("[⏳] Đang đợi hệ thống UI của Z HUB load hoàn toàn...")
    
    -- Vòng lặp chờ LinoriaLib đăng ký SaveManager vào môi trường toàn cục
    local timeout = 0
    while not getgenv().SaveManager and timeout < 60 do
        task.wait(0.5)
        timeout = timeout + 1
    end

    if not getgenv().SaveManager then
        return warn("[⚠️] Quá thời gian chờ! Không tìm thấy SaveManager của bộ UI.")
    end

    -- Đợi thêm 3 giây để đảm bảo menu đã vẽ xong toàn bộ Toggles/Sliders lên màn hình Mobile
    task.wait(3)

    print("[🔍] Phát hiện script đã load xong. Tiến hành nạp Config...")

    -- 4. Ép SaveManager của Z HUB tự load file config có tên "autoload"
    local successConfig, errConfig = pcall(function()
        local SaveManager = getgenv().SaveManager
        if SaveManager and SaveManager.Load then
            SaveManager:Load("autoload")
            print("[🎉 SUCCESS] Đã gọi lệnh hệ thống nạp thành công cấu hình 'autoload'!")
        else
            error("SaveManager không hỗ trợ hàm Load")
        end
    end)

    -- Dự phòng: Nếu hàm Load tự động của UI bị lỗi, ép trực tiếp bằng mã lệnh cứng
    if not successConfig then
        warn("[⚠️] Không thể load bằng SaveManager ("..tostring(errConfig).."). Đang chuyển sang ép lệnh trực tiếp...")
        task.wait(1)
        
        local function forceSet(flag, val)
            if getgenv().Toggles and getgenv().Toggles[flag] then pcall(function() getgenv().Toggles[flag]:SetValue(val) end) end
            if getgenv().Options and getgenv().Options[flag] then pcall(function() getgenv().Options[flag]:SetValue(val) end) end
        end
        
        forceSet("Killaura", true)
        forceSet("KillauraRange", 35)
        forceSet("AutoDrag", true)
        forceSet("AutoDragRange", 12)
        forceSet("AutoDragHoldDistance", 3)
        forceSet("AutoDragHoldHeight", 1)
        
        print("[🎉 SUCCESS] Đã hoàn thành nạp ép buộc bằng cấu trúc Toggles/Options.")
    end
end)

return true
