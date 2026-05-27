-- 1. Tạo thư mục và ghi file cấu hình chuẩn cho ZHUB
local httpService = game:GetService("HttpService")
local configName = "ZHUB_Config.json" -- Tên file gốc của bạn

local optimizedConfig = {
    ["Flags"] = {
        ["Killaura"] = true,
        ["KillauraRange"] = 25,
        ["AutoEat"] = true,
        ["AutoEatThreshold"] = 50,
        ["AutoHeal"] = true,
        ["AutoHealThreshold"] = 50,
        ["AutoDrag"] = true,
        ["AutoDragRange"] = 15,
        ["DragPriorityItems"] = {"Gas Mask", "Emerald"},
        ["PriorityPickupItems"] = {"Gas Mask", "Emerald"},
        ["AntiAFK"] = true,
        ["FPSBoost"] = true,
        ["RemoveFog"] = true,
        ["Fullbright"] = true,
        ["Settings_MenuToggle"] = {"K", "Toggle", {}},
        ["NoRecoil"] = true,
        ["NoSpread"] = true,
        ["AutoReload"] = true,
        ["SpeedEnabled"] = false,
        ["SpeedValue"] = 16,
        ["ESPCombat"] = false,
        ["ChestsESP"] = false
    },
    ["Version"] = "5.5.2",
    ["GameId"] = "sta",
    ["ConfigVersion"] = 1,
    ["Script"] = "ZHUB"
}

-- Tiến hành ép ghi file vào tất cả các đường dẫn mà ZHUB có thể quét
if writefile then
    local jsonData = httpService:JSONEncode(optimizedConfig)
    
    -- Cách 1: Ghi thẳng vào file config chung
    pcall(function() writefile(configName, jsonData) end)
    
    -- Cách 2: Tạo thư mục ZHUB (nếu chưa có) và ghi file cấu hình riêng của game
    if makefolder then
        pcall(function() makefolder("ZHUB") end)
        pcall(function() writefile("ZHUB/sta.json", jsonData) end)
        pcall(function() writefile("ZHUB/config.json", jsonData) end)
    end
end

-- 2. Khởi chạy Script
loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
