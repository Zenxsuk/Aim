local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local UILibrary = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/UILibrary.lua"
))()

local Config = {
	Enabled = true,

	Smoothness = 0,
	SnapSpeed = 0,
	FOV = 30,
	Range = 300,
	TargetPart = "Head",
	TeamCheck = true,
	WallCheck = true,

	ESPEnabled = true,
	Occluded = true,

	FriendlyColor = Color3.fromRGB(0, 255, 0),
	CTColor = Color3.fromRGB(0, 0, 255),
	TColor = Color3.fromRGB(255, 165, 0),

	FillTransparency = 0.8,
	OutlineTransparency = 0,
}

local Removed = false
local HoldingAim = false

local Connections = {}
local ESPHighlights = {}
local NPCs = {}

local Teams = {
	CT = "CT",
	T = "T",
}

local function Track(connection)
	table.insert(Connections, connection)
	return connection
end

local function GetState(Player, Name)
	local Playerstates = Player:FindFirstChild("Playerstates")

	if not Playerstates then
		return nil
	end

	local State = Playerstates:FindFirstChild(Name)

	if not State then
		return nil
	end

	if State:IsA("ObjectValue") then
		return State.Value and State.Value.Name or nil
	end

	if State:IsA("ValueBase") then
		return State.Value
	end

	return nil
end

local function RemoveESP(Player)
	local Highlight = ESPHighlights[Player]

	if Highlight then
		Highlight:Destroy()
		ESPHighlights[Player] = nil
	end
end

local function GetESPColor(Player)
	local PlayerTeam = GetState(Player, "Team")
	local MyTeam = GetState(player, "Team")

	if PlayerTeam == MyTeam then
		return Config.FriendlyColor
	end

	if PlayerTeam == Teams.CT then
		return Config.CTColor
	end

	if PlayerTeam == Teams.T then
		return Config.TColor
	end

	return nil
end

local function UpdateESP(Player)
	if Removed or Player == player then
		return
	end

	if not Config.ESPEnabled then
		RemoveESP(Player)
		return
	end

	local Character = Player.Character

	if not Character then
		RemoveESP(Player)
		return
	end

	local Alive = GetState(Player, "Alive")

	if Alive ~= true then
		RemoveESP(Player)
		return
	end

	local Color = GetESPColor(Player)

	if not Color then
		RemoveESP(Player)
		return
	end

	local Highlight = ESPHighlights[Player]

	if Highlight and Highlight.Parent ~= Character then
		Highlight:Destroy()
		Highlight = nil
		ESPHighlights[Player] = nil
	end

	if not Highlight then
		Highlight = Instance.new("Highlight")
		Highlight.Name = "Esp"
		Highlight.Parent = Character

		ESPHighlights[Player] = Highlight
	end

	Highlight.FillColor = Color
	Highlight.OutlineColor = Color
	Highlight.FillTransparency = Config.FillTransparency
	Highlight.OutlineTransparency = Config.OutlineTransparency

	Highlight.DepthMode =
		Config.Occluded
		and Enum.HighlightDepthMode.Occluded
		or Enum.HighlightDepthMode.AlwaysOnTop
end

local function UpdateAllESP()
	if Removed then
		return
	end

	for _, Player in ipairs(Players:GetPlayers()) do
		UpdateESP(Player)
	end
end

local function SetupPlayer(Player)
	if Player == player then
		return
	end

	Track(
		Player.CharacterAdded:Connect(function()
			task.defer(UpdateESP, Player)
		end)
	)

	local Playerstates = Player:FindFirstChild("Playerstates")

	if Playerstates then
		local Alive = Playerstates:FindFirstChild("Alive")
		local Team = Playerstates:FindFirstChild("Team")

		if Alive then
			Track(
				Alive.Changed:Connect(function()
					UpdateESP(Player)
				end)
			)
		end

		if Team then
			Track(
				Team.Changed:Connect(function()
					UpdateESP(Player)
				end)
			)
		end
	end

	UpdateESP(Player)
