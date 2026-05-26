local Workspace = game:GetService("Workspace")
local localPlayer = game:GetService("Players").LocalPlayer

-- =========================================================================
-- 🔥 HÀM TÌM NÚT BẤM PROXIMITYPROMPT CỦA TRẠM ĐIỆN
-- =========================================================================
local function getPowerBoxPrompt()
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Tìm kiếm chính xác đối tượng tên "Prompt" là ProximityPrompt nằm trong Power Box
        if obj.Name == "Prompt" and obj:IsA("ProximityPrompt") then
            -- Kiểm tra xem nó có thuộc về cấu trúc Power Plant -> Power Box không
            if obj.Parent and obj.Parent.Name == "Power Box" then
                return obj
            end
        end
    end
    return nil
