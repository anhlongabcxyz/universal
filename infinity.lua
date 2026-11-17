-- Infinity + PartClaim: one shared ON/OFF toggle
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local enabled = true

-- Small draggable toggle UI (executor UI container when available, PlayerGui fallback)
local guiParent
pcall(function()
    if typeof(gethui) == "function" then
        guiParent = gethui()
    end
end)
if not guiParent then
    guiParent = player:WaitForChild("PlayerGui")
end

local oldGui = guiParent:FindFirstChild("InfinityToggleGui")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "InfinityToggleGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
        syn.protect_gui(gui)
    end
end)

gui.Parent = guiParent

local button = Instance.new("TextButton")
button.Name = "ToggleButton"
button.Size = UDim2.fromOffset(132, 38)
button.Position = UDim2.new(0, 18, 0.5, -17)
button.BackgroundColor3 = Color3.fromRGB(238, 240, 245)
button.TextColor3 = Color3.fromRGB(15, 15, 15)
button.Text = "VÔ HẠN HẠN: ON"
button.TextSize = 12
button.Font = Enum.Font.GothamSemibold
button.BorderSizePixel = 0
button.AutoButtonColor = true
button.TextWrapped = false
button.TextXAlignment = Enum.TextXAlignment.Center
button.TextYAlignment = Enum.TextYAlignment.Center
button.TextStrokeTransparency = 0.9
button.Active = true
button.Draggable = true
button.ZIndex = 20
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(20, 20, 20)
stroke.Thickness = 1.2
stroke.Parent = button

local function updateButton()
    button.Text = enabled and "VÔ HẠN HẠN: ON" or "VÔ HẠN HẠN: OFF"
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(238, 240, 245)
        or Color3.fromRGB(18, 18, 18)
    button.TextColor3 = enabled
        and Color3.fromRGB(15, 15, 15)
        or Color3.fromRGB(245, 245, 245)
    stroke.Color = enabled and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(245, 245, 245)
end

-- PartClaim setup
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local targetFolder = Instance.new("Folder")
targetFolder.Name = "PartClaimFolder"
targetFolder.Parent = Workspace

local targetPart = Instance.new("Part")
targetPart.Name = "PartClaimTarget"
targetPart.Anchored = true
targetPart.CanCollide = false
targetPart.Transparency = 1
targetPart.Parent = targetFolder

local attachment1 = Instance.new("Attachment")
attachment1.Parent = targetPart

local Network = getgenv().Network
if not Network then
    Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }
    getgenv().Network = Network
end
Network.BaseParts = Network.BaseParts or {}
Network.Velocity = Network.Velocity or Vector3.new(14.46262424, 14.46262424, 14.46262424)

Network.RetainPart = function(part)
    if typeof(part) == "Instance" and part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
        table.insert(Network.BaseParts, part)
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        part.CanCollide = false
    end
end

player.ReplicationFocus = Workspace
local partClaimConnection = RunService.Heartbeat:Connect(function()
    if not enabled then return end
    sethiddenproperty(player, "SimulationRadius", math.huge)
    for _, part in pairs(Network.BaseParts) do
        if part and part:IsDescendantOf(Workspace) then
            part.Velocity = Network.Velocity
        end
    end
end)

local function ForcePart(v)
    if not enabled then return end
    if v:IsA("Part") and not v.Anchored
        and v.Parent
        and not v.Parent:FindFirstChild("Humanoid")
        and not v.Parent:FindFirstChild("Head")
        and v.Name ~= "Handle" then

        for _, x in next, v:GetChildren() do
            if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce")
                or x:IsA("BodyGyro") or x:IsA("BodyPosition")
                or x:IsA("BodyThrust") or x:IsA("BodyVelocity")
                or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end

        for _, name in ipairs({"Attachment", "AlignPosition", "Torque"}) do
            local existing = v:FindFirstChild(name)
            if existing then existing:Destroy() end
        end

        v.CanCollide = false
        local torque = Instance.new("Torque")
        torque.Torque = Vector3.new(100000, 100000, 100000)
        torque.Parent = v

        local attachment2 = Instance.new("Attachment")
        attachment2.Parent = v
        torque.Attachment0 = attachment2

        local alignPosition = Instance.new("AlignPosition")
        alignPosition.MaxForce = 9999999999999999
        alignPosition.MaxVelocity = math.huge
        alignPosition.Responsiveness = 200
        alignPosition.Attachment0 = attachment2
        alignPosition.Attachment1 = attachment1
        alignPosition.Parent = v
    end