end

for _, Instance in ipairs(workspace:GetDescendants()) do
	if Instance:IsA("Humanoid")
		and Instance.Parent
		and Instance.Parent:IsA("Model") then
		NPCs[Instance.Parent] = true
	end
end

Track(
	workspace.DescendantAdded:Connect(function(Instance)
		if Instance:IsA("Humanoid")
			and Instance.Parent
			and Instance.Parent:IsA("Model") then
			NPCs[Instance.Parent] = true
		end
	end)
)

Track(
	workspace.DescendantRemoving:Connect(function(Instance)
		if Instance:IsA("Model") then
			NPCs[Instance] = nil
		end
	end)
)

local Window = UILibrary:CreateWindow({
	Name = "AmbotUI",
	Title = "Ambot",
	Width = 620,
	Height = 430,
})

local AimTab = Window:CreateTab("Aim")
local TargetTab = Window:CreateTab("Targeting")
local VisualTab = Window:CreateTab("Visuals")

local AimSection = AimTab:AddSection("Aim Settings")

AimSection:AddToggle({
	Name = "Enabled",
	Default = Config.Enabled,

	Callback = function(value)
		Config.Enabled = value
	end,
})

AimSection:AddSlider({
	Name = "Smoothness",
	Min = 0,
	Max = 1,
	Default = Config.Smoothness,
	Step = 0.01,
	Decimals = 2,

	Callback = function(value)
		Config.Smoothness = value
	end,
})

AimSection:AddSlider({
	Name = "Snap Speed",
	Min = 0,
	Max = 1,
	Default = Config.SnapSpeed,
	Step = 0.01,
	Decimals = 2,

	Callback = function(value)
		Config.SnapSpeed = value
	end,
})

AimSection:AddSlider({
	Name = "FOV",
	Min = 1,
	Max = 180,
	Default = Config.FOV,
	Step = 1,
	Decimals = 0,

	Callback = function(value)
		Config.FOV = value
	end,
})

local TargetSection = TargetTab:AddSection("Target Settings")

TargetSection:AddDropdown({
	Name = "Target Part",

	Values = {
		"Head",
		"HumanoidRootPart",
		"UpperTorso",
		"LowerTorso",
	},

	Default = Config.TargetPart,

	Callback = function(value)
		Config.TargetPart = value
	end,
})

TargetSection:AddSlider({
	Name = "Range",
	Min = 25,
	Max = 1000,
	Default = Config.Range,
	Step = 5,
	Decimals = 0,

	Callback = function(value)
		Config.Range = value
	end,
})

TargetSection:AddToggle({
	Name = "Team Check",
	Default = Config.TeamCheck,

	Callback = function(value)
		Config.TeamCheck = value
	end,
})

TargetSection:AddToggle({
	Name = "Wall Check",
	Default = Config.WallCheck,

	Callback = function(value)
		Config.WallCheck = value
	end,
})

local FOVSection = VisualTab:AddSection("FOV")

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = Window.ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 1.5
CircleStroke.Color = Color3.fromRGB(90, 120, 255)
CircleStroke.Parent = FOVCircle

FOVSection:AddToggle({
	Name = "Show FOV",
	Default = true,

	Callback = function(value)
		FOVCircle.Visible = value
	end,
})

local ESPSection = VisualTab:AddSection("ESP")

ESPSection:AddToggle({
	Name = "ESP",
	Default = Config.ESPEnabled,

	Callback = function(value)
		Config.ESPEnabled = value
		UpdateAllESP()
	end,
})

ESPSection:AddToggle({
	Name = "Occluded",
	Default = Config.Occluded,

	Callback = function(value)
		Config.Occluded = value
		UpdateAllESP()
	end,
})

ESPSection:AddColorPicker({
	Name = "Friendly Color",
	Default = Config.FriendlyColor,

	Callback = function(value)
		Config.FriendlyColor = value
		UpdateAllESP()
	end,
})

