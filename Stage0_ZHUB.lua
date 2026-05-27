-- 1. Khởi chạy Script gốc trước
loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()

-- 2. Chờ script tải xong hoàn toàn (tầm 5 giây) rồi ép config
task.spawn(function()
    print("Đang chờ Script ZHUB load...")
    task.wait(5) -- Bạn có thể tăng lên 7-8 giây nếu máy load chậm
    
    -- Danh sách các tính năng cần ép bật (Thân thiện Mobile/PC)
    local forceSettings = {
        ["Killaura"] = true,
        ["KillauraRange"] = 25,
        ["AutoEat"] = true,
        ["AutoEatThreshold"] = 50,
        ["AutoHeal"] = true,
        ["AutoHealThreshold"] = 50,
        ["AutoDrag"] = true,
        ["AutoDragRange"] = 15,
        ["AntiAFK"] = true,
        ["FPSBoost"] = true,
        ["RemoveFog"] = true,
        ["Fullbright"] = true,
        ["NoRecoil"] = true,
        ["NoSpread"] = true,
        ["AutoReload"] = true
    }

    -- Tìm và ép dữ liệu vào môi trường của Script
    local registry = getreg or debug.getregistry
    if registry then
        for _, v in pairs(registry()) do
            if type(v) == "table" and v.Flags then
                -- Tìm thấy bảng quản lý nút bấm của UIX
                for setting, value in pairs(forceSettings) do
                    v.Flags[setting] = value
                    
                    -- Kích hoạt hàm callback (nếu có) để script thực sự chạy tính năng đó
                    if v.Options and v.Options[setting] and v.Options[setting].Callback then
                        pcall(function()
                            v.Options[setting].Callback(value)
                        end)
                    end
                end
                print("Đã ép tự động load cấu hình thành công!")
                break
            end
        end
    else
        -- Cách phụ nếu không lấy được registry: Ép trực tiếp thông qua biến Global môi trường
        if shared.Flags or _G.Flags then
            local target = shared.Flags or _G.Flags
            for setting, value in pairs(forceSettings) do
                target[setting] = value
            end
            print("Đã ép cấu hình qua biến Global!")
        end
    end
end)
