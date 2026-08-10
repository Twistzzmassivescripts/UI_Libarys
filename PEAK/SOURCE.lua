-- what are you skidding budd !!!

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local input = UserInputService
local inset = GuiService:GetGuiInset()
local EmptyFunction = function() end
local uiFont = Enum.Font.SourceSansBold

local util = {}
do
    function util.new(instanceType, options, children)
        local instance = Instance.new(instanceType)
        if instance:IsA("GuiObject") then instance.BorderSizePixel = 0 end
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            instance.TextXAlignment = Enum.TextXAlignment.Left
            instance.TextYAlignment = Enum.TextYAlignment.Center
            instance.Font = uiFont
        end
        if instance:IsA("TextButton") or instance:IsA("ImageButton") then
            instance.AutoButtonColor = false
            if instance:IsA("TextButton") then instance.Text = "" end
        end
        for i, v in pairs(options) do instance[i] = v end
        if not children then return instance end
        for _, v in pairs(children) do v.Parent = instance end
        return instance
    end

    function util.tween(instance, properties, duration, style, direction)
        TweenService:Create(instance, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out), properties):Play()
    end

    function util.corner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 6)
        c.Parent = parent
        return c
    end

    function util.stroke(parent, color, thickness)
        local s = Instance.new("UIStroke")
        s.Color = color or Color3.fromRGB(38, 38, 48)
        s.Thickness = thickness or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = parent
        return s
    end

    function util.gradient(parent, color1, color2, rotation)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color1 or Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, color2 or Color3.fromRGB(0, 0, 0)),
        })
        g.Rotation = rotation or 90
        g.Parent = parent
        return g
    end
end

local theme = {
    Background     = Color3.fromRGB(8, 10, 16),
    TopBar         = Color3.fromRGB(13, 18, 28),
    Sidebar        = Color3.fromRGB(11, 14, 21),
    Panel          = Color3.fromRGB(15, 19, 29),
    ElementBg      = Color3.fromRGB(21, 26, 36),
    ElementOutline = Color3.fromRGB(39, 47, 63),

    Accent         = Color3.fromRGB(72, 162, 255),
    AccentHover    = Color3.fromRGB(96, 174, 255),

    Text           = Color3.fromRGB(245, 247, 250),
    SubText        = Color3.fromRGB(154, 164, 180),

    Border         = Color3.fromRGB(33, 41, 56),
}

local library = { values = {} }
library.__index = library
local tab = {}
tab.__index = tab
local panel = {}
panel.__index = panel
local interactable = {}
interactable.__index = interactable

