-- Infinity Client with compact toggle
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local FREEZE_START_DISTANCE = 13
local WALL_DISTANCE = 5
local PUSH_OUT_SPEED = 40
local SCAN_RADIUS = FREEZE_START_DISTANCE + 5
local UPDATE_INTERVAL = 0.05

local enabled = false
local elapsed = 0

-- Small toggle UI
local gui = Instance.new("ScreenGui")
gui.Name = "InfinityToggle"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local button = Instance.new("TextButton")
button.Name = "Toggle"
button.Size = UDim2.fromOffset(76, 30)
button.Position = UDim2.new(1, -92, 0.5, -15)
button.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "INFINITY: OFF"
button.TextSize = 11
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = true
button.BorderSizePixel = 0
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(110, 110, 110)
stroke.Thickness = 1
stroke.Parent = button

local function updateButton()
    button.Text = enabled and "INFINITY: ON" or "INFINITY: OFF"
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(30, 135, 85)
        or Color3.fromRGB(55, 55, 55)
end

button.Activated:Connect(function()
    enabled = not enabled
    updateButton()
end)

gui.Parent = player:WaitForChild("PlayerGui")
updateButton()

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.RespectCanCollide = false
overlapParams.MaxParts = 0

local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function updateNearbyParts()
    local character = player.Character
    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    overlapParams.FilterDescendantsInstances = { character }

    local parts = workspace:GetPartBoundsInRadius(
        root.Position,
        SCAN_RADIUS,
        overlapParams
    )

    for _, part in ipairs(parts) do
        if part:IsA("BasePart")
            and not part.Anchored
            and not isCharacterPart(part)
        then
            local offset = part.Position - root.Position
            local distance = offset.Magnitude

            if distance <= WALL_DISTANCE then
                local direction = distance > 0.001
                    and offset / distance
                    or root.CFrame.LookVector

                part.AssemblyLinearVelocity = direction * PUSH_OUT_SPEED

            elseif distance <= FREEZE_START_DISTANCE then
                local factor = math.clamp(
                    (distance - WALL_DISTANCE)
                        / (FREEZE_START_DISTANCE - WALL_DISTANCE),
                    0,
                    1
                )

                part.AssemblyLinearVelocity =
                    part.AssemblyLinearVelocity * factor
            end
        end
    end
end

RunService.Heartbeat:Connect(function(deltaTime)
    if not enabled then
        return
    end

    elapsed += deltaTime
    if elapsed < UPDATE_INTERVAL then
        return
    end

    elapsed = 0
    updateNearbyParts()
end)
