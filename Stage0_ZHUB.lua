-- 1. Tự động thiết lập cấu hình thân thiện Mobile & PC
local optimizedConfig = {
    ["Flags"] = {
        ["Killaura"] = true,
        ["KillauraRange"] = 25, -- Giảm xuống 25 để tránh lỗi Anticheat kích hoạt trên Mobile
        ["AutoEat"] = true,
        ["AutoEatThreshold"] = 50,
        ["AutoHeal"] = true,
        ["AutoHealThreshold"] = 50,
        ["AutoDrag"] = true, -- Tự động hút/gom vật phẩm
        ["AutoDragRange"] = 15,
        ["DragPriorityItems"] = {"Gas Mask", "Emerald"},
        ["AntiAFK"] = true, -- Chống bị văng game khi treo máy lâu
        ["FPSBoost"] = true, -- Bật tối ưu FPS cho máy yếu/Mobile
        ["RemoveFog"] = true, -- Xóa sương mù giúp nhìn rõ và mượt hơn
        ["Fullbright"] = true, -- Làm sáng bản đồ
        ["Settings_MenuToggle"] = {"K", "Toggle", {}}, -- Phím K để ẩn/hiện menu trên PC
        ["ShowFPS"] = false,
        ["ShowDistance"] = false,
        ["ESPCombat"] = false, -- Tắt bớt ESP để không bị lag máy
        ["ChestsESP"] = false,
        ["ESPResources"] = false,
        ["AutoReload"] = true,
        ["NoRecoil"] = true, -- Tắt độ giật súng
        ["NoSpread"] = true, -- Đạn bay thẳng
        ["SpeedEnabled"] = false, -- Để false cho an toàn, bật lên dễ bị kick
        ["SpeedValue"] = 16
    },
    ["Version"] = "5.5.2",
    ["GameId"] = "sta",
    ["ConfigVersion"] = 1,
    ["Script"] = "ZHUB"
}

-- 2. Lưu cấu hình vào bộ nhớ máy (Tùy biến theo từng Executor)
if writefile then
    -- Lưu thành file config mặc định của ZHUB để script tự nhận diện khi load
    writefile("ZHUB_Config.json", game:GetService("HttpService"):JSONEncode(optimizedConfig))
    writefile("ZHUB/sta.json", game:GetService("HttpService"):JSONEncode(optimizedConfig))
end

-- 3. Khởi chạy Script chính
loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