end
getgenv().PartClaimForcePart = ForcePart

-- Sound and red fire aura (both follow the character and shared toggle)
local soundId = "rbxassetid://122261039674349"
local sound

local auraEmitters = {}

local function removeAura()
    for _, effect in ipairs(auraEmitters) do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end
    table.clear(auraEmitters)
end

-- Smooth red aura wrapped around the character; no particle emitters.
local function createAura(char)
    removeAura()

    local highlight = Instance.new("Highlight")
    highlight.Name = "RedBodyAura"
    highlight.Adornee = char
    highlight.FillColor = Color3.fromRGB(220, 0, 18)
    highlight.OutlineColor = Color3.fromRGB(255, 35, 45)
    highlight.FillTransparency = 0.68
    highlight.OutlineTransparency = 0.12
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = enabled
    highlight.Parent = char

    table.insert(auraEmitters, highlight)
end

local function setupCharacter(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 8)
    if not root then return end

    if sound then
        sound:Stop()
        sound:Destroy()
    end
    sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Name = "CustomSound"
    sound.Volume = 4
    sound.PlaybackSpeed = 1
    sound.TimePosition = 0
    sound.Parent = root
    if enabled then sound:Play() end

    createAura(char)
end

setupCharacter(character)

-- Infinity settings and loop
local FREEZE_START_DISTANCE = 13
local WALL_DISTANCE = 5
local PUSH_FORCE = 100000
local PUSH_OUT_SPEED = 40

local function getNearbyUnanchoredParts(centerPos, range)
    local region = Region3.new(
        centerPos - Vector3.new(range, range, range),
        centerPos + Vector3.new(range, range, range)
    )
    local parts = Workspace:FindPartsInRegion3WithIgnoreList(region, {player.Character}, math.huge)
    local valid = {}
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and not part.Anchored
            and player.Character and not part:IsDescendantOf(player.Character) then
            table.insert(valid, part)
        end
    end
    return valid
end

local infinityConnection = RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local currentCharacter = player.Character
    if not currentCharacter then return end
    local root = currentCharacter:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local playerPos = root.Position
    local parts = getNearbyUnanchoredParts(playerPos, FREEZE_START_DISTANCE + 5)

    for _, part in ipairs(parts) do
        local offset = part.Position - playerPos
        local distance = offset.Magnitude
        local velocityControl = part:FindFirstChild("RepelForce")

        if not velocityControl then
            velocityControl = Instance.new("BodyVelocity")
            velocityControl.Name = "RepelForce"
            velocityControl.MaxForce = Vector3.new(PUSH_FORCE, PUSH_FORCE, PUSH_FORCE)
            velocityControl.P = 10000
            velocityControl.Parent = part
        end

        if distance <= WALL_DISTANCE then
            if distance > 0 then
                velocityControl.Velocity = offset.Unit * PUSH_OUT_SPEED
            end
        elseif distance <= FREEZE_START_DISTANCE then
            local currentVelocity = part.AssemblyLinearVelocity
            local factor = math.clamp(
                (distance - WALL_DISTANCE) / (FREEZE_START_DISTANCE - WALL_DISTANCE),
                0, 1
            )
            velocityControl.Velocity = currentVelocity * factor
        elseif velocityControl then
            velocityControl:Destroy()
        end
    end
end)

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    updateButton()

    if enabled then
        if sound and sound.Parent and not sound.IsPlaying then sound:Play() end
    else
        if sound and sound.IsPlaying then sound:Stop() end
    end

    for _, effect in ipairs(auraEmitters) do
        if effect and effect:IsA("Highlight") then
            effect.Enabled = enabled
        end
    end
end)

updateButton()

-- Rebuild sound and aura after respawn; keep the toggle UI alive.
player.CharacterAdded:Connect(function(char)
    task.wait(0.25)
    setupCharacter(char)
end)
