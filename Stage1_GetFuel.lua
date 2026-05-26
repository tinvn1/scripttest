local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- --- CONFIGURATION ---
local Config = {
    Aimbot = false, Wallhack = false, Hitbox = false,
    Fly = false, God = false, Noclip = false, 
    FlyVal = 50, HitboxSize = 15, CurrentTarget = nil,
    
    SpamKey1 = Enum.KeyCode.E, Spam1Active = false, Spam1Delay = 0.1,
    SpamKey2 = Enum.KeyCode.R, Spam2Active = false, Spam2Delay = 0.1,
    SpamKey3 = Enum.KeyCode.Q, Spam3Active = false, Spam3Delay = 0.1,
    SpamClickActive = false, SpamClickDelay = 0.1
}

-- --- INTERFACE DESIGN ---
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "Genesis_TriMacro_Hub"
sg.ResetOnSpawn = false

local openBtn = Instance.new("TextButton", sg)
openBtn.Size = UDim2.new(0, 130, 0, 40)
openBtn.Position = UDim2.new(0, 15, 0, 15)
openBtn.Visible = false
openBtn.Text = "⚡ OPEN GENESIS"
openBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 460, 0, 470)
main.Position = UDim2.new(0.3, 0, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
main.BorderSizePixel = 0
main.Active, main.Draggable = true, true
local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 12)

local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1, 0, 0, 4)
topBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Instance.new("UICorner", topBar)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(0.5, 0, 0, 40)
title.Position = UDim2.new(0, 15, 0, 5)
title.Text = "GENESIS TRIPLE MACRO"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1

local function createTopBtn(text, x, color)
    local b = Instance.new("TextButton", main)
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, x, 0, 8)
    b.Text, b.BackgroundColor3, b.TextColor3 = text, color, Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end
local closeBtn = createTopBtn("×", -35, Color3.fromRGB(240, 70, 70))
local miniBtn = createTopBtn("−", -70, Color3.fromRGB(45, 45, 55))

miniBtn.MouseButton1Click:Connect(function() main.Visible = false openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() main.Visible = true openBtn.Visible = false end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local leftSection = Instance.new("ScrollingFrame", main)
leftSection.Size = UDim2.new(0.46, 0, 0.85, 0)
leftSection.Position = UDim2.new(0, 15, 0, 55)
leftSection.BackgroundTransparency = 1
leftSection.CanvasSize = UDim2.new(0, 0, 1.2, 0)
leftSection.ScrollBarThickness = 2

local rightSection = Instance.new("ScrollingFrame", main)
rightSection.Size = UDim2.new(0.46, 0, 0.85, 0)
rightSection.Position = UDim2.new(0.52, 0, 0, 55)
rightSection.BackgroundTransparency = 1
rightSection.CanvasSize = UDim2.new(0, 0, 1.7, 0)
rightSection.ScrollBarThickness = 2

local function addLayout(parent)
    local layout = Instance.new("UIListLayout", parent)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
end
addLayout(leftSection)
addLayout(rightSection)

local function createToggleBtn(text, parent, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.95, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(25, 26, 35)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text .. " : OFF"
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    local indicator = Instance.new("Frame", frame)
    indicator.Size = UDim2.new(0, 8, 0, 16)
    indicator.Position = UDim2.new(1, -18, 0.5, -8)
    indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", indicator)
    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = "  " .. text .. (active and " : ON" or " : OFF")
        btn.TextColor3 = active and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 180)
        indicator.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 70)
        callback(active)
    end)
    return frame
end

local function createInput(placeholder, parent, callback)
    local inp = Instance.new("TextBox", parent)
    inp.Size = UDim2.new(0.95, 0, 0, 32)
    inp.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    inp.PlaceholderText = placeholder
    inp.Text = ""
    inp.TextColor3 = Color3.new(1, 1, 1)
    inp.Font = Enum.Font.Gotham
    inp.TextSize = 11
    Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 6)
    inp:GetPropertyChangedSignal("Text"):Connect(function() callback(inp.Text) end)
    return inp
end

local function createKeySelector(label, parent, defaultKey, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.95, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(22, 23, 30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.35, 0, 0.7, 0)
    btn.Position = UDim2.new(0.62, 0, 0.15, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 36, 48)
    btn.Text = defaultKey.Name
    btn.TextColor3 = Color3.fromRGB(0, 170, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local listening = false
    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
    end)
    UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            btn.Text = input.KeyCode.Name
            callback(input.KeyCode)
        end
    end)
end

-- Features UI
createToggleBtn("AIMBOT (LOCK)", leftSection, function(val) Config.Aimbot = val end)
createToggleBtn("WALLHACK ESP", leftSection, function(val) Config.Wallhack = val end)
createToggleBtn("BIG HITBOX", leftSection, function(val) Config.Hitbox = val end)
createToggleBtn("FLY MODE", leftSection, function(val) Config.Fly = val if val then handleFly() end end)
createToggleBtn("GOD MODE", leftSection, function(val) Config.God = val end)
createToggleBtn("NOCLIP", leftSection, function(val) Config.Noclip = val end)
createInput("Tốc độ bay (Mặc định: 50)", leftSection, function(txt) Config.FlyVal = tonumber(txt) or 50 end)

