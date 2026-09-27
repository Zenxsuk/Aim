local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local UILibrary = {}

UILibrary.Version = "1.0.0"

local Theme = {
	Background = Color3.fromRGB(18, 18, 22),
	Secondary = Color3.fromRGB(25, 25, 30),
	Tertiary = Color3.fromRGB(32, 32, 39),
	Accent = Color3.fromRGB(90, 120, 255),
	Text = Color3.fromRGB(240, 240, 245),
	Subtext = Color3.fromRGB(160, 160, 170),
	Border = Color3.fromRGB(55, 55, 65),
}

local function Create(className, properties)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	return object
end

local function Round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
	return corner
end

local function Stroke(object, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Parent = object
	return stroke
end

local function GetTextWidth(text, font, size)
	return TextService:GetTextSize(
		text,
		size,
		font,
		Vector2.new(1000, 1000)
	).X
end

function UILibrary:CreateWindow(options)
	options = options or {}

	local Window = {
		Name = options.Name or "UILibrary",
		Title = options.Title or "Window",
		Width = options.Width or 600,
		Height = options.Height or 400,
		Connections = {},
		Tabs = {},
	}

	function Window:Track(connection)
		table.insert(self.Connections, connection)
		return connection
	end

	Window.ScreenGui = Create("ScreenGui", {
		Name = Window.Name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})

	Window.Main = Create("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(Window.Width, Window.Height),
		Position = UDim2.new(
			0.5,
			-Window.Width / 2,
			0.5,
			-Window.Height / 2
		),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = Window.ScreenGui,
	})

	Round(Window.Main, 8)
	Stroke(Window.Main, Theme.Border)

	local Topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0,
		Parent = Window.Main,
	})

	local Title = Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = Window.Title,
		TextColor3 = Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Topbar,
	})

	local TabBar = Create("Frame", {
		Name = "TabBar",
		Position = UDim2.fromOffset(10, 50),
		Size = UDim2.new(1, -20, 0, 34),
		BackgroundTransparency = 1,
		Parent = Window.Main,
	})

	local TabLayout = Instance.new("UIListLayout")
	TabLayout.FillDirection = Enum.FillDirection.Horizontal
	TabLayout.Padding = UDim.new(0, 6)
	TabLayout.Parent = TabBar

	local Pages = Create("Frame", {
		Name = "Pages",
		Position = UDim2.fromOffset(10, 92),
		Size = UDim2.new(1, -20, 1, -102),
		BackgroundTransparency = 1,
		Parent = Window.Main,
	})

	local dragging = false
	local dragStart
	local startPosition

	Window:Track(
		Topbar.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			dragging = true
			dragStart = input.Position
			startPosition = Window.Main.Position
		end)
	)

	Window:Track(
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end

			if input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			local delta = input.Position - dragStart

			Window.Main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end)
	)

	Window:Track(
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	)

	function Window:CreateTab(name)
		local Tab = {
			Name = name,
			Window = self,
			Sections = {},
		}

		local ButtonWidth = math.max(
			70,
			GetTextWidth(name, Enum.Font.GothamMedium, 13) + 28
		)

		Tab.Button = Create("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(ButtonWidth, 34),
			BackgroundColor3 = Theme.Tertiary,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = name,
			TextColor3 = Theme.Subtext,
			TextSize = 13,
			Parent = TabBar,
		})

		Round(Tab.Button, 6)

		Tab.Page = Create("ScrollingFrame", {
			Name = name .. "Page",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = Pages,
		})

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.Padding = UDim.new(0, 8)
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Parent = Tab.Page

		local PagePadding = Instance.new("UIPadding")
		PagePadding.PaddingTop = UDim.new(0, 2)
		PagePadding.PaddingBottom = UDim.new(0, 8)
		PagePadding.PaddingLeft = UDim.new(0, 2)
		PagePadding.PaddingRight = UDim.new(0, 2)
		PagePadding.Parent = Tab.Page

		function Tab:SetActive(active)
			self.Page.Visible = active
			self.Button.BackgroundColor3 =
				active and Theme.Accent or Theme.Tertiary
			self.Button.TextColor3 =
				active and Color3.new(1, 1, 1) or Theme.Subtext
		end

		Window:Track(
			Tab.Button.MouseButton1Click:Connect(function()
				for _, OtherTab in ipairs(Window.Tabs) do
					OtherTab:SetActive(OtherTab == Tab)
				end
			end)
		)

		function Tab:AddSection(name)
			local Section = {
				Name = name,
				Window = Window,
			}

			Section.Frame = Create("Frame", {
				Name = name,
				Size = UDim2.new(1, -4, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Parent = Tab.Page,
			})

			Round(Section.Frame, 7)
			Stroke(Section.Frame, Theme.Border)

			local TitleLabel = Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 8),
				Size = UDim2.new(1, -24, 0, 22),
				Font = Enum.Font.GothamBold,
				Text = name,
				TextColor3 = Theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Section.Frame,
			})

			Section.Holder = Create("Frame", {
				Name = "Holder",
				Position = UDim2.fromOffset(10, 35),
				Size = UDim2.new(1, -20, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = Section.Frame,
			})

			local HolderLayout = Instance.new("UIListLayout")
			HolderLayout.Padding = UDim.new(0, 6)
			HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
			HolderLayout.Parent = Section.Holder

			local HolderPadding = Instance.new("UIPadding")
			HolderPadding.PaddingBottom = UDim.new(0, 10)
			HolderPadding.Parent = Section.Holder

			function Section:AddLabel(text)
				return Create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					Font = Enum.Font.Gotham,
					Text = text,
					TextColor3 = Theme.Subtext,
					TextSize = 12,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Section.Holder,
				})
			end

			function Section:AddToggle(config)
				config = config or {}

				local value = config.Default == true

				local Row = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = Theme.Tertiary,
					BorderSizePixel = 0,
					Parent = Section.Holder,
				})

				Round(Row, 6)

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(1, -85, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = config.Name or "Toggle",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local Button = Create("TextButton", {
					Position = UDim2.new(1, -68, 0.5, -11),
					Size = UDim2.fromOffset(58, 22),
					BackgroundColor3 = value
						and Theme.Accent
						or Theme.Secondary,
					BorderSizePixel = 0,
					Font = Enum.Font.GothamBold,
					Text = value and "ON" or "OFF",
					TextColor3 = Theme.Text,
					TextSize = 10,
					Parent = Row,
				})

				Round(Button, 5)

				local function SetValue(newValue, fireCallback)
					value = newValue
					Button.Text = value and "ON" or "OFF"
					Button.BackgroundColor3 =
						value and Theme.Accent or Theme.Secondary

					if fireCallback ~= false and config.Callback then
						config.Callback(value)
					end
				end

				Window:Track(
					Button.MouseButton1Click:Connect(function()
						SetValue(not value)
					end)
				)

				return {
					SetValue = SetValue,

					GetValue = function()
						return value
					end,
				}
			end

			function Section:AddSlider(config)
				config = config or {}

				local minimum = config.Min or 0
				local maximum = config.Max or 100
				local step = config.Step or 1
				local decimals = config.Decimals or 0
				local value = math.clamp(
					config.Default or minimum,
					minimum,
					maximum
				)

				local Row = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 54),
					BackgroundColor3 = Theme.Tertiary,
					BorderSizePixel = 0,
					Parent = Section.Holder,
				})

				Round(Row, 6)

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 6),
					Size = UDim2.new(1, -100, 0, 18),
					Font = Enum.Font.GothamMedium,
					Text = config.Name or "Slider",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local ValueLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -80, 0, 6),
					Size = UDim2.fromOffset(70, 18),
					Font = Enum.Font.GothamBold,
					TextColor3 = Theme.Subtext,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = Row,
				})

				local TrackFrame = Create("Frame", {
					Position = UDim2.new(0, 10, 1, -19),
					Size = UDim2.new(1, -20, 0, 6),
					BackgroundColor3 = Theme.Secondary,
					BorderSizePixel = 0,
					Parent = Row,
				})

				Round(TrackFrame, 4)

				local Fill = Create("Frame", {
					Size = UDim2.new(),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = TrackFrame,
				})

				Round(Fill, 4)

				local draggingSlider = false

				local function FormatValue(number)
					return string.format(
						"%." .. decimals .. "f",
						number
					)
				end

				local function SetValue(newValue, fireCallback)
					newValue = math.clamp(newValue, minimum, maximum)

					if step > 0 then
						newValue =
							minimum
							+ math.round((newValue - minimum) / step)
								* step
					end

					value = math.clamp(
						newValue,
						minimum,
						maximum
					)

					local percent = 0

					if maximum ~= minimum then
						percent =
							(value - minimum)
							/ (maximum - minimum)
					end

					Fill.Size = UDim2.new(percent, 0, 1, 0)
					ValueLabel.Text = FormatValue(value)

					if fireCallback ~= false and config.Callback then
						config.Callback(value)
					end
				end

				local function UpdateFromX(x)
					local percent = math.clamp(
						(x - TrackFrame.AbsolutePosition.X)
							/ TrackFrame.AbsoluteSize.X,
						0,
						1
					)

					SetValue(
						minimum
							+ (maximum - minimum) * percent
					)
				end

				Window:Track(
					TrackFrame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingSlider = true
							UpdateFromX(input.Position.X)
						end
					end)
				)

				Window:Track(
					UserInputService.InputChanged:Connect(function(input)
						if draggingSlider
							and input.UserInputType
								== Enum.UserInputType.MouseMovement then
							UpdateFromX(input.Position.X)
						end
					end)
				)

				Window:Track(
					UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType
							== Enum.UserInputType.MouseButton1 then
							draggingSlider = false
						end
					end)
				)

				SetValue(value, false)

				return {
					SetValue = SetValue,

					GetValue = function()
						return value
					end,
				}
			end

			function Section:AddDropdown(config)
				config = config or {}

				local values = config.Values or {}
				local current = config.Default or values[1]
				local opened = false

				local Row = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 34),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Theme.Tertiary,
					BorderSizePixel = 0,
					Parent = Section.Holder,
				})

				Round(Row, 6)

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(0.5, -10, 0, 34),
					Font = Enum.Font.GothamMedium,
					Text = config.Name or "Dropdown",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local Select = Create("TextButton", {
					Position = UDim2.new(0.5, 0, 0, 5),
					Size = UDim2.new(0.5, -5, 0, 24),
					BackgroundColor3 = Theme.Secondary,
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					Text = tostring(current),
					TextColor3 = Theme.Text,
					TextSize = 11,
					Parent = Row,
				})

				Round(Select, 5)

				local List = Create("Frame", {
					Position = UDim2.fromOffset(0, 35),
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Visible = false,
					Parent = Row,
				})

				local ListLayout = Instance.new("UIListLayout")
				ListLayout.Padding = UDim.new(0, 4)
				ListLayout.Parent = List

				local function SetValue(newValue, fireCallback)
					current = newValue
					Select.Text = tostring(current)

					if fireCallback ~= false and config.Callback then
						config.Callback(current)
					end
				end

				for _, item in ipairs(values) do
					local Option = Create("TextButton", {
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Theme.Secondary,
						BorderSizePixel = 0,
						Font = Enum.Font.Gotham,
						Text = tostring(item),
						TextColor3 = Theme.Text,
						TextSize = 11,
						Parent = List,
					})

					Round(Option, 5)

					Window:Track(
						Option.MouseButton1Click:Connect(function()
							SetValue(item)
							opened = false
							List.Visible = false
						end)
					)
				end

				Window:Track(
					Select.MouseButton1Click:Connect(function()
						opened = not opened
						List.Visible = opened
					end)
				)

				return {
					SetValue = SetValue,

					GetValue = function()
						return current
					end,
				}
			end

			function Section:AddColorPicker(config)
				config = config or {}

				local value = config.Default or Color3.new(1, 1, 1)

				local Row = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundColor3 = Theme.Tertiary,
					BorderSizePixel = 0,
					Parent = Section.Holder,
				})

				Round(Row, 6)

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(0.5, -10, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = config.Name or "Color",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local Swatch = Create("Frame", {
					Position = UDim2.new(1, -178, 0.5, -11),
					Size = UDim2.fromOffset(22, 22),
					BackgroundColor3 = value,
					BorderSizePixel = 0,
					Parent = Row,
				})

				Round(Swatch, 5)

				local Box = Create("TextBox", {
					Position = UDim2.new(1, -148, 0.5, -12),
					Size = UDim2.fromOffset(138, 24),
					BackgroundColor3 = Theme.Secondary,
					BorderSizePixel = 0,
					ClearTextOnFocus = false,
					Font = Enum.Font.Code,
					PlaceholderText = "#FFFFFF",
					TextColor3 = Theme.Text,
					TextSize = 11,
					Parent = Row,
				})

				Round(Box, 5)

				local function ColorToHex(color)
					return string.format(
						"#%02X%02X%02X",
						math.floor(color.R * 255 + 0.5),
						math.floor(color.G * 255 + 0.5),
						math.floor(color.B * 255 + 0.5)
					)
				end

				local function ParseHex(text)
					text = text:gsub("#", ""):gsub("%s+", "")

					if #text ~= 6 then
						return nil
					end

					local r = tonumber(text:sub(1, 2), 16)
					local g = tonumber(text:sub(3, 4), 16)
					local b = tonumber(text:sub(5, 6), 16)

					if not r or not g or not b then
						return nil
					end

					return Color3.fromRGB(r, g, b)
				end

				local function SetColor(newColor, fireCallback)
					value = newColor
					Swatch.BackgroundColor3 = value
					Box.Text = ColorToHex(value)

					if fireCallback ~= false and config.Callback then
						config.Callback(value)
					end
				end

				Window:Track(
					Box.FocusLost:Connect(function()
						local newColor = ParseHex(Box.Text)

						if newColor then
							SetColor(newColor)
						else
							Box.Text = ColorToHex(value)
						end
					end)
				)

				SetColor(value, false)

				return {
					SetColor = SetColor,

					GetColor = function()
						return value
					end,
				}
			end

			function Section:AddKeybind(config)
				config = config or {}

				local current =
					config.Default or Enum.KeyCode.RightShift

				local listening = false

				local Row = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = Theme.Tertiary,
					BorderSizePixel = 0,
					Parent = Section.Holder,
				})

				Round(Row, 6)

				Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(1, -120, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = config.Name or "Keybind",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local Button = Create("TextButton", {
					Position = UDim2.new(1, -105, 0.5, -12),
					Size = UDim2.fromOffset(95, 24),
					BackgroundColor3 = Theme.Secondary,
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					Text = current.Name,
					TextColor3 = Theme.Text,
					TextSize = 10,
					Parent = Row,
				})

				Round(Button, 5)

				Window:Track(
					Button.MouseButton1Click:Connect(function()
						listening = true
						Button.Text = "Press key..."
					end)
				)

				Window:Track(
					UserInputService.InputBegan:Connect(function(input, processed)
						if processed or not listening then
							return
						end

						if input.KeyCode == Enum.KeyCode.Unknown then
							return
						end

						current = input.KeyCode
						listening = false
						Button.Text = current.Name

						if config.Callback then
							config.Callback(current)
						end
					end)
				)

				return {
					SetValue = function(newValue)
						current = newValue
						Button.Text = current.Name

						if config.Callback then
							config.Callback(current)
						end
					end,

					GetValue = function()
						return current
					end,
				}
			end

			table.insert(Tab.Sections, Section)

			return Section
		end

		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then
			Tab:SetActive(true)
		end

		return Tab
	end

	function Window:Destroy()
		for _, connection in ipairs(self.Connections) do
			if connection.Connected then
				connection:Disconnect()
			end
		end

		table.clear(self.Connections)

		if self.ScreenGui then
			self.ScreenGui:Destroy()
		end
	end

	return Window
end

return UILibrary