ESPSection:AddColorPicker({
	Name = "CT Color",
	Default = Config.CTColor,

	Callback = function(value)
		Config.CTColor = value
		UpdateAllESP()
	end,
})

ESPSection:AddColorPicker({
	Name = "T Color",
	Default = Config.TColor,

	Callback = function(value)
		Config.TColor = value
		UpdateAllESP()
	end,
})

ESPSection:AddSlider({
	Name = "Fill Transparency",
	Min = 0,
	Max = 1,
	Default = Config.FillTransparency,
	Step = 0.01,
	Decimals = 2,

	Callback = function(value)
		Config.FillTransparency = value
		UpdateAllESP()
	end,
})

ESPSection:AddSlider({
	Name = "Outline Transparency",
	Min = 0,
	Max = 1,
	Default = Config.OutlineTransparency,
	Step = 0.01,
	Decimals = 2,

	Callback = function(value)
		Config.OutlineTransparency = value
		UpdateAllESP()
	end,
})

local function UpdateFOVCircle()
	local Viewport = Camera.ViewportSize

	if Viewport.Y <= 0 then
		return
	end

	local CameraFOV = math.max(Camera.FieldOfView, 1)

	local Radius =
		math.tan(math.rad(Config.FOV / 2))
		/ math.tan(math.rad(CameraFOV / 2))
		* (Viewport.Y / 2)

	FOVCircle.Size = UDim2.fromOffset(
		Radius * 2,
		Radius * 2
	)
end

local function IsValidCharacter(Character)
	if not Character or not Character:IsA("Model") then
		return false
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	return Humanoid and Humanoid.Health > 0
end

local function IsValidPlayerTarget(Player, Character)
	if Player == player then
		return false
	end

	if not IsValidCharacter(Character) then
		return false
	end

	local Alive = GetState(Player, "Alive")

	if Alive ~= true then
		return false
	end

	if Config.TeamCheck then
		local MyTeam = GetState(player, "Team")
		local TargetTeam = GetState(Player, "Team")

		if MyTeam and TargetTeam and MyTeam == TargetTeam then
			return false
		end
	end

	return true
end

local function HasLineOfSight(Character, TargetPart)
	if not Config.WallCheck then
		return true
	end

	local Origin = Camera.CFrame.Position
	local Direction = TargetPart.Position - Origin

	local Parameters = RaycastParams.new()

	Parameters.FilterType = Enum.RaycastFilterType.Exclude
	Parameters.FilterDescendantsInstances = {
		player.Character,
	}

	local Result = workspace:Raycast(
		Origin,
		Direction,
		Parameters
	)

	if not Result then
		return true
	end

	return Result.Instance:IsDescendantOf(Character)
end

local function GetTarget()
	local CameraPosition = Camera.CFrame.Position
	local CameraLook = Camera.CFrame.LookVector

	local BestTarget
	local BestAngle = math.huge
	local Checked = {}

	for _, Player in ipairs(Players:GetPlayers()) do
		local Character = Player.Character

		if IsValidPlayerTarget(Player, Character) then
			Checked[Character] = true

			local TargetPart =
				Character:FindFirstChild(Config.TargetPart)

			if TargetPart and TargetPart:IsA("BasePart") then
				local Offset =
					TargetPart.Position - CameraPosition

				local Distance = Offset.Magnitude

				if Distance <= Config.Range then
					local Direction = Offset.Unit

					local Dot = math.clamp(
						CameraLook:Dot(Direction),
						-1,
						1
					)

					local Angle =
						math.deg(math.acos(Dot))

					if Angle <= Config.FOV / 2
						and Angle < BestAngle
						and HasLineOfSight(
							Character,
							TargetPart
						) then

						BestAngle = Angle
						BestTarget = TargetPart
					end
				end
			end
		end
	end

	for Character in pairs(NPCs) do
		if Character.Parent
			and not Checked[Character]
			and IsValidCharacter(Character) then

			local TargetPart =
				Character:FindFirstChild(Config.TargetPart)

			if TargetPart and TargetPart:IsA("BasePart") then
				local Offset =
					TargetPart.Position - CameraPosition

				local Distance = Offset.Magnitude

				if Distance <= Config.Range then
					local Direction = Offset.Unit

					local Dot = math.clamp(
						CameraLook:Dot(Direction),
						-1,
						1
					)

					local Angle =
						math.deg(math.acos(Dot))

					if Angle <= Config.FOV / 2
						and Angle < BestAngle
						and HasLineOfSight(
							Character,
							TargetPart
						) then

						BestAngle = Angle
						BestTarget = TargetPart
					end
				end
			end
		end
	end

	return BestTarget