local rstBtn = Instance.new("TextButton", leftSection)
rstBtn.Size = UDim2.new(0.95,0,0,35)
rstBtn.BackgroundColor3 = Color3.fromRGB(120, 35, 35)
rstBtn.Text = "⚡ TỰ TỬ / RESET"
rstBtn.TextColor3 = Color3.new(1,1,1)
rstBtn.Font = Enum.Font.GothamBold
rstBtn.TextSize = 11
Instance.new("UICorner", rstBtn).CornerRadius = UDim.new(0, 6)
rstBtn.MouseButton1Click:Connect(function() if player.Character then player.Character:BreakJoints() end end)

-- LOGIC SPAM TỐI ƯU
local function startSpamLoop(keyEnum, isMouse)
    task.spawn(function()
        while (isMouse and Config.Spam1Active) or (keyEnum == Config.SpamKey2 and Config.Spam2Active) or (keyEnum == Config.SpamKey3 and Config.Spam3Active) do
            local delayTime = isMouse and Config.Spam1Delay or (keyEnum == Config.SpamKey2 and Config.Spam2Delay or Config.Spam3Delay)
            if isMouse then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            else
                VirtualInputManager:SendKeyEvent(true, keyEnum, false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
            end
            task.wait(math.max(0.01, delayTime))
        end
    end)
end

-- SPAM UI
createKeySelector("Spam Phím 1 (Chuột):", rightSection, Config.SpamKey1, function(key) Config.SpamKey1 = key end)
createToggleBtn("KÍCH HOẠT PHÍM 1", rightSection, function(val) Config.Spam1Active = val if val then startSpamLoop(nil, true) end end)
createInput("Delay Phím 1 (s)", rightSection, function(txt) Config.Spam1Delay = tonumber(txt) or 0.1 end)

createKeySelector("Spam Phím 2:", rightSection, Config.SpamKey2, function(key) Config.SpamKey2 = key end)
createToggleBtn("KÍCH HOẠT PHÍM 2", rightSection, function(val) Config.Spam2Active = val if val then startSpamLoop(Config.SpamKey2, false) end end)
createInput("Delay Phím 2 (s)", rightSection, function(txt) Config.Spam2Delay = tonumber(txt) or 0.1 end)

createKeySelector("Spam Phím 3:", rightSection, Config.SpamKey3, function(key) Config.SpamKey3 = key end)
createToggleBtn("KÍCH HOẠT PHÍM 3", rightSection, function(val) Config.Spam3Active = val if val then startSpamLoop(Config.SpamKey3, false) end end)
createInput("Delay Phím 3 (s)", rightSection, function(txt) Config.Spam3Delay = tonumber(txt) or 0.1 end)

createToggleBtn("CONSOLE AFK CLICK", rightSection, function(val)
    Config.SpamClickActive = val
    if val then
        task.spawn(function()
            while Config.SpamClickActive do
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(1e5, 1e5))
                task.wait(Config.SpamClickDelay)
            end
        end)
    end
end)
createInput("Delay Click Chuột (s)", rightSection, function(txt) Config.SpamClickDelay = tonumber(txt) or 0.1 end)

-- Anti AFK
pcall(function()
    player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
    end)
end)

-- CORE LOOPS
local function getTarget()
    if Config.CurrentTarget and Config.CurrentTarget.Parent and Config.CurrentTarget.Parent:FindFirstChild("Humanoid") and Config.CurrentTarget.Parent.Humanoid.Health > 0 then
        local _, onScreen = camera:WorldToViewportPoint(Config.CurrentTarget.Position)
        if onScreen then return Config.CurrentTarget end
    end
    local target, dist = nil, 250
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local pos, on = camera:WorldToViewportPoint(p.Character.Head.Position)
            if on then
                local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                if mag < dist then target = p.Character.Head; dist = mag end
            end
        end
    end
    Config.CurrentTarget = target
    return target
end

RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if Config.Hitbox and hrp then
                hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                hrp.Transparency = 0.7; hrp.CanCollide = false
            elseif hrp and hrp.Size ~= Vector3.new(2,2,1) then
                hrp.Size = Vector3.new(2,2,1); hrp.Transparency = 1; hrp.CanCollide = true
            end
            local esp = p.Character:FindFirstChild("G_ESP")
            if Config.Wallhack then
                if not esp then esp = Instance.new("Highlight", p.Character); esp.Name = "G_ESP"; esp.FillColor = Color3.fromRGB(255, 50, 50) end
            elseif esp then esp:Destroy() end
        end
    end
    if Config.Aimbot then
        local t = getTarget()
        if t then camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, t.Position), 0.15) end
    else Config.CurrentTarget = nil end
    if Config.God and player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.Health = 100 end
end)

function handleFly()
    local char = player.Character
    if not char then return end
    local root = char:WaitForChild("HumanoidRootPart")
    if root:FindFirstChild("G_BV") then root.G_BV:Destroy() end
    if root:FindFirstChild("G_BG") then root.G_BG:Destroy() end
    local bv = Instance.new("BodyVelocity", root)
    local bg = Instance.new("BodyGyro", root)
    bv.Name, bg.Name = "G_BV", "G_BG"
    bv.MaxForce, bg.MaxTorque = Vector3.new(9e9,9e9,9e9), Vector3.new(9e9,9e9,9e9)
    task.spawn(function()
        while Config.Fly and char:FindFirstChild("Humanoid") do
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
            bv.Velocity = dir * Config.FlyVal
            bg.CFrame = camera.CFrame
            task.wait()
        end
        bv:Destroy() bg:Destroy()
    end)
end

RunService.Stepped:Connect(function()
    if Config.Noclip and player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0, 3, 0))
        end
    end
end)
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
