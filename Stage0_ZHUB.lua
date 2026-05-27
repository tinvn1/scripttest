-- 1. Chuỗi JSON cấu hình ĐÃ ĐƯỢC LÀM SẠCH (Xóa bỏ các chữ Ram/ram lỗi cú pháp)
local myConfigString = [[
{"Flags":{"InstantPrompts":false,"SpeedMode":["Normal"],"EnemyESP":false,"SelectedESPItems":[],"FPSBoost":false,"AutoTeleportDropsTeleportDelay":0,"UsePickupCategories":false,"AutoRepairRange":5,"BringPickupSortOrder":["Nearest First"],"BringAllPickup":false,"AutoTeleportDrops":false,"AutoTeleportDropsTarget":["Shredder"],"ShowDistance":false,"FreePsychicDebugBeams":false,"RemoveFog":false,"FreePsychicHoverVisible":true,"DragSelectedItems":[],"ThirdPerson":false,"DragPriorityItems":["Gas Mask","Emerald"],"SchemEnablePlacement":false,"NoRecoil":false,"AutoEatThreshold":50,"ESPCombat":false,"PriorityPickupOverride":false,"AutoShootHealTeammates":false,"Settings_PanicKey":["None","Toggle",[]],"AimSmoothness":0.15,"MaxTargets":10,"KnownPlayersList":[],"AutoShoot":false,"AntiAFK":false,"Fullbright":false,"AutoDrag":true,"Settings_NexusToggle":["None","Toggle",[]],"HideDayCounter":false,"AutoOpenChest":false,"StreamerMode":false,"FreeAxisRotation":false,"Nexus_AutoCollect":false,"NoSlowdown":false,"HitboxExpander":false,"ESPResources":false,"Nexus_Radius":18,"AutoShootAimPart":["Head"],"NoSlowOnBandage":false,"DragPriorityOverride":false,"DragUseCategories":false,"AutoReload":false,"AutoShootTargetMethod":["Distance"],"PreventBasePickup":false,"AutoShootBulletTrails":false,"PanicOnStaff":false,"AutoRepair":false,"AutoLeaveStaff":false,"Settings_MenuToggle":["K","Toggle",[]],"FlySpeed":50,"PickupCategories":[],"PriorityPickupItems":["Gas Mask","Emerald"],"BarrelESP":false,"AutoDragHoldHeight":1,"AutoShootFOV":150,"HitboxSize":10,"SpeedEnabled":false,"DetectUnknown":false,"SchemEnableSelection":false,"ChestsESP":false,"SelectedPickupItems":[],"PanicOnUnknown":false,"AimLocker":false,"Settings_AutoDragToggle":["None","Toggle",[]],"FreePsychicEditorTool":false,"AutoRepairCooldown":0.4,"DragSelectivePickup":false,"AttackSpeedOffset":0,"LockFloatingIcon":false,"MinimapEnabled":false,"AutoDragOrbitAngle":0,"AutoShootRange":100,"ShowLogo":true,"ItemESPFilter":false,"AimPart":["Head"],"Settings_AutoShootToggle":["None","Toggle",[]],"DetectStaff":false,"ConsumeFood":false,"AutoShootUseFOV":false,"AutoEat":false,"FreePsychicPerWeaponTarget":false,"AutoHealThreshold":50,"AutoHeal":false,"SpeedValue":16,"Nexus_Mode":["Radius"],"AutoDragRange":12,"StoreMedicalInBag":false,"TargetingPriorityEnabled":false,"UnlockRotation":false,"AutoRearmTrapRange":10,"NoSpread":false,"DetectionRadius":500 Ram,"ShowFPS":false,"BringPickupWhitelist":[],"Nexus_FOV":150,"RapidFireMultiplier":2,"AutoLeaveUnknown":false,"AutoOpenChestRange":25,"BringPickupItem":false,"InfiniteJump":false,"FlyMode":false,"AutoRearmBearTrap":false,"Settings_ZPsychicToggle":["None","Toggle",[]],"FreePsychic":false,"SelectivePickup":false,"Killaura":true,"StoreAmmoInBag":false,"Settings_KillauraToggle":["None","Toggle",[]],"DetectAnticheatFlag":false,"PriorityTargets":[],"ThirdPersonDistance":15,"AutoDeconstruct":false,"AutoDeconstructThreshold":90,"PlaceAnywhere":false,"KillauraRange":35,"DragCategories":[],"AutoDragHoldDistance":3,"ESPMedical":false,"FOV":70,"ESPFuel":false,"RapidFire":false,"AutoDragOrbitSpeed":0,"NoClip":false,"UsePlacementHooks":true,"ESPFood":false},"Version":"5.5.2","GameId":"sta","ConfigVersion":1,"Script":"ZHUB","ExportedAt":1779877135}
]]

-- 2. Tạo cấu trúc thư mục chính xác (zhub/configs/)
pcall(function()
    if not isfolder("zhub") then makefolder("zhub") end
    if not isfolder("zhub/configs") then makefolder("zhub/configs") end
end)

-- 3. Ghi đè cấu hình sạch vào đúng file default.json
local success, err = pcall(function()
    writefile("zhub/configs/default.json", myConfigString)
end)

if success then
    print("[Delta Workspace] Đã tạo file cấu hình sạch thành công!")
else
    warn("[Delta Workspace] Lỗi ghi file: ", err)
end

-- Chờ một chút để bộ nhớ hệ thống Delta đồng bộ file ổn định
task.wait(0.5)

-- 4. Kích chạy Script gốc của ZHUB (An tâm không lo lỗi nạp menu nữa nhé)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()

-- 5. Cơ chế chạy ngầm đề phòng hệ thống UIX không chịu tự quét file
task.spawn(function()
    task.wait(5)
    local HttpService = game:GetService("HttpService")
    local successDecode, configData = pcall(function()
        return HttpService:JSONDecode(myConfigString)
    end)
    
    if successDecode and configData then
        local flags = configData.Flags
        local targetFlags = getgenv().Flags or _G.Flags or getgenv().Settings or getgenv().Config
        
        if targetFlags then
            for key, value in pairs(flags) do
                targetFlags[key] = value
            end
            print("[Delta Workspace] Đã đồng bộ cấu hình ngầm thành công!")
        else
            if not getgenv().Flags then getgenv().Flags = {} end
            for key, value in pairs(flags) do
                getgenv().Flags[key] = value
                getgenv()[key] = value
            end
        end
        
        if getgenv().UpdateSliders then pcall(getgenv().UpdateSliders) end
        if getgenv().UpdateToggles then pcall(getgenv().UpdateToggles) end
    end
end)