do
    function library.init(title, version, id, position, size)
        position = position or UDim2.new(0.2, 0, 0.2, 0)
        size = size or UDim2.new(0, 700, 0, 430)

        local preexisting = getgenv()[id]
        if preexisting then
            for _, v in pairs(preexisting.connections) do v:Disconnect() end
            preexisting.GUI:Destroy()
        end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = id
        ScreenGui.Parent = CoreGui
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local MasterContainer = util.new("Frame", {
            Parent = ScreenGui,
            Size = size,
            Position = position,
            BackgroundColor3 = theme.Background,
            ClipsDescendants = true,
            Name = "MasterContainer",
        })
        util.corner(MasterContainer, 10)
        util.stroke(MasterContainer, theme.Border, 1)

        local connections = {}
        getgenv()[id] = { connections = connections, GUI = ScreenGui }

        local TopBar = util.new("Frame", {
            Parent = MasterContainer,
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = theme.TopBar,
            Name = "TopBar",
            ZIndex = 2,
        })
        util.stroke(TopBar, theme.Border, 1)
        util.gradient(TopBar, Color3.fromRGB(28, 37, 52), Color3.fromRGB(13, 18, 28), 90)

        local TopAccent = util.new("Frame", {
            Parent = TopBar,
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = theme.Accent,
            ZIndex = 3,
        })

        local TitleLogo = util.new("Frame", {
            Parent = TopBar,
            Size = UDim2.new(0, 8, 0, 8),
            Position = UDim2.new(0, 16, 0.5, -4),
            BackgroundColor3 = theme.Accent,
            ZIndex = 3,
        })
        util.corner(TitleLogo, 4)

        util.new("TextLabel", {
            Parent = TopBar,
            Text = title,
            TextColor3 = theme.Text,
            TextSize = 13,
            Font = uiFont,
            Position = UDim2.new(0, 32, 0, 0),
            Size = UDim2.new(0, 150, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 3,
        })

        util.new("TextLabel", {
            Parent = TopBar,
            Text = version,
            TextColor3 = theme.SubText,
            TextSize = 11,
            Font = uiFont,
            Position = UDim2.new(1, -70, 0, 0),
            Size = UDim2.new(0, 56, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 3,
        })

        local TipBar = util.new("TextLabel", {
            Parent = MasterContainer,
            Size = UDim2.new(1, -30, 0, 16),
            Position = UDim2.new(0, 16, 1, -22),
            ZIndex = 50,
            TextColor3 = theme.SubText,
            Font = uiFont,
            TextSize = 10,
            BackgroundTransparency = 1,
        })

        local ContentContainer = util.new("Frame", {
            Parent = MasterContainer,
            Size = UDim2.new(1, 0, 1, -40),
            Position = UDim2.new(0, 0, 0, 40),
            BackgroundTransparency = 1,
        })

        local TabSelectContainer = util.new("Frame", {
            Parent = ContentContainer,
            Size = UDim2.new(0, 150, 1, -28),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = theme.Sidebar,
        }, {
            util.new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),
            util.new("UIPadding", {
                PaddingTop = UDim.new(0, 6)
            })
        })
        util.corner(TabSelectContainer, 8)
        util.stroke(TabSelectContainer, theme.Border, 1)

        local TabContentContainer = util.new("Frame", {
            Parent = ContentContainer,
            Size = UDim2.new(1, -180, 1, -28),
            Position = UDim2.new(0, 170, 0, 10),
            BackgroundTransparency = 1,
        })

        local isDragging = false
        local draggingOffset

        table.insert(connections, input.InputBegan:Connect(function(inp, gpe)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and not gpe then
                local mouse = input:GetMouseLocation() - inset
                local topLeft = MasterContainer.AbsolutePosition
                local bottomRight = topLeft + Vector2.new(MasterContainer.AbsoluteSize.X, 40)
                if mouse.X > topLeft.X and mouse.X < bottomRight.X and mouse.Y > topLeft.Y and mouse.Y < bottomRight.Y then
                    isDragging = true
                    draggingOffset = mouse - topLeft
                end
            end
        end))
        table.insert(connections, input.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
        end))
        table.insert(connections, input.InputChanged:Connect(function(inp)
            if isDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local guiPos = input:GetMouseLocation() - draggingOffset - inset
                MasterContainer.Position = UDim2.new(0, guiPos.X, 0, guiPos.Y)
            end
        end))

        local self = setmetatable({
            _connections = connections,
            size = size,
            keybind = Enum.KeyCode.RightControl,
            visible = true,
            tabs = {},
            MasterContainer = MasterContainer,
            ContentContainer = ContentContainer,
            TabSelectContainer = TabSelectContainer,
            TabContentContainer = TabContentContainer,
            TipBar = TipBar,
        }, library)

        table.insert(connections, input.InputBegan:Connect(function(inp, gpe)
            if inp.UserInputType == Enum.UserInputType.Keyboard and not gpe and inp.KeyCode == self.keybind then
                self.visible = not self.visible
                MasterContainer.Visible = self.visible
            end
        end))

        return self
    end

    function library:AddTab(title, desc)
        local newTab = tab.new(self, title, desc, #self.tabs + 1)
        table.insert(self.tabs, newTab)
        if #self.tabs == 1 then newTab:select() end
        return unpack(newTab.panels)
    end
end

do
    function tab.new(lib, title, desc, id)
        local TabButton = util.new("TextButton", {
            Parent = lib.TabSelectContainer,
            Size = UDim2.new(1, -12, 0, 36),
            BackgroundColor3 = theme.Sidebar,
            LayoutOrder = id,
        })
        util.corner(TabButton, 6)

        local ActiveIndicator = util.new("Frame", {
            Parent = TabButton,
            Size = UDim2.new(0, 3, 0.55, 0),
            Position = UDim2.new(0, 0, 0.225, 0),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 1,
        })
        util.corner(ActiveIndicator, 2)

        util.new("TextLabel", {
            Parent = TabButton,
            Text = title,
            TextColor3 = theme.SubText,
            TextSize = 12,
            Font = uiFont,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -12, 1, 0),
            BackgroundTransparency = 1,
        })

        local panels = {}
        local self = setmetatable({
            library = lib,
            title = title,
            selected = false,
            panels = panels,
            TabButton = TabButton,
            ActiveIndicator = ActiveIndicator,
        }, tab)

        panels[1] = panel.new(self, {
            Parent = lib.TabContentContainer,
            Size = UDim2.new(0.5, -6, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = theme.Panel,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.Accent,
            Visible = false,
        }, 1)
        util.corner(panels[1].PanelContainer, 8)
        util.stroke(panels[1].PanelContainer, theme.Border, 1)

        panels[2] = panel.new(self, {
            Parent = lib.TabContentContainer,
            Size = UDim2.new(0.5, -6, 1, 0),
            Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundColor3 = theme.Panel,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.Accent,
            Visible = false,
        }, 2)
        util.corner(panels[2].PanelContainer, 8)
        util.stroke(panels[2].PanelContainer, theme.Border, 1)

        TabButton.MouseButton1Down:Connect(function() self:select() end)
        TabButton.MouseEnter:Connect(function()
            if not self.selected then util.tween(TabButton, { BackgroundColor3 = theme.ElementBg }, 0.15) end
        end)
        TabButton.MouseLeave:Connect(function()
            if not self.selected then util.tween(TabButton, { BackgroundColor3 = theme.Sidebar }, 0.15) end
        end)

        return self
    end

    function tab:_deselectOthers()
        for _, t in pairs(self.library.tabs) do
            if t ~= self then t:deselect() end
        end
    end

    function tab:select()
        self.selected = true
        self:_deselectOthers()
        util.tween(self.TabButton, { BackgroundColor3 = theme.ElementBg }, 0.15)
        util.tween(self.TabButton:FindFirstChildOfClass("TextLabel"), { TextColor3 = theme.Text }, 0.15)
        util.tween(self.ActiveIndicator, { BackgroundTransparency = 0 }, 0.15)
        for _, v in pairs(self.panels) do v.PanelContainer.Visible = true end
    end

    function tab:deselect()
        self.selected = false
        util.tween(self.TabButton, { BackgroundColor3 = theme.Sidebar }, 0.15)
        util.tween(self.TabButton:FindFirstChildOfClass("TextLabel"), { TextColor3 = theme.SubText }, 0.15)
        util.tween(self.ActiveIndicator, { BackgroundTransparency = 1 }, 0.15)
        for _, v in pairs(self.panels) do v.PanelContainer.Visible = false end
    end
end

do
    function interactable.new() return setmetatable({}, interactable) end
end

do
    function panel.new(tab, panelProperties, id)
        local PanelContainer = util.new("ScrollingFrame", panelProperties, {
            util.new("UIListLayout", {
                VerticalAlignment = Enum.VerticalAlignment.Top,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            util.new("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            })
        })

        return setmetatable({
            tab = tab,
            PanelContainer = PanelContainer,
            id = id,
            seperators = {},
        }, panel)
    end

    function panel:SetTip(tipText)
        self.tab.library.TipBar.Text = tipText
    end

    function panel:_GlobalTable()
        local values = self.tab.library.values
        local t, p, s = self.tab.title, self.id, self.currentSeperator or "Default"
        if not values[t] then values[t] = {} end
        if not values[t][p] then values[t][p] = {} end
        if not values[t][p][s] then values[t][p][s] = {} end
        return values[t][p][s]
    end

    function panel:_Container(height, clickable)
        return util.new(clickable and "TextButton" or "Frame", {
            Parent = self.PanelContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, height),
            LayoutOrder = #self.PanelContainer:GetChildren(),
        })
    end

    function panel:AddSeperator(text)
        self.seperators[text] = {}
        self.currentSeperator = text
        local Container = self:_Container(20)

        util.new("TextLabel", {
            Parent = Container,
            Text = string.upper(text),
            TextColor3 = theme.SubText,
            TextSize = 10,
            Font = uiFont,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 2, 0, 0),
            BackgroundTransparency = 1,
        })
        return self
    end

    function panel:AddLabel(title, valueText)
        local Container = self:_Container(36, false)
        local Bg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.ElementBg })
        util.corner(Bg, 8)
        util.stroke(Bg, theme.ElementOutline, 1)

        util.new("TextLabel", {
            Parent = Container,
            Text = title,
            TextColor3 = theme.Text,
            TextSize = 11,
            Font = uiFont,
            Size = UDim2.new(0.6, 0, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
        })
        util.new("TextLabel", {
            Parent = Container,
            Text = tostring(valueText),
            TextColor3 = theme.SubText,
            TextSize = 11,
            Font = uiFont,
            Size = UDim2.new(0.4, -10, 1, 0),
            Position = UDim2.new(0.6, 0, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
    end

    function panel.AddToggle(panel, data)
        local callback = data.callback or EmptyFunction
        local self = interactable.new()
        self.checked = data.checked or false
        local text = data.title
        local value = panel:_GlobalTable()
        value[text] = self.checked

        local Container = panel:_Container(38, true)
        local Bg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.ElementBg })
        util.corner(Bg, 8)
        util.stroke(Bg, theme.ElementOutline, 1)

        local SwitchBg = util.new("Frame", { Parent = Container, Size = UDim2.new(0, 32, 0, 16), Position = UDim2.new(1, -40, 0.5, -8), BackgroundColor3 = theme.ElementOutline })
        util.corner(SwitchBg, 8)

        local Knob = util.new("Frame", { Parent = SwitchBg, Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = theme.SubText })
        util.corner(Knob, 6)

        util.new("TextLabel", { Parent = Container, Text = text, TextColor3 = theme.Text, TextSize = 11, Font = uiFont, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1 })

        local function render(override)
            if self.checked then
                util.tween(SwitchBg, { BackgroundColor3 = theme.Accent }, 0.15)
                util.tween(Knob, { Position = UDim2.new(0, 18, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
            else
                util.tween(SwitchBg, { BackgroundColor3 = theme.ElementOutline }, 0.15)
                util.tween(Knob, { Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = theme.SubText }, 0.15)
            end
            value[text] = self.checked
            if not override then callback(self.checked) end
        end
        render(true)

        Container.MouseButton1Down:Connect(function()
            self.checked = not self.checked
            render()
        end)
        Container.MouseEnter:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.Border }, 0.1) panel:SetTip(data.desc or "") end)
        Container.MouseLeave:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.ElementBg }, 0.1) panel:SetTip("") end)

        return { setToggled = function(v, noCallback) self.checked = v render(noCallback) end, getToggled = function() return self.checked end }
    end

    function panel.AddSlider(panel, data)
        local callback = data.callback or EmptyFunction
        local self = interactable.new()
        self.values = data.values or { min=0, max=100, default=50, round=1 }
        local text = data.title
        local value = panel:_GlobalTable()
        value[text] = self.values.default or 50

        local function round(x) return math.floor((x * (self.values.round or 1)) + 0.5) / (self.values.round or 1) end

        local Container = panel:_Container(46, true)
        local Bg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.ElementBg })
        util.corner(Bg, 8)
        util.stroke(Bg, theme.ElementOutline, 1)

        util.new("TextLabel", { Parent = Container, Text = text, TextColor3 = theme.Text, TextSize = 11, Font = uiFont, Size = UDim2.new(0.6, 0, 0, 16), Position = UDim2.new(0, 10, 0, 6), BackgroundTransparency = 1 })

        local ValueLabel = util.new("TextLabel", { Parent = Container, Text = tostring(self.values.default or 0), TextColor3 = theme.SubText, TextSize = 11, Font = uiFont, Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(1, -50, 0, 6), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })

        local TrackBg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 28), BackgroundColor3 = theme.ElementOutline })
        util.corner(TrackBg, 2)

        local Fill = util.new("Frame", { Parent = TrackBg, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = theme.Accent })
        util.corner(Fill, 2)

        local isInteracting = false
        local function renderFromPercent(percent, override)
            percent = math.clamp(percent, 0, 1)
            local actualValue = round(percent * (self.values.max - self.values.min) + self.values.min)
            ValueLabel.Text = tostring(actualValue)
            Fill:TweenSize(UDim2.new(percent, 0, 1, 0), "Out", "Linear", 0.05, true)
            value[text] = actualValue
            if not override then callback(actualValue) end
        end

        local function renderFromValue(v, override)
            local min, max = self.values.min or 0, self.values.max or 100
            renderFromPercent((v - min) / (max - min), override)
        end

        renderFromValue(self.values.default or 0, true)

        Container.InputBegan:Connect(function(inp, gpe)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and not gpe then 
                isInteracting = true 
                renderFromPercent((input:GetMouseLocation().X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X)
            end
        end)
        Container.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then isInteracting = false end end)
        RunService.RenderStepped:Connect(function()
            if isInteracting then renderFromPercent((input:GetMouseLocation().X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X) end
        end)

        Container.MouseEnter:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.Border }, 0.1) panel:SetTip(data.desc or "") end)
        Container.MouseLeave:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.ElementBg }, 0.1) panel:SetTip("") end)

        return { setValue = renderFromValue, getValue = function() return value[text] end }
    end

    function panel.AddDropdown(panel, data)
        local callback = data.callback or EmptyFunction
        local self = interactable.new()
        self.options = data.options or {}
        self.expanded = false
        local title = data.title
        local value = panel:_GlobalTable()

        local Container = panel:_Container(38, true)
        local Bg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.ElementBg })
        util.corner(Bg, 8)
        util.stroke(Bg, theme.ElementOutline, 1)

        util.new("TextLabel", { Parent = Container, Text = title, TextColor3 = theme.Text, TextSize = 11, Font = uiFont, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1 })
        local DropText = util.new("TextLabel", { Parent = Container, Text = "Select...", TextColor3 = theme.SubText, TextSize = 11, Font = uiFont, Size = UDim2.new(0.4, -20, 1, 0), Position = UDim2.new(0.6, -10, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right })

        local DropdownMenu = util.new("Frame", {
            Parent = Container, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 4), BackgroundColor3 = theme.Panel, ZIndex = 60, ClipsDescendants = true
        }, {
            util.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
            util.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) })
        })
        util.corner(DropdownMenu, 6)
        util.stroke(DropdownMenu, theme.Border, 1)

        local function renderDropdown()
            local UIList = DropdownMenu:FindFirstChildOfClass("UIListLayout")
            if self.expanded then
                DropdownMenu:TweenSize(UDim2.new(1, 0, 0, UIList.AbsoluteContentSize.Y + 8), "Out", "Quart", 0.15, true)
            else
                DropdownMenu:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quart", 0.15, true)
            end
        end

        for count, text in pairs(self.options) do
            local Item = util.new("TextButton", { Parent = DropdownMenu, Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = theme.Panel, LayoutOrder = count, ZIndex = 61 })
            util.corner(Item, 5)

            local ItemText = util.new("TextLabel", { Parent = Item, Text = text, TextColor3 = theme.SubText, TextSize = 11, Font = uiFont, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, ZIndex = 62 })

            local function select(override)
                if self.expanded or override then
                    DropText.Text = text
                    self.expanded = false
                    self.selected = count
                    renderDropdown()
                    value[title] = count
                    if not override then callback(count, text) end
                end
            end

            Item.MouseButton1Click:Connect(select)
            if count == (data.default or 1) then select(true) end
            Item.MouseEnter:Connect(function() util.tween(Item, { BackgroundColor3 = theme.ElementBg }, 0.1) util.tween(ItemText, { TextColor3 = theme.Text }, 0.1) end)
            Item.MouseLeave:Connect(function() util.tween(Item, { BackgroundColor3 = theme.Panel }, 0.1) util.tween(ItemText, { TextColor3 = theme.SubText }, 0.1) end)
        end

        Container.MouseButton1Down:Connect(function() self.expanded = not self.expanded renderDropdown() end)
        Container.MouseEnter:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.Border }, 0.1) panel:SetTip(data.desc or "") end)
        Container.MouseLeave:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.ElementBg }, 0.1) panel:SetTip("") end)

        return { getSelected = function() return self.selected, self.options[self.selected] end }
    end

    function panel.AddTextInput(panel, data)
        local callback = data.callback or EmptyFunction
        local title = data.title
        local value = panel:_GlobalTable()

        local Container = panel:_Container(38, true)
        local Bg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.ElementBg })
        util.corner(Bg, 8)
        util.stroke(Bg, theme.ElementOutline, 1)

        util.new("TextLabel", { Parent = Container, Text = title, TextColor3 = theme.Text, TextSize = 11, Font = uiFont, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1 })

        local TextInput = util.new("TextBox", {
            Parent = Container, PlaceholderText = data.placeholder or "Enter text...", Text = "", TextColor3 = theme.Accent, PlaceholderColor3 = theme.SubText, TextSize = 11, Font = uiFont, Size = UDim2.new(0.4, 0, 0, 20), Position = UDim2.new(0.6, -10, 0.5, -10), BackgroundColor3 = theme.TopBar, TextXAlignment = Enum.TextXAlignment.Center
        })
        util.corner(TextInput, 4)
        util.stroke(TextInput, theme.ElementOutline, 1)

        TextInput:GetPropertyChangedSignal("Text"):Connect(function()
            value[title] = TextInput.Text
            callback(TextInput.Text)
        end)
        Container.MouseEnter:Connect(function() panel:SetTip(data.desc or "") end)
        Container.MouseLeave:Connect(function() panel:SetTip("") end)
    end

    function panel.AddButton(panel, data)
        local callback = data.callback or EmptyFunction
        local Container = panel:_Container(34, true)

        local Bg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.ElementBg })
        util.corner(Bg, 8)
        util.stroke(Bg, theme.ElementOutline, 1)

        util.new("TextLabel", { Parent = Container, Text = data.title or "Button", TextColor3 = theme.Text, TextSize = 11, Font = uiFont, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center })

        Container.MouseEnter:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.Accent }, 0.15) panel:SetTip(data.desc or "") end)
        Container.MouseLeave:Connect(function() util.tween(Bg, { BackgroundColor3 = theme.ElementBg }, 0.15) panel:SetTip("") end)
        Container.MouseButton1Down:Connect(function() callback() end)
    end

    function panel.AddKeybind(panel, data)
        local callback = data.callback or EmptyFunction
        local self = interactable.new()
        self.key = data.default or Enum.KeyCode.E
        self.listening = false
        local text = data.title
        local value = panel:_GlobalTable()
        value[text] = self.key

        local Container = panel:_Container(38, true)
        local Bg = util.new("Frame", { Parent = Container, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.ElementBg })
        util.corner(Bg, 8)
        util.stroke(Bg, theme.ElementOutline, 1)

        util.new("TextLabel", { Parent = Container, Text = text, TextColor3 = theme.Text, TextSize = 11, Font = uiFont, Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1 })

        local KeyDisplay = util.new("TextButton", { Parent = Container, Size = UDim2.new(0, 54, 0, 22), Position = UDim2.new(1, -64, 0.5, -11), BackgroundColor3 = theme.TopBar })
        util.corner(KeyDisplay, 4)
        util.stroke(KeyDisplay, theme.ElementOutline, 1)

        local KeyLabel = util.new("TextLabel", { Parent = KeyDisplay, Text = self.key.Name, TextColor3 = theme.SubText, TextSize = 10, Font = uiFont, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center })

        KeyDisplay.MouseButton1Down:Connect(function()
            self.listening = true
            KeyLabel.Text = "..."
            KeyLabel.TextColor3 = theme.Accent
        end)

        input.InputBegan:Connect(function(inp, gpe)
            if self.listening and inp.UserInputType == Enum.UserInputType.Keyboard then
                self.listening = false
                self.key = inp.KeyCode
                KeyLabel.Text = inp.KeyCode.Name
                KeyLabel.TextColor3 = theme.SubText
                value[text] = self.key
                callback(self.key)
            end
        end)

        Container.MouseEnter:Connect(function() panel:SetTip(data.desc or "") end)
        Container.MouseLeave:Connect(function() panel:SetTip("") end)

        return { getKey = function() return self.key end }
    end
end