end

local function AimAt(TargetPart, dt)
	if not TargetPart or not TargetPart.Parent then
		return
	end

	local Desired = CFrame.lookAt(
		Camera.CFrame.Position,
		TargetPart.Position
	)

	if Config.Smoothness == 0
		and Config.SnapSpeed == 0 then

		Camera.CFrame = Desired
		return
	end

	local Speed =
		120 / (1 + Config.SnapSpeed * 29)

	local Alpha =
		1 - math.exp(-Speed * dt)

	Alpha =
		Alpha ^ (1 + Config.Smoothness * 3)

	Alpha = math.clamp(Alpha, 0, 1)

	Camera.CFrame =
		Camera.CFrame:Lerp(
			Desired,
			Alpha
		)
end

local function Cleanup()
	if Removed then
		return
	end

	Removed = true
	HoldingAim = false

	for Player in pairs(ESPHighlights) do
		RemoveESP(Player)
	end

	table.clear(ESPHighlights)
	table.clear(NPCs)

	for _, Connection in ipairs(Connections) do
		if Connection.Connected then
			Connection:Disconnect()
		end
	end

	table.clear(Connections)

	if FOVCircle then
		FOVCircle:Destroy()
	end

	if Window then
		Window:Destroy()
	end

	script:Destroy()
end

for _, Player in ipairs(Players:GetPlayers()) do
	SetupPlayer(Player)
end

Track(
	Players.PlayerAdded:Connect(SetupPlayer)
)

local MyPlayerstates = player:FindFirstChild("Playerstates")

if MyPlayerstates then
	local MyTeam = MyPlayerstates:FindFirstChild("Team")

	if MyTeam then
		Track(
			MyTeam.Changed:Connect(UpdateAllESP)
		)
	end
end

Track(
	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed or Removed then
			return
		end

		if Input.UserInputType
			== Enum.UserInputType.MouseButton2 then

			HoldingAim = true
		end

		if Input.KeyCode == Enum.KeyCode.O then
			Config.ESPEnabled = true
			Config.Occluded = true
			UpdateAllESP()
		elseif Input.KeyCode == Enum.KeyCode.I then
			Config.ESPEnabled = true
			Config.Occluded = false
			UpdateAllESP()
		elseif Input.KeyCode == Enum.KeyCode.P then
			Config.ESPEnabled = false
			UpdateAllESP()
		elseif Input.KeyCode == Enum.KeyCode.Insert then
			Window.ScreenGui.Enabled =
				not Window.ScreenGui.Enabled
		elseif Input.KeyCode == Enum.KeyCode.Delete then
			Cleanup()
		end
	end)
)

Track(
	UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType
			== Enum.UserInputType.MouseButton2 then

			HoldingAim = false
		end
	end)
)

Track(
	RunService.RenderStepped:Connect(function(dt)
		if Removed then
			return
		end

		UpdateFOVCircle()

		if not Config.Enabled or not HoldingAim then
			return
		end

		local Target = GetTarget()

		if Target then
			AimAt(Target, dt)
		end
	end)
)

UpdateAllESP()
UpdateFOVCircle()
