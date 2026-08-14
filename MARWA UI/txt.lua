local Utility = {}
local TweenService = game:GetService("TweenService")

function Utility:TweenObject(obj, properties, duration, ...)
    TweenService:Create(obj, TweenInfo.new(duration, ...), properties):Play() 
end

function Utility:Debounce(fn, cooldown)
    local locked = false
    return function(...)
        if locked then return end
        locked = true
        local args = {...}
        local ok, err = pcall(fn, unpack(args))
        if not ok then warn("[Debounce] " .. tostring(err)) end
        task.delay(cooldown, function() locked = false end)
    end
end

function Utility:GetNearest(origin, list, getPositionFn)
    getPositionFn = getPositionFn or function(item) return item.Position end
    local nearest, nearestDist = nil, math.huge
    for _, item in ipairs(list) do
        local ok, pos = pcall(getPositionFn, item)
        if ok and pos then
            local dist = (origin - pos).Magnitude
            if dist < nearestDist then
                nearest, nearestDist = item, dist
            end
        end
    end
    return nearest, nearestDist
end

local activeNotifs = 0
local UI, _183goat = {
    Theme = nil,
    Themes = {},
    Notifications = 0,
    DefaultProps = {},
    IslandOpen = false,
}, {
    Objects = {},
}

_183goat.DefaultProps = {
    TextButton = {
        AutoButtonColor = false,
        TextTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        ZIndex = 1,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextSize = 12,
        ZIndex = 1,
    },
    ImageLabel = {
        BorderSizePixel = 0,
        ZIndex = 1,
    },
    Frame = {
        BorderSizePixel = 0,
        ZIndex = 1,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 1,
    },
}

_183goat.Themes = {
    Amethyst = {
        Name = "Amethyst",
        Background = Color3.fromRGB(12, 5, 22),      -- deep void purple
        SideBar = Color3.fromRGB(18, 10, 32),        -- rich dark purple
        Text = Color3.fromRGB(240, 230, 255),
        ElementColor = Color3.fromRGB(28, 15, 48),    -- card fill purple
        Outline = Color3.fromRGB(180, 50, 255),       -- INSANE neon purple stroke
        Placeholder = Color3.fromRGB(65, 30, 110),      -- unfilled toggle/slider track
        IconColor = Color3.fromRGB(210, 130, 255),
        Accent = Color3.fromRGB(200, 50, 255),         -- NEW: hyper bright accent for "on" states
        AccentGlow = Color3.fromRGB(230, 140, 255),    -- NEW: hot highlight for pulses
    },
}

UI.Theme = _183goat.Themes["Amethyst"]

function _183goat:Create(class, properties, children)
    local inst = Instance.new(class)

    local defaults = _183goat.DefaultProps[class]
    if defaults then
        for prop, val in next, defaults do
            if properties[prop] == nil then
                properties[prop] = val
            end
        end
    end

    for property, Value in next, properties or {} do
        if property ~= "ThemeID" then
            inst[property] = Value
        end
    end

    for _, Child in next, children or {} do
        Child.Parent = inst
    end

    if properties.ThemeID then
        _183goat:AddThemeObject(inst, properties.ThemeID)
    end
    return inst
end


function _183goat:GetThemeProperty(property, theme, fallbackProperty)
    local function resolve(t, key)
        for _, part in ipairs(string.split(key, ".")) do
            if type(t) ~= "table" then return nil end
            t = t[part]
        end
        return t
    end

    return resolve(theme, property) 
        or resolve(_183goat.Themes["Dark"], property)
        or (fallbackProperty and (resolve(theme, fallbackProperty) or resolve(_183goat.Themes["Dark"], fallbackProperty)))
end

function _183goat:AddThemeObject(object, properties)
    _183goat.Objects[object] = { Object = object, Properties = properties }
    _183goat:UpdateTheme(object, false)
    return object
end

function _183goat:UpdateTheme(targetObject, isTween)
    local function ApplyTheme(objData)
        for property, colorKey in pairs(objData.Properties or {}) do
            local color = nil
            for _, key in ipairs(string.split(colorKey, "|")) do
                key = key:gsub("%s+", "")
                color = _183goat:GetThemeProperty(key, UI.Theme)
                if color then break end
            end

            if color then
                if not isTween then
                    objData.Object[property] = color
                else
                    Utility:TweenObject(objData.Object, { [property] = color }, 0)
                end
            end
        end
    end

    if targetObject then
        local objData = _183goat.Objects[targetObject]
        if objData then ApplyTheme(objData) end
    else
        for _, objData in pairs(_183goat.Objects) do
            ApplyTheme(objData)
        end
    end
end

function _183goat:SetTheme(themeName)
    local theme = _183goat.Themes[themeName]
    if not theme then
       
        return
    end

    UI.Theme = theme
    _183goat:UpdateTheme(nil, true)
end

function UI:AddTheme(i)
    _183goat.Themes[i.Name] = i
    return i
end
function Utility:GlassStroke(themeKey, thickness, animated)
    local gradient = _183goat:Create("UIGradient", {
        Color = ColorSequence.new(
            Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(255, 255, 255)
        ),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Rotation = -110
    })

    local stroke = _183goat:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        LineJoinMode = "Round",
        Thickness = thickness or 1.2, -- Made thicker for emphasis
        ThemeID = { Color = themeKey or "Outline" }
    }, { gradient })

    -- opt-in continuous rotation, cheap (one tween loop per stroke)
    if animated ~= false then
        task.spawn(function()
            while stroke.Parent do
                gradient.Rotation = 0
                -- Sped up the rotation for a more dynamic feel
                Utility:TweenObject(gradient, {Rotation = 360}, 2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                task.wait(2.5)
            end
        end)
    end

    return stroke
end


function Utility:Padding(a, b, c, d)
    if type(a) == "table" then
        return _183goat:Create("UIPadding", {
            PaddingTop = UDim.new(0, a.top or 0),
            PaddingBottom = UDim.new(0, a.bottom or 0),
            PaddingLeft = UDim.new(0, a.left or 0),
            PaddingRight = UDim.new(0, a.right or 0),
        })
    end
    return _183goat:Create("UIPadding", {
        PaddingTop = UDim.new(0, a or 0),
        PaddingBottom = UDim.new(0, b or a or 0),
        PaddingLeft = UDim.new(0, c or a or 0),
        PaddingRight = UDim.new(0, d or c or a or 0),
    })
end

function Utility:ListLayout(dir, padding, align)
    return _183goat:Create("UIListLayout", {
        FillDirection = (dir == "H") and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 5),
        HorizontalAlignment = (align and dir == "H") and align or nil,
        VerticalAlignment = (align and dir == "V") and align or nil,
    })
end

function Utility:T(scope, prop, fallback)
    return scope .. "." .. prop .. "|" .. fallback
end

function Utility:Search(Window, cfg)
    table.insert(Window.SearchIndex, cfg)
end

function Utility:ElText(parent, title, desc, scope)
    local Title = Text(parent, title, {
        Size = UDim2.new(1, 0, 0, 5),
        AutomaticSize = "Y",
        ZIndex = 16,
        FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold),
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        RichText = true,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ThemeID = { TextColor3 = Utility:T(scope, "Text", "Text") }
    }, { Utility:Padding({ left = 10 }) })
    Title.Position = UDim2.new(0, 0, 0, 0)

    local Desc = Text(parent, desc, {
        Size = UDim2.new(1, 0, 0, 5),
        AutomaticSize = "Y",
        ZIndex = 16,
        FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold),
        TextSize = 12,
        TextTransparency = 0.7,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        RichText = true,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = desc ~= nil,
        ThemeID = { TextColor3 = Utility:T(scope, "Text", "Text") }
    }, { Utility:Padding({ left = 10 }) })

    return Title, Desc
end

function Utility:Element(RightScroll, ElementFrame, sizeY, scope)
    local Beeee = _183goat:Create("Frame", {
        Parent = RightScroll,
        BackgroundTransparency = 1,
        AutomaticSize = "Y",
        Size = UDim2.new(0, ElementFrame.Size.X.Offset - 10, 0, sizeY or 40),
        ZIndex = 15,
    }, {
        _183goat:Create("UIScale", {
            Scale = 1
        })
    })

    local Card = _183goat:Create("Frame", {
        Parent = Beeee,
        AutomaticSize = "Y",
        ClipsDescendants = true,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 15,
        ThemeID = { BackgroundColor3 = Utility:T(scope, "Background", "ElementColor") }
    }, {
        Utility:GlassStroke(),
        _183goat:Create("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        Utility:Padding({ top = 5, bottom = 5 }),
    })

    local Inner = _183goat:Create("Frame", {
        Parent = Card,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        ZIndex = 16,
    }, {
        Utility:ListLayout("V", 1),
        Utility:Padding({ top = 9 }),
    })

    return Beeee, Card, Inner
end

local IconsV2 = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
IconsV2.SetIconsType("lucide")

local function GetIcon(icon)
    if typeof(icon) == "string" and icon:find("rbxassetid://") then
        return icon
    end

    if icon:find(":") then
        local pack, name = icon:match("([^:]+):(.+)")
        if pack and name then
            IconsV2.SetIconsType(string.lower(pack))
            return IconsV2.GetIcon(name)
        end
    end
    
    IconsV2.SetIconsType("lucide")
    return IconsV2.GetIcon(icon)
end

local UserInputService = game:GetService("UserInputService")

local function enableDragging(frame)
    local dragging = false
    local dragStart
    local startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

                local delta = input.Position - dragStart
                -- Add a slight snappy tween to the drag for an insane feel
                Utility:TweenObject(frame, {
                    Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                }, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end
        end
    end)
end

function LockedElm(Frame, Stat)
    local LockFrame = Frame:FindFirstChild("Lock")
    if not LockFrame then
        LockFrame = _183goat:Create("Frame", {
            Name = "Lock",
            BackgroundTransparency = 0.2,
            AutomaticSize = "XY",
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 198,
            Parent = Frame,
            Active = true,
            ThemeID = {
                BackgroundColor3 = "Background"
            }
        },{
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0,12)
            })
        })
        _183goat:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0,20, 0,20),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            ZIndex = 199,
            Image = GetIcon("lock-keyhole"),
            Parent = LockFrame,
        })
    end
    LockFrame.Visible = Stat
    return LockFrame
end

function Text(parent, text, textProps, children)
    local container = _183goat:Create("Frame", {
        BackgroundTransparency = textProps.BackgroundTransparency or 1,
        AutomaticSize = textProps.AutomaticSize or "XY",
        Size = textProps.Size or UDim2.new(),
        LayoutOrder = textProps.LayoutOrder,
        Position = textProps.Position,
        ZIndex = textProps.ZIndex,
        Visible = textProps.Visible ~= false,
        Parent = textProps.Parent or parent,
    }, {
        _183goat:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })
    })

    if children then
        for _, child in ipairs(children) do
            child.Parent = container
        end
    end

    local imgTheme = nil
    if textProps.ThemeID and textProps.ThemeID.TextColor3 then
        imgTheme = { ImageColor3 = textProps.ThemeID.TextColor3 }
    end

    local function CreateText(str, layoutOrder, parentRow)
        return _183goat:Create("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = "XY",
            Size = UDim2.new(),
            LayoutOrder = layoutOrder,
            Text = str,
            RichText = textProps.RichText or false,
            TextSize = textProps.TextSize or 13,
            FontFace = textProps.FontFace or Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextColor3 = textProps.TextColor3 or Color3.fromRGB(255, 255, 255),
            TextTransparency = textProps.TextTransparency or 0,
            TextWrapped = textProps.TextWrapped or false,
            TextXAlignment = textProps.TextXAlignment or Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = textProps.ZIndex,
            Parent = parentRow,
            ThemeID = textProps.ThemeID,
        })
    end

    local function CreateIcon(name, layoutOrder, parentRow)
        if not icon then
            --warn("IconsV2: Icon Not Found — " .. name)
        end

        local img = _183goat:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, textProps.TextSize or 13, 0, textProps.TextSize or 13),
            LayoutOrder = layoutOrder,
            ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = textProps.TextColor3 or Color3.fromRGB(255, 255, 255),
            ImageTransparency = textProps.TextTransparency or 0,
            ZIndex = textProps.ZIndex,
            Image = "",
            ThemeID = imgTheme,
            Parent = parentRow,
        })

        if typeof(IconsV2.GetIcon(name)) == "table" then
            img.Image = GetIcon(name).Image or ""
            if IconsV2.GetIcon(name).ImageRectOffset then
                img.ImageRectOffset = GetIcon(name).ImageRectOffset
            end
            if IconsV2.GetIcon(name).ImageRectSize then
                img.ImageRectSize = GetIcon(name).ImageRectSize
            end
        elseif typeof(IconsV2.GetIcon(name)) == "string" then
            img.Image = GetIcon(name)
        end
        return img
    end

    local function Render(newText)
        for _, child in ipairs(container:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end

        newText = (newText or ""):gsub("\n", "\\n")

        for lineIndex, line in ipairs(string.split(newText, "\\n")) do
            local row = _183goat:Create("Frame", {
                BackgroundTransparency = 1,
                AutomaticSize = "XY",
                ClipsDescendants = true,
                Size = UDim2.new(),
                LayoutOrder = lineIndex,
                Parent = container,
            }, {
                _183goat:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                })
            })

            local order = 0
            local lastPos = 1

            for before, iconName in line:gmatch("(.-)<([%w_%-]+)>") do
                if #before:gsub("%s", "") > 0 then
                    order += 1
                    CreateText(before, order, row)
                end

                order += 1
                CreateIcon(iconName, order, row)

                lastPos = lastPos + #before + #iconName + 2
            end
            local rest = line:sub(lastPos)
            if #rest:gsub("%s", "") > 0 then
                order += 1
                CreateText(rest, order, row)
            end
        end
    end
    Render(text)
    return {
        Frame = container,
        SetText = Render,
        UIPadding = container:FindFirstChildOfClass("UIPadding"),
    }
end

    local UIScreen = _183goat:Create("ScreenGui", {
        Parent = game:GetService("CoreGui"),
        --ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    local Island = _183goat:Create("Frame", {
        Parent = UIScreen,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0), 
        AnchorPoint = Vector2.new(9e9, 9e9),
        Position = UDim2.new(0.5, 0, -0.2, 0),
        ZIndex = 100,
        ThemeID = {
            BackgroundColor3 = "Background"
        }
    },{
        _183goat:Create("UICorner", { CornerRadius = UDim.new(0, 16) }),
        _183goat:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = "Left",
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3),
        }),
        _183goat:Create("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
        })
    })

    Island.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Utility:TweenObject(Island, {Size = UDim2.new(0, Island.UIListLayout.AbsoluteContentSize.X + 5, 0, 36)}, 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    task.defer(function()
        Utility:TweenObject(Island, {Size = UDim2.new(0, Island.UIListLayout.AbsoluteContentSize.X + 5, 0, 35)}, 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

function UI:CreateWindow(Config)
    local Window = {
        Name = Config.Name or "_183goat",
        Author = Config.Author or nil,
        Icon = Config.Icon or nil,
        ToggleKey = Config.ToggleKey or Enum.KeyCode.F,
        Transparent = Config.Transparent or false,
        Theme = Config.Theme or "Dark",
        Folder = Config.Folder,
        KeySystem = Config.KeySystem,
        Default = Config.Default or "Default",
        AutoScale = Config.AutoScale or true,
        Resizable = Config.Resizable or true,
        Topbar = {
            Height = Config.Height or 35,
        },
        OnDestroy = Config.OnDestroy or function() end,
        Themes = _183goat.Themes,
        Size = Config.Size and UDim2.new(
            0, math.clamp(Config.Size.X.Offset, 420, 580),
            0, math.clamp(Config.Size.Y.Offset, 280, 450)
        ) or UDim2.new(0, 550, 0, 375),
        SideBarWidth = Config.SideBarWidth or 160,
        User = Config.User or {},
        Tabs = {},
        AllElements = {},
        CurrentTab = {},
        TabOrder = {},
        SearchIndex = {},
    }
	local oldUI = game:GetService("CoreGui"):FindFirstChild(Config.Name or "_183goat")
    if oldUI then
        oldUI:Destroy()
    end
    local UIScreen = _183goat:Create("ScreenGui", {
        Name = Config.Name or "_183goat",
        Parent = game:GetService("CoreGui"),
    })
    Window.IslandOpen = true
    function Window:SetTheme(themeName)
        Window.Theme = themeName
        local theme = _183goat.Themes[themeName]
        if not theme then
            
            return
        end
        
        UI.Theme = theme
        _183goat:UpdateTheme(nil, true)
    end

    Window:SetTheme(Window.Theme)


    local Main = _183goat:Create("Frame", {
        Name = Window.Name,
        Size = UDim2.new(0, Window.Size.X.Offset, 0, Window.Size.Y.Offset),
        ClipsDescendants = true,
        Active = true,
        BorderColor3 = Color3.new(0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = (Window.Transparent and 0.1 or 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(15, 8, 25), -- Changed to Deep Purple
        Parent = UIScreen,
        ThemeID = {
            BackgroundColor3 = "Background"
        }
    }, {
        _183goat:Create("UICorner", {
            CornerRadius = UDim.new(0, 16),
        }),
        _183goat:Create("Frame", {
            Size = UDim2.new(0, Window.Size.X.Offset, 0, Window.Size.Y.Offset-8),--Window.Topbar.Height),
            --ClipsDescendants = true,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            --Active = true,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 8),
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            _183goat:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 5),
            }),
            _183goat:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
            }),
        }),
        _183goat:Create("UIScale", {
            Scale = 1,
        }),
    })
    enableDragging(Main)

    -- INSANE entrance: extreme elastic scale-in with overshoot + fade
    Main.UIScale.Scale = 0.001
    Main.BackgroundTransparency = 1
    Main.Frame.BackgroundTransparency = 1
    -- UPGRADED to Elastic for intense snap
    Utility:TweenObject(Main.UIScale, {Scale = 1}, 0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    Utility:TweenObject(Main, {BackgroundTransparency = (Window.Transparent and 0.1 or 0)}, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)


	function Window:Toggle()
    if Main.Visible then
        Main.Visible = false
    else
        Main.Visible = true
    end
end


    local TopBarF1 = _183goat:Create("Frame", {
        Parent = Main.Frame,
        Size = UDim2.new(0, Window.Size.X.Offset - 182 + 133 + 5, 0, Window.Topbar.Height), --Window.Size.X.Offset - 10 + 133 + 5
        --ClipsDescendants = true,
        BackgroundColor3 = Color3.fromRGB(22, 12, 38), -- Changed to Dark Purple
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Position = UDim2.new(0, 0, 0, 8),
        BorderSizePixel = 0,
        ZIndex = 3,
        ThemeID = {
            BackgroundColor3 = "SideBar"
        }
    }, {
        _183goat:Create("UICorner", {
            CornerRadius = UDim.new(0, 16),
        }),
        _183goat:Create("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            LineJoinMode = "Round",
            Thickness = 0,
            ThemeID = {
                Color = "Outline"
            }
        },{
            _183goat:Create("UIGradient", {
                Color = ColorSequence.new(
                    Color3.fromRGB(255, 255, 255), 
                    Color3.fromRGB(255, 255, 255)
                ),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.1),
                    NumberSequenceKeypoint.new(0.5, 1),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = -110
            })
        }),
        _183goat:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            --ClipsDescendants = true,
            BackgroundColor3 = Color3.fromRGB(22, 12, 38), -- Changed to Dark Purple
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Position = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, {
            _183goat:Create("UIPadding", {
                --PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 0),
                PaddingTop = UDim.new(0, 0),
            }),
        }),
    })
    TopBarF1.Size = UDim2.new(0,Window.Size.X.Offset - 5 - 5 - 5- 187,0,Window.Topbar.Height)

    local LibName = _183goat:Create("TextLabel", {
        Parent = TopBarF1.Frame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        RichText = true,
        Size = UDim2.new(1, 0, 0, 35),
        FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Text = Window.Name,
        AutomaticSize = "Y",
        TextSize = 13,
        ZIndex = 5,
        TextWrapped = true,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Window.Author and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        ThemeID = {
            TextColor3 = "Text"
        }
    }, {
        _183goat:Create("UIPadding", {
            PaddingLeft = UDim.new(0, Window.Icon and 45 or 12),
            PaddingTop = Window.Author and UDim.new(0, 6) or UDim.new(0, 0),
        })
    })

    local LibAuthor = _183goat:Create("TextLabel", {
        Parent = TopBarF1.Frame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        RichText = true,
        Size = UDim2.new(1, 0, 0, 35),
        FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Text = Window.Author or "",
        AutomaticSize = "Y",
        TextTransparency = 0.5,
        TextSize = 13,
        ZIndex = 5,
        TextWrapped = true,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = Window.Author,
        ThemeID = {
            TextColor3 = "Text"
        }
    }, {
        _183goat:Create("UIPadding", {
            PaddingLeft = UDim.new(0, Window.Icon and 45 or 12),
            PaddingTop = UDim.new(0, 13),
        })
    })

    if Window.Icon then
        local UIIcon = _183goat:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Image = GetIcon(Window.Icon),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0.5, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 25, 0, 25),
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = TopBarF1,
            ThemeID = { ImageColor3 = "IconColor"}
        })
    end

    local TopBarF2 = _183goat:Create("Frame", {
        Parent = Main.Frame,
        Size = UDim2.new(0, 133, 0, Window.Topbar.Height),
        ClipsDescendants = true,
        BackgroundColor3 = Color3.fromRGB(22, 12, 38), -- Changed to Dark Purple
        Visible = false,
        LayoutOrder = 2,
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0, 0, 0, 8),
        BorderSizePixel = 0,
        ZIndex = 3,
        ThemeID = {
            BackgroundColor3 = "SideBar"
        }
    }, {
        _183goat:Create("UICorner", {
            CornerRadius = UDim.new(0, 16),
        }),
        _183goat:Create("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            LineJoinMode = "Round",
            Thickness = 0.6,
            ThemeID = {
                Color = "Outline"
            }
        },{
            _183goat:Create("UIGradient", {
                Color = ColorSequence.new(
                    Color3.fromRGB(255, 255, 255), 
                    Color3.fromRGB(255, 255, 255)
                ),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.1),
                    NumberSequenceKeypoint.new(0.5, 1),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = -110
            })
        }),
        _183goat:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = "Right",
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
        }),
        _183goat:Create("UIPadding", {
            --PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 4),
        }),
    })

    local TopBarF3 = _183goat:Create("Frame", {
        Parent = Main.Frame,
        Size = UDim2.new(0, 187, 0, Window.Topbar.Height),
        --ClipsDescendants = true,
        BackgroundColor3 = Color3.fromRGB(22, 12, 38), -- Changed to Dark Purple
        LayoutOrder = 3,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 8),
        BorderSizePixel = 0,
        ZIndex = 3,
        ThemeID = {
            BackgroundColor3 = "SideBar"
        }
    }, {
        _183goat:Create("UICorner", {
            CornerRadius = UDim.new(0, 16),
        }),
        _183goat:Create("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            LineJoinMode = "Round",
            Thickness = 0,
            ThemeID = {
                Color = "Outline"
            }
        },{
            _183goat:Create("UIGradient", {
                Color = ColorSequence.new(
                    Color3.fromRGB(255, 255, 255), 
                    Color3.fromRGB(255, 255, 255)
                ),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.1),
                    NumberSequenceKeypoint.new(0.5, 1),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = -110
            })
        }),
    })

    function UI:Dialog(Config)
        local Dialog = {
            Title = Config.Title or "Dialog",
            Desc = Config.Desc or nil,
            Buttons = Config.Buttons or {},
            Image = Config.Image or nil,
            ImageSizeY = Config.ImageSizeY or 60,
            Count = 0,
        }

        local Overlay = _183goat:Create("Frame", {
            Parent = Main,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0.1,
            Active = true,
            ZIndex = 1000,
            ThemeID = {
                BackgroundColor3 = "Background"
            }
        }, {
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, 16),
            }),
        })

        local DialogFrame = _183goat:Create("Frame", {
            Parent = Overlay,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 190, 0, 0),
            ClipsDescendants = true,
            --AutomaticSize = "Y",
            Active = true,
            ZIndex = 1001,
            ThemeID = {
                BackgroundColor3 = "Dialog.Background|SideBar"
            }
        }, {
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, 16),
            }),
            _183goat:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            }),
            _183goat:Create("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
            }),
        })
        DialogFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Utility:TweenObject(DialogFrame, {Size = UDim2.new(0, 200, 0, DialogFrame.UIListLayout.AbsoluteContentSize.Y + 20)}, 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)

        local Image
        if Dialog.Image then
            Image = _183goat:Create("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 180, 0, Dialog.ImageSizeY),
                ZIndex = 1002,
                ScaleType = "Crop",
                Parent = DialogFrame,
            }, {
                _183goat:Create("UICorner", {
                    CornerRadius = UDim.new(0, 16),
                }),
            })
            Image.Image = Dialog.Image
        end

        Text(DialogFrame, Dialog.Title, {
            LayoutOrder = 1,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            RichText = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = "Y",
            FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            Text = Dialog.Title,
            TextSize = 14,
            ZIndex = 1002,
            TextWrapped = true,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeID = {
                TextColor3 = "Dialog.Text|Text"
            }
        })

        if Dialog.Desc then
            Text(DialogFrame, Dialog.Desc, {
                Parent = DialogFrame,
                LayoutOrder = 2,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                RichText = true,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = "Y",
                FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextSize = 12,
                TextTransparency = 0.5,
                ZIndex = 1002,
                TextWrapped = true,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeID = {
                    TextColor3 = "Dialog.Text|Text"
                }
            })
        end

        if Dialog.Buttons then
            local ButtonsFrame = _183goat:Create("Frame", {
                Parent = DialogFrame,
                LayoutOrder = 3,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ZIndex = 1002,
            }, {
                _183goat:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                }),
            })

            local Rows = {}
            for i = 1, #Dialog.Buttons, 2 do
                table.insert(Rows, {Dialog.Buttons[i], Dialog.Buttons[i + 1]})
            end

            for rowIndex, Row in ipairs(Rows) do
                local RowFrame = _183goat:Create("Frame", {
                    Parent = ButtonsFrame,
                    LayoutOrder = rowIndex,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    ZIndex = 1002,
                }, {
                    _183goat:Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 6),
                    }),
                })

                local ButtonsInRow = 0
                for _, cfg in ipairs(Row) do
                    if cfg then
                        ButtonsInRow = ButtonsInRow + 1
                    end
                end

                for colIndex, ButtonConfig in ipairs(Row) do
                    Dialog.Count = Dialog.Count + 1

                    local Width
                    if ButtonsInRow == 1 then
                        Width = UDim2.new(1, 0, 1, 0)
                    else
                        Width = UDim2.new(0.5, -3, 1, 0)
                    end

                    local Button = _183goat:Create("TextButton", {
                        Parent = RowFrame,
                        LayoutOrder = colIndex,
                        Size = Width,
                        BackgroundColor3 = Color3.fromRGB(35, 18, 60), -- Changed to deep button purple
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 1002,
                        ThemeID = {
                            BackgroundColor3 = "Dialog.Button|ElementColor"
                        }
                    }, {
                        _183goat:Create("UICorner", {
                            CornerRadius = UDim.new(0, 10),
                        }),
                        _183goat:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                            Text = ButtonConfig.Text or "Button",
                            TextSize = 14,
                            ZIndex = 1002,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ThemeID = {
                                TextColor3 = "Text"
                            }
                        }),
                    })

                    Button.MouseButton1Click:Connect(function()
                        if ButtonConfig.Callback then
                            ButtonConfig.Callback()
                        end
                        Utility:TweenObject(Overlay, {Transparency = 1}, 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                        Utility:TweenObject(DialogFrame, {Size = UDim2.new(0, 200, 0, 0)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                        task.wait(0.2)
                        Overlay:Destroy()
                    end)
                end
            end
        end
        return Dialog
    end
    local TopBarBC = 0
    function UI:CreateTopbarButton(Config)
        TopBarF2.Visible = true
        TopBarBC += 1

        if TopBarBC > 4 then
            TopBarBC = 4
        end
        TopBarF2.Size = UDim2.new(0, (37 * TopBarBC) + (-5 * (TopBarBC - 1)), 0, 35)
        TopBarF1.Size = UDim2.new(0,Window.Size.X.Offset - 5 - 5 - 5 - 5 -TopBarF2.Size.X.Offset - 187,0,35)
        --TopBarF2.Size = UDim2.new(0, (37 * TopBarBC) + (-5 * (TopBarBC - 1)), 0, 35)
        --Window.Size.X.Offset - 173 + 133 + 5
        --TopBarF1.Size = UDim2.new(0, Window.Size.X.Offset - 208 - TopBarF2.Size.X.Offset, 0, 35)
        --TopBarF1.Size = UDim2.new(0, 270 - TopBarF2.Size.X.Offset, 0, 35)

        local TopBarButton = {
            Icon = Config.Icon or "bird",
            Callback = Config.Callback or function() end,
            Order = Config.Order or 1,
        }
        local TopButton = _183goat:Create("Frame", {
            Parent = TopBarF2,
            Size = UDim2.new(0, 27, 0, 27),
            BackgroundTransparency = 0.6,
            ClipsDescendants = true,
            BackgroundColor3 = Color3.fromRGB(32, 18, 55), -- Purple tone
            Active = true,
            LayoutOrder = TopBarButton.Order,
            Position = UDim2.new(0, 0, 0, 8),
            BorderSizePixel = 0,
            ZIndex = 3,
            ThemeID = {
                BackgroundColor3 = "Background"
            }
        }, {
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            _183goat:Create("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                LineJoinMode = "Round",
                Thickness = 0.6,
                ThemeID = {
                    Color = "Outline"
                }
            },{
                _183goat:Create("UIGradient", {
                    Color = ColorSequence.new(
                        Color3.fromRGB(255, 255, 255), 
                        Color3.fromRGB(255, 255, 255)
                    ),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.1),
                        NumberSequenceKeypoint.new(0.5, 1),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    Rotation = -110
                })
            }),
        })
        
    end
    function UI:CreateTopbarToggle(Config)
        TopBarF2.Visible = true
        TopBarBC += 1
        if TopBarBC > 4 then
            TopBarBC = 4
        end
        TopBarF2.Size = UDim2.new(0, (37 * TopBarBC) + (-5 * (TopBarBC - 1)), 0, 35)
        TopBarF1.Size = UDim2.new(0,Window.Size.X.Offset - 5 - 5 - 5 - 5 -TopBarF2.Size.X.Offset - 187,0,35)

        local TopBarToggle = {
            Icon = Config.Icon or "bird",
            Callback = Config.Callback or function() end,
            Order = Config.Order or 1,
            Default = Config.Default or false,
            EnableIcon = Config.EnableIcon or Config.Icon,
            DisableIcon = Config.DisableIcon or Config.Icon,
            EnableBackground = Config.EnableBackground or nil,
            DisableBackground = Config.DisableBackground or nil,
        }
        local TopToggle = _183goat:Create("Frame", {
            Parent = TopBarF2,
            Size = UDim2.new(0, 27, 0, 27),
            BackgroundTransparency = 0.6,
            ClipsDescendants = true,
            BackgroundColor3 = Color3.fromRGB(32, 18, 55), -- Purple tone
            Active = true,
            LayoutOrder = TopBarToggle.Order,
            Position = UDim2.new(0, 0, 0, 8),
            BorderSizePixel = 0,
            ZIndex = 3,
            ThemeID = {
                BackgroundColor3 = "Background"
            }
        }, {
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            _183goat:Create("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                LineJoinMode = "Round",
                Thickness = 0.6,
                ThemeID = {
                    Color = "Outline"
                }
            },{
                _183goat:Create("UIGradient", {
                    Color = ColorSequence.new(
                        Color3.fromRGB(255, 255, 255), 
                        Color3.fromRGB(255, 255, 255)
                    ),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.1),
                        NumberSequenceKeypoint.new(0.5, 1),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    Rotation = -110
                })
            }),
        })
        local Icon = _183goat:Create("ImageButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = GetIcon(TopBarToggle.Icon),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 16, 0, 16),
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = TopToggle,
            ThemeID = {
                ImageColor3 = "IconColor"
            }
        })

		local function updateToggleState()
    		Utility:TweenObject(TopToggle, {BackgroundTransparency = TopBarToggle.Default and 0 or 0.6}, 0.2)
            Utility:TweenObject(TopToggle, {BackgroundColor3 = (TopBarToggle.Default and TopBarToggle.EnableBackground and TopBarToggle.EnableBackground or Color3.fromRGB(32, 18, 55) or TopBarToggle.DisableBackground and TopBarToggle.DisableBackground or Color3.fromRGB(32, 18, 55))}, 0.2)
            Icon.Image = not TopBarToggle.Default and GetIcon(TopBarToggle.EnableIcon) or GetIcon(TopBarToggle.DisableIcon)
    		--Utility:TweenObject(ToggleScroll, {BackgroundColor3 = Toggle.Default and UI.Theme.ToggleModule.ScrollNew or UI.Theme.ToggleModule.Scroll}, 0.2)
    		task.delay(0.1, function()
    pcall(TopBarToggle.Callback, TopBarToggle.Default)
end)
		end

		updateToggleState()

		Icon.MouseButton1Click:Connect(function()
    		TopBarToggle.Default = not TopBarToggle.Default
    		updateToggleState()
		end)
		return TopBarToggle
    end
    local Tags = 0
    function Window:Tag(Config)
        Tags = Tags + 1

      
        local Tag = {
            Name = Config.Name or "Tag",
            Icon = Config.Icon,
            Color = Config.Color,
            Corner = Config.Corner or 16,
        }
        local TagF = _183goat:Create("Frame", {
            Parent = TagFrame,
            Size = UDim2.new(0, 20, 0, 25),
            AutomaticSize = "X",
            ClipsDescendants = true,
            Active = true,
            ZIndex = 201,
            BackgroundColor3 = Tag.Color or Color3.fromRGB(255, 255, 255),
        },{
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, Tag.Corner)
            }),
            _183goat:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5)
            })
        })
        local Title = _183goat:Create("TextLabel", {
            Size = UDim2.new(0, 0, 0, 13),
            Parent = TagF,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            AutomaticSize = "X",
            BackgroundTransparency = 1,
            ZIndex = 203,
            Text = Tag.Name,
            FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            RichText = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeID = {
                TextColor3 = "Tag.Text|Text"
            }
        }, {
            _183goat:Create("UIPadding", {
                PaddingLeft = UDim.new(0, 0)
            })
        })
        local Icon
        if Tag.Icon then
            Icon = _183goat:Create("ImageLabel", {
                AnchorPoint = Vector2.new(.04, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(.04, 0, 0.5, 0),
                Image = GetIcon(Tag.Icon),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(0, 15, 0, 15),
                ZIndex = 202,
                Parent = TagF,
                ImageTransparency = 0,
                ThemeID = {
                    ImageColor3 = "Tag.Icon|IconColor"
                }
            })
            Title.UIPadding.PaddingLeft = UDim.new(0,22)
        end
        function Tag:SetTitle(i)
            Title.Text = i
        end
        function Tag:SetColor(i)
            TagF.BackgroundColor3 = i
        end
        function Tag:SetCorner(i)
            TagF.UICorner.CornerRadius = UDim.new(0, i)
        end
        return Tag
    end
 
    local WinElements = _183goat:Create("Frame", {
        Parent = TopBarF3,
        Size = UDim2.new(0, 51, 0, 35),
        AnchorPoint = Vector2.new(0.95, 0.5),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Active = true,
        LayoutOrder = 3,
        Position = UDim2.new(0.95, 0, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 100,
    },{
        _183goat:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = "Right",
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3),
        }),
        _183goat:Create("ImageButton", {
            Name = "Cross",
            AnchorPoint = Vector2.new(0, 0.5),
            Image = IconsV2.GetIcon("x"),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Position = UDim2.new(0, 12, 0.5, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 25, 0, 25),
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = TopBarF1,
            ThemeID = {
                ImageColor3 = "IconColor"
            }
        }),
        _183goat:Create("ImageButton", {
            AnchorPoint = Vector2.new(0, 0.5),
            Image = IconsV2.GetIcon(""),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Position = UDim2.new(0, 12, 0.5, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 25, 0, 25),
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = TopBarF1,
            ThemeID = {
                ImageColor3 = "IconColor"
            }
        }),
        _183goat:Create("UIPadding", {
            --PaddingLeft = UDim.new(0, 5),
            --PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 4),
        }),
    })



    local TabFrame = _183goat:Create("Frame", {
        Size = UDim2.new(0, Window.SideBarWidth, 0, Window.Size.Y.Offset - Window.Topbar.Height - 13),
        ClipsDescendants = true,
        Active = true,
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 0, 0, Window.Topbar.Height+13),
        BorderSizePixel = 0,
        ZIndex = 3,
        BackgroundTransparency = (Window.Transparent and 1 or 0),
        BackgroundColor3 = Color3.fromRGB(22, 12, 38), -- Dark purple sidebar
        Parent = Main,
        ThemeID = {
            BackgroundColor3 = "SideBar"
        }
    },{
        _183goat:Create("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = (Window.Transparent and 1 or 0),
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundColor3 = Color3.fromRGB(22, 12, 38),
            BorderSizePixel = 0,
            ZIndex = 4,
            ThemeID = {
                BackgroundColor3 = "SideBar"
            }
        }),
        _183goat:Create("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = (Window.Transparent and 1 or 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundColor3 = Color3.fromRGB(22, 12, 38),
            BorderSizePixel = 0,
            ZIndex = 4,
            ThemeID = {
                BackgroundColor3 = "SideBar"
            }
        }),
        _183goat:Create("UICorner", {
            CornerRadius = UDim.new(0, 16),
        }),
    })

    --USER
    local UserFrame = _183goat:Create("Frame", {
        Parent = TabFrame,
        AnchorPoint = Vector2.new(0.5, 0.96),
        Position = UDim2.new(0.5, 0, 0.96, 0),
        BorderColor3 = Color3.new(0, 0, 0),
        ClipsDescendants = true,
        Size = UDim2.new(0, Window.SideBarWidth - 20, 0, 40),
        BackgroundColor3 = Color3.fromRGB(22, 12, 38),
        ZIndex = 10,
        ThemeID = {
            BackgroundColor3 = "Background"
        }
    },{
        _183goat:Create("UICorner", {
            CornerRadius = UDim.new(0, 16),
        }),
        _183goat:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.075, 0.5),
            BackgroundTransparency = 0.7,
            Position = UDim2.new(0.075, 0, 0.5, 0),
            Size = UDim2.new(0, 25, 0, 25),
            ZIndex = 11,
            Image = (function()
                return game:GetService("Players"):GetUserThumbnailAsync(Window.User.Anonymous and 1 or game.Players.LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
            end)(),
        },{
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, 64),
            }),
        }),
        _183goat:Create("TextButton", {
            Visible = Window.User.Callback and true or false,
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            TextTransparency = 1,
            ZIndex = 100,
        }),
    })
UserFrame.TextButton.MouseButton1Click:Connect(function()
    task.defer(function()
        pcall(Window.User.Callback)
    end)
end)

    local UserTitle = _183goat:Create("TextLabel", {
        Parent = UserFrame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        RichText = true,
        Size = UDim2.new(1, 0, 1, 0),
        FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Text = Window.User.Anonymous and "Anonymous" or game.Players.LocalPlayer.DisplayName,
        TextTransparency = 0,
        TextSize = 13,
        ZIndex = 11,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = Window.Author,
        ThemeID = {
            TextColor3 = "User.Text|Text"
        }
    }, {
        _183goat:Create("UIPadding", {
            PaddingLeft = UDim.new(0,40),
            PaddingBottom = UDim.new(0,15)
        })
    })
    local UserSub = _183goat:Create("TextLabel", {
        Parent = UserFrame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        RichText = true,
        Size = UDim2.new(1, 0, 1, 0),
        FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Text = Window.User.Anonymous and "@Anonymous" or "@"..game.Players.LocalPlayer.Name,
        TextTransparency = 0.6,
        TextSize = 13,
        ZIndex = 11,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = Window.Author,
        ThemeID = {
            TextColor3 = "User.Text|Text"
        }
    }, {
        _183goat:Create("UIPadding", {
            PaddingLeft = UDim.new(0,40),
            PaddingTop = UDim.new(0,15)
        })
    })

    UserFrame.Visible = Window.User.Enabled or false
    --endUser

    local LeftScroll = _183goat:Create("ScrollingFrame", {
        Parent = TabFrame,
        Active = true,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0., 0),
        Size = UDim2.new(1, 0, 1, -10),
        ScrollBarThickness = 0
    },{
        _183goat:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        }),
        _183goat:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 10),
        })
    })
    LeftScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        LeftScroll.CanvasSize = UDim2.new(0, LeftScroll.UIListLayout.AbsoluteContentSize.X, 0, LeftScroll.UIListLayout.AbsoluteContentSize.Y)
    end)

    local ElementFolder = _183goat:Create("Folder", {
        Parent = Main,
    })

    Window.TabList = Window.TabList or {}
    function Window:SelectTab(i)
        if Window.TabList[i] and Window.TabList[i].Select then
            Window.TabList[i].Select()
        end
    end

    function Window:Tab(Config, type)
        local Tab = {
            Title = Config.Title or "Tab",
            Icon = Config.Icon or nil,
            Border = 1,
            Callback = Config.Callback or function() end
        }

        local TabBack = _183goat:Create("Frame", {
            Parent = type or LeftScroll,
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            AutomaticSize = "Y",
            BorderColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0,
            Size = UDim2.new(0, Window.SideBarWidth - 10, 0, 25),
            BackgroundColor3 = Color3.fromRGB(45, 30, 70), -- Purple Tab Highlight
            BorderSizePixel = 0,
            ZIndex = 4,
            ThemeID = {
                BackgroundColor3 = "Tab.Background|ElementColor"
            }
        },{
            _183goat:Create("UIScale", { Scale = 1 }), -- Added for hover bounce
            _183goat:Create("TextButton", {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 6,
            }),
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            _183goat:Create("UIStroke", {
                Color = Color3.fromRGB(255, 255, 255),
                LineJoinMode = "Round",
                Thickness = 0.6,
                ThemeID = {
                    Color = "Outline"
                }
            },{
                _183goat:Create("UIGradient", {
                    Color = ColorSequence.new(
                        Color3.fromRGB(255, 255, 255), 
                        Color3.fromRGB(255, 255, 255)
                    ),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.1),
                        NumberSequenceKeypoint.new(0.5, 1),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    Rotation = -110
                })
            }),
            _183goat:Create("UIPadding", {
                PaddingBottom = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
            })
        })
        local TabTitle = _183goat:Create("TextLabel", {
            Parent = TabBack,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            RichText = true,
            Size = UDim2.new(1, 0, 0, 25),
            FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            Text = Tab.Title,
            AutomaticSize = "Y",
            TextTransparency = 0,
            TextSize = 13,
            ZIndex = 5,
            TextWrapped = true,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = Window.Author,
            ThemeID = {
                TextColor3 = "Tab.Text|Text"
            }
        }, {
            _183goat:Create("UIPadding", {
                PaddingLeft = UDim.new(0,10)
            })
        })
        local TabIcon
        if Tab.Icon then
            TabIcon = _183goat:Create("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Image = GetIcon(Tab.Icon),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0.5, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(0, 19, 0, 19),
                BorderSizePixel = 0,
                ZIndex = 5,
                Parent = TabBack,
                ThemeID = {
                    ImageColor3 = "Tab.IconColor|IconColor"
                }
            })
            TabTitle.UIPadding.PaddingLeft = UDim.new(0,31)
        end
        TabBack.BackgroundTransparency = 1
        TabTitle.TextTransparency = 0.5
        TabBack.UIStroke.Transparency = 1
        if TabIcon then
            TabIcon.ImageTransparency = 0.5
        end
        
        local ElementFrame = _183goat:Create("Frame", {
            Parent = ElementFolder,
            AnchorPoint = Vector2.new(.97, 0),
            Position = UDim2.new(.97, 0, 0, Window.Topbar.Height+25),
            BorderColor3 = Color3.new(0, 0, 0),
            ClipsDescendants = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, Window.Size.X.Offset-Window.SideBarWidth-8, 0, 0),
            BackgroundColor3 = Color3.fromRGB(22, 12, 38), -- Dark purple
            ZIndex = 4,
            ThemeID = {
                BackgroundColor3 = "SideBar"
            }
        },{
            _183goat:Create("UICorner", {
                CornerRadius = UDim.new(0, 5),
            }),
        })
        local RightScroll = _183goat:Create("ScrollingFrame", {
            Parent = ElementFrame,
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            CanvasSize = UDim2.new(0,0,0,0),
            Position = UDim2.new(0,0,0,5),
            Size = UDim2.new(1, 0, 0.97, 0),
            ScrollBarThickness = 3,
            ZIndex = 10,
            --AutomaticSize = Y
        },{
            _183goat:Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            }),
            _183goat:Create("UIPadding", {
                --PaddingTop = UDim.new(0,5),
                PaddingBottom = UDim.new(0,5),
                PaddingLeft = UDim.new(0,5)
            })
        })

        RightScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            RightScroll.CanvasSize = UDim2.new(0, RightScroll.UIListLayout.AbsoluteContentSize.X, 0, RightScroll.UIListLayout.AbsoluteContentSize.Y)
        end)
       local function SelectTab()
            for i, v in next, ElementFolder:GetChildren() do
                if v:IsA("GuiObject") then
                    v.Visible = false
                    v.Size = UDim2.new(0, Window.Size.X.Offset-Window.SideBarWidth-8, 0, 0)
                end
            end
            ElementFrame.Visible = true
            RightScroll.Visible = true
            Window.ActiveElementFrame = ElementFrame
            -- Extra bounce for tab switching
            Utility:TweenObject(ElementFrame, {Size = UDim2.new(0, Window.Size.X.Offset-Window.SideBarWidth-8, 0, Window.Size.Y.Offset - Window.Topbar.Height-20 - (Tags > 0 and 37 or 0))}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Utility:TweenObject(ElementFrame, {BackgroundTransparency = 0.2}, 0.2)
            for _, v in next, Window.Tabs do
                Utility:TweenObject(v, {BackgroundTransparency = 1}, 0.2)
                for _, obj in ipairs(v:GetChildren()) do
                    if obj:IsA("TextLabel") then
                        Utility:TweenObject(obj, {TextTransparency = 0.5}, 0.2)
                    elseif obj:IsA("UIStroke") then
                        Utility:TweenObject(obj, {Transparency = 1}, 0.2)
                    elseif obj:IsA("ImageLabel") then
                        Utility:TweenObject(obj, {ImageTransparency = 0.5}, 0.2)
                    end
                end
            end
            Utility:TweenObject(TabBack, {BackgroundTransparency = (Tab.Border and 0.6 or 1)}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            Utility:TweenObject(TabBack.UIStroke, {Transparency = (Tab.Border and 0 or 1)}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            Utility:TweenObject(TabTitle, {TextTransparency = 0}, 0.2)
            if TabIcon then
                Utility:TweenObject(TabIcon, {ImageTransparency = 0}, 0.2)
            end
            Tab.Callback()
        end

        TabBack.TextButton.MouseEnter:Connect(function()
            Utility:TweenObject(TabBack.UIScale, {Scale = 1.05}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
        TabBack.TextButton.MouseLeave:Connect(function()
            Utility:TweenObject(TabBack.UIScale, {Scale = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
        TabBack.TextButton.MouseButton1Click:Connect(function()
            -- Insane click bounce on tab
            Utility:TweenObject(TabBack.UIScale, {Scale = 0.9}, 0.1, Enum.EasingStyle.Quad)
            task.delay(0.1, function() Utility:TweenObject(TabBack.UIScale, {Scale = 1}, 0.2, Enum.EasingStyle.Back) end)
            SelectTab()
        end)
        Tab.Select = SelectTab

        table.insert(Window.Tabs, TabBack)
        table.insert(Window.TabOrder, Tab.Title)
        table.insert(Window.TabList, Tab)
        --Window.SearchIndex[Tab.Title] = {}

        --print(Config.Parent)
        function Tab:Paragraph(Config,type)
            local Paragraph = {
                Title = Config.Title or "Paragraph",
                Desc = Config.Desc or nil,
                Icon = Config.Icon or nil,
                Color = Config.Color,
                Thumbnail = Config.Thumbnail,
                ThumbnailPos = Config.ThumbnailPos or "Up",
                ScaleType = Config.ScaleType or "Crop",
                ThumbnailSize = Config.ThumbnailSize or 54,
                SizeY = 40
            }
            local Colors = {
                Red    = Color3.fromRGB(255, 45, 85),
                Green  = Color3.fromRGB(52, 255, 130),
                Blue   = Color3.fromRGB(64, 156, 255),
                Orange = Color3.fromRGB(255, 159, 10),
                Purple = Color3.fromRGB(191, 90, 255),
                Yellow = Color3.fromRGB(255, 224, 20),
                Pink   = Color3.fromRGB(255, 55, 130),
                Cyan   = Color3.fromRGB(50, 220, 255),
                Mint   = Color3.fromRGB(50, 255, 200),
                Coral  = Color3.fromRGB(255, 100, 60),
            }
            local ResolvedColor = nil
            if typeof(Paragraph.Color) == "Color3" then
                ResolvedColor = Paragraph.Color
            elseif typeof(Paragraph.Color) == "string" then
                ResolvedColor = Colors[Paragraph.Color]
                if not ResolvedColor then
                    warn("_183goat: Unknown color name '" .. Paragraph.Color .. "'")
                end
            end
            local ParagraphThemeID = nil
            if not ResolvedColor then
                ParagraphThemeID = {BackgroundColor3 = "Paragraph.Background|ElementColor"}
            end
            local StrokeThemeID = nil
            if not ResolvedColor then
                StrokeThemeID = {Color = "Outline"}
            end
            local ParagraphFrame = _183goat:Create("Frame", {
                Parent = RightScroll,
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                AutomaticSize = "Y",
                ClipsDescendants = true,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(0, ElementFrame.Size.X.Offset - 10, 0, Paragraph.SizeY),
                BackgroundColor3 = ResolvedColor or Color3.fromRGB(30, 15, 50), -- Deep paragraph purple
                BorderSizePixel = 0,
                ZIndex = 15,
                ThemeID = ParagraphThemeID
            },{
                _183goat:Create("UIStroke", {
                    Color = ResolvedColor,
                    LineJoinMode = "Round",
                    Thickness = 0.6,
                    ThemeID = StrokeThemeID
                },{
                    _183goat:Create("UIGradient", {
                        Color = ColorSequence.new(
                            Color3.fromRGB(255, 255, 255), 
                            Color3.fromRGB(255, 255, 255)
                        ),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.1),
                            NumberSequenceKeypoint.new(0.5, 1),
                            NumberSequenceKeypoint.new(1, 1)
                        }),
                        Rotation = -110
                    })
                }),
                _183goat:Create("UICorner", {
                    CornerRadius = UDim.new(0, 12),
                }),
                _183goat:Create("UIPadding", {
                    PaddingTop = UDim.new(0,5),
                    PaddingLeft = UDim.new(0,5),
                    PaddingBottom = UDim.new(0,5)
                }),
                _183goat:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1)
                }),
                _183goat:Create("Frame", {
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.new(1, 0, 0, 0),
                    LayoutOrder = 2,
                    ClipsDescendants = true,
                    ZIndex = 16,
                },{
                    _183goat:Create("Frame", {
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Size = UDim2.new(1, 0, 0, 0),
                        ClipsDescendants = true,
                        ZIndex = 16,
                    },{
                        _183goat:Create("UIListLayout", {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 1)
                        }),
                        _183goat:Create("UIPadding", {
                            PaddingTop = UDim.new(0,9),
                        })
                    })
                }),
            })

            local Thumbnail
            if Paragraph.Thumbnail then
                Thumbnail = _183goat:Create("ImageLabel", {
                    AnchorPoint = Vector2.new(0.1, 0.5),
                    Image = Paragraph.Thumbnail,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.1, 0, 0.5, 0),
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(1, -5, 0, Paragraph.ThumbnailSize),
                    ScaleType = Paragraph.ScaleType,
                    ZIndex = 17,
                    LayoutOrder = (Paragraph.ThumbnailPos == "Up") and 1 or 3,
                    Parent = ParagraphFrame,
                    ImageTransparency = 0,
                    ThemeID = {
                        ImageColor3 = "Paragraph.IconColor|IconColor"
                    },
                },{
                    _183goat:Create("UICorner", {
                        CornerRadius = UDim.new(0, 16),
                    }),
                })
            end

            local Title = Text(ParagraphFrame.Frame.Frame, Paragraph.Title, {
                Size = UDim2.new(0, 0, 0, 5),
                AutomaticSize = "XY",
                ZIndex = 16,
                FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 13,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                RichText = true,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeID = {
                    TextColor3 = "Paragraph.Text|Text"
                }
            }, {
                _183goat:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 5)
                })
            })
            Title.Position = UDim2.new(0, 0, 0, 0)
            local Desc = Text(ParagraphFrame.Frame.Frame, Paragraph.Desc, {
                Size = UDim2.new(0, 0, 0, 5),
                AutomaticSize = "XY",
                ZIndex = 16,
                FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 12,
                TextTransparency = 0.7,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                RichText = true,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = Paragraph.Desc ~= nil,
                ThemeID = {
                    TextColor3 = "Paragraph.Text|Text"
                }
            }, {
                _183goat:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 5)
                })
            })
            local Icon
            if Paragraph.Icon then
                Icon = _183goat:Create("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Image = GetIcon(Paragraph.Icon),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0.5, 0),
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(0, 22, 0, 22),
                    ZIndex = 17,
                    Parent = ParagraphFrame.Frame,
                    ImageTransparency = 0,
                    ThemeID = {
                        ImageColor3 = "Paragraph.IconColor|IconColor"
                    }
                })
                Title.UIPadding.PaddingLeft = UDim.new(0,35)
                Desc.UIPadding.PaddingLeft = UDim.new(0,35)
            end

            function Paragraph:SetTitle(Text)
                Title.SetText(Text)
            end
            function Paragraph:SetThumbnail(v)
                if Paragraph.Thumbnail then Paragraph.Thumbnail.Image = v else warn("Thumbnail Not Found In Paragraph!") end
            end

            function Paragraph:SetPos(v)
                if Paragraph.Thumbnail then Paragraph.Thumbnail.LayoutOrder = (v == "Up") and 1 or 3 else warn("Thumbnail Not Found In Paragraph!") end
            end

            function Paragraph:SetThumbnailSize(v)
                if Paragraph.Thumbnail then Paragraph.Thumbnail.Size = UDim2.new(1, -5, 0, v) else warn("Thumbnail Not Found In Paragraph!") end
            end

            table.insert(Window.SearchIndex, {
                Title = Paragraph.Title, Desc = Paragraph.Desc, Icon = Paragraph.Icon,
                Type = "Paragraph", TabTitle = Tab.Title,
                SelectFn = SelectTab, Frame = ParagraphFrame, RightScroll = RightScroll,
            })
            return Paragraph
        end
function Tab:Paragraph1(Config,type)
            local Paragraph1 = {
                Title = Config.Title or "Paragraph",
                Desc = Config.Desc or nil,
                Icon = Config.Icon or nil,
                Color = Config.Color,
                Thumbnail = Config.Thumbnail,
                ThumbnailPos = Config.ThumbnailPos or "Up",
                ScaleType = Config.ScaleType or "Crop",
                ThumbnailSize = Config.ThumbnailSize or 35,
                SizeY = 25
            }
            local Colors = {
                Red    = Color3.fromRGB(255, 45, 85),
                Green  = Color3.fromRGB(52, 255, 130),
                Blue   = Color3.fromRGB(64, 156, 255),
                Orange = Color3.fromRGB(255, 159, 10),
                Purple = Color3.fromRGB(191, 90, 255),
                Yellow = Color3.fromRGB(255, 224, 20),
                Pink   = Color3.fromRGB(255, 55, 130),
                Cyan   = Color3.fromRGB(50, 220, 255),
                Mint   = Color3.fromRGB(50, 255, 200),
                Coral  = Color3.fromRGB(255, 100, 60),
            }
            local ResolvedColor = nil
            if typeof(Paragraph.Color) == "Color3" then
                ResolvedColor = Paragraph.Color
            elseif typeof(Paragraph.Color) == "string" then
                ResolvedColor = Colors[Paragraph.Color]
                if not ResolvedColor then
                    warn("_183goat: Unknown color name '" .. Paragraph.Color .. "'")
                end
            end
            local ParagraphThemeID = nil
            if not ResolvedColor then
                ParagraphThemeID = {BackgroundColor3 = "Paragraph.Background|ElementColor"}
            end
            local StrokeThemeID = nil
            if not ResolvedColor then
                StrokeThemeID = {Color = "Outline"}
            end
            local ParagraphFrame = _183goat:Create("Frame", {
                Parent = RightScroll,
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                AutomaticSize = "Y",
                ClipsDescendants = true,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(0, ElementFrame.Size.X.Offset - 10, 0, Paragraph.SizeY),
                BackgroundColor3 = ResolvedColor or Color3.fromRGB(30, 15, 50), -- Deep paragraph purple
                BorderSizePixel = 0,
                ZIndex = 15,
                ThemeID = ParagraphThemeID
            },{
                _183goat:Create("UIStroke", {
                    Color = ResolvedColor,
                    LineJoinMode = "Round",
                    Thickness = 0.6,
                    ThemeID = StrokeThemeID
                },{
                    _183goat:Create("UIGradient", {
                        Color = ColorSequence.new(
                            Color3.fromRGB(255, 255, 255), 
                            Color3.fromRGB(255, 255, 255)
                        ),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.1),
                            NumberSequenceKeypoint.new(0.5, 1),
                            NumberSequenceKeypoint.new(1, 1)
                        }),
                        Rotation = -110
                    })
                }),
                _183goat:Create("UICorner", {
                    CornerRadius = UDim.new(0, 12),
                }),
                _183goat:Create("UIPadding", {
                    PaddingTop = UDim.new(0,5),
                    PaddingLeft = UDim.new(0,5),
                    PaddingBottom = UDim.new(0,5)
                }),
                _183goat:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1)
                }),
                _183goat:Create("Frame", {
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.new(1, 0, 0, 0),
                    LayoutOrder = 2,
                    ClipsDescendants = true,
                    ZIndex = 16,
                },{
                    _183goat:Create("Frame", {
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Size = UDim2.new(1, 0, 0, 0),
                        ClipsDescendants = true,
                        ZIndex = 16,
                    },{
                        _183goat:Create("UIListLayout", {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 1)
                        }),
                        _183goat:Create("UIPadding", {
                            PaddingTop = UDim.new(0,9),
                        })
                    })
                }),
            })

            local Thumbnail
            if Paragraph.Thumbnail then
                Thumbnail = _183goat:Create("ImageLabel", {
                    AnchorPoint = Vector2.new(0.1, 0.5),
                    Image = Paragraph.Thumbnail,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.1, 0, 0.5, 0),
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(1, -5, 0, Paragraph.ThumbnailSize),
                    ScaleType = Paragraph.ScaleType,
                    ZIndex = 17,
                    LayoutOrder = (Paragraph.ThumbnailPos == "Up") and 1 or 3,
                    Parent = ParagraphFrame,
                    ImageTransparency = 0,
                    ThemeID = {
                        ImageColor3 = "Paragraph.IconColor|IconColor"
                    },
                },{
                    _183goat:Create("UICorner", {
                        CornerRadius = UDim.new(0, 16),
                    }),
                })
            end

            local Title = Text(ParagraphFrame.Frame.Frame, Paragraph.Title, {
                Size = UDim2.new(0, 0, 0, 5),
                AutomaticSize = "XY",
                ZIndex = 16,
                FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 13,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                RichText = true,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ThemeID = {
                    TextColor3 = "Paragraph.Text|Text"
                }
            }, {
                _183goat:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 5)
                })
            })
            Title.Position = UDim2.new(0, 0, 0, 0)
            local Desc = Text(ParagraphFrame.Frame.Frame, Paragraph.Desc, {
                Size = UDim2.new(0, 0, 0, 5),
                AutomaticSize = "XY",
                ZIndex = 16,
                FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 12,
                TextTransparency = 0.7,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                RichText = true,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = Paragraph.Desc ~= nil,
                ThemeID = {
                    TextColor3 = "Paragraph.Text|Text"
                }
            }, {
                _183goat:Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 5)
                })
            })
            local Icon
            if Paragraph.Icon then
                Icon = _183goat:Create("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Image = GetIcon(Paragraph.Icon),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0.5, 0),
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(0, 22, 0, 22),
                    ZIndex = 17,
                    Parent = ParagraphFrame.Frame,
                    ImageTransparency = 0,
                    ThemeID = {
                        ImageColor3 = "Paragraph.IconColor|IconColor"
                    }
                })
                Title.UIPadding.PaddingLeft = UDim.new(0,35)
                Desc.UIPadding.PaddingLeft = UDim.new(0,35)
            end

            function Paragraph:SetTitle(Text)
                Title.SetText(Text)
            end
            function Paragraph:SetThumbnail(v)
                if Paragraph.Thumbnail then Paragraph.Thumbnail.Image = v else warn("Thumbnail Not Found In Paragraph!") end
            end

            function Paragraph:SetPos(v)
                if Paragraph.Thumbnail then Paragraph.Thumbnail.LayoutOrder = (v == "Up") and 1 or 3 else warn("Thumbnail Not Found In Paragraph!") end
            end

            function Paragraph:SetThumbnailSize(v)
                if Paragraph.Thumbnail then Paragraph.Thumbnail.Size = UDim2.new(1, -5, 0, v) else warn("Thumbnail Not Found In Paragraph!") end
            end

            table.insert(Window.SearchIndex, {
                Title = Paragraph.Title, Desc = Paragraph.Desc, Icon = Paragraph.Icon,
                Type = "Paragraph", TabTitle = Tab.Title,
                SelectFn = SelectTab, Frame = ParagraphFrame, RightScroll = RightScroll,
            })
            return Paragraph
        end

        function Tab:Button(Config)
            local Button = {
                Title = Config.Title or "Button",
                Desc = Config.Desc,
                Icon = Config.Icon or "mouse-pointer-click",
                Locked = Config.Locked,
                SizeY = Config.SizeY or 40,
                Callback = Config.Callback or function() end
            }

            local Beeee, ButtonFrame, Inner = Utility:Element(RightScroll, ElementFrame, Button.SizeY, "Button")
            local ButtonTRG = _183goat:Create("TextButton", {
                Parent = Beeee,
                Size = UDim2.new(1, 0, 1, 0),
                TextTransparency = 1,
                BackgroundTransparency = 1,
                ZIndex = 25,
            })
            
            ButtonTRG.MouseEnter:Connect(function()
                -- INSANE Hover expansion
                Utility:TweenObject(Beeee.UIScale, {Scale = 1.02}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                Utility:TweenObject(ButtonFrame, {BackgroundTransparency = 0.2}, 0.15) 
            end)
            ButtonTRG.MouseLeave:Connect(function()
                Utility:TweenObject(Beeee.UIScale, {Scale = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                Utility:TweenObject(ButtonFrame, {BackgroundTransparency = 0.5}, 0.15) 
            end)

            ButtonTRG.MouseButton1Click:Connect(function()
                if Button.Locked then return end
                spawn(function() pcall(Button.Callback) end)

                -- Extreme Click Pulse
                Utility:TweenObject(Beeee.UIScale, {Scale = 0.94}, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                Utility:TweenObject(ButtonFrame, {BackgroundTransparency = 0}, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                -- Huge neon ripple effect
                local ripple = _183goat:Create("UIStroke", {
                    Parent = ButtonFrame,
                    Color = Color3.fromRGB(200, 50, 255),
                    Thickness = 2,
                    Transparency = 0,
                    ZIndex = 30,
                })
                Utility:TweenObject(ripple, {Thickness = 15, Transparency = 1}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                task.delay(0.5, function() ripple:Destroy() end)

                task.wait(0.1)
                Utility:TweenObject(ButtonFrame, {BackgroundTransparency = 0.5}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                Utility:TweenObject(Beeee.UIScale, {Scale = 1}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)

            local Title, Desc = Utility:ElText(Inner, Button.Title, Button.Desc, "Button")

            local Icon
            if Button.Icon then
                Icon = _183goat:Create("ImageLabel", {
                    AnchorPoint = Vector2.new(.96, 0.5),
                    Image = GetIcon(Button.Icon),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(.96, 0, 0.5, 0),
                    Size = UDim2.new(0, 20, 0, 20),
                    ZIndex = 16,
                    Parent = ButtonFrame,
                    ThemeID = { ImageColor3 = "Button.Text|Text"}
                })
            end

            function Button:Lock()
                Button.Locked = true
                LockedElm(Beeee, true)
                end
            function Button:UnLock()
                Button.Locked = false
                LockedElm(Beeee, false)
            end

            if Button.Locked then Button:Lock() end

            function Button:SetTitle(t)
                Title.SetText(t) 
            end
            function Button:SetDesc(t)
                Desc.Visible = true
                Desc.SetText(t)
            end
            function Button:Close() 
                Beeee:Destroy()
            end
            if Button.Desc then 
                Button:SetDesc(Button.Desc)
            end

            Utility:Search(Window, {Title = Button.Title, Desc = Button.Desc, Icon = "mouse-pointer-click",Type = "Button", TabTitle = Tab.Title, SelectFn = SelectTab, Frame = Beeee, RightScroll = RightScroll,})
            return Button
        end

        function Tab:Toggle(Config,type)
            local Togglee = {
                Title = Config.Title or "Toggle",
                Desc = Config.Desc,
                Icon = Config.Icon or "mouse-pointer-click",
                Default = Config.Default or false,
                SizeY = Config.SizeY or 40,
                Locked = Config.Locked,
                Callback = Config.Callback or function() end
            }
            local Beeee, ToggleFrame, Inner = Utility:Element(RightScroll, ElementFrame, Togglee.SizeY, "Toggle")
            local ToggleTRG = _183goat:Create("TextButton", {
                Parent = Beeee,
                Size = UDim2.new(1, 0, 1, 0),
                TextTransparency = 1,
                BackgroundTransparency = 1,
                ZIndex = 25,
            })
            
            ToggleTRG.MouseEnter:Connect(function()
                Utility:TweenObject(Beeee.UIScale, {Scale = 1.02}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
            ToggleTRG.MouseLeave:Connect(function()
                Utility:TweenObject(Beeee.UIScale, {Scale = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
            
            local Title, Desc = Utility:ElText(Inner, Togglee.Title, Togglee.Desc, "Button")

             local ToggleV = _183goat:Create("Frame", {
                    Parent = ToggleFrame,
                    AnchorPoint = Vector2.new(.96, 0.5),
                    Position = UDim2.new(0.96, -5, 0.5, 0),
                    ClipsDescendants = false,
                    BackgroundTransparency = 0.5,
                    Size = UDim2.new(0, 46, 0, 22),
                    ZIndex = 15,
                    BackgroundColor3 = Color3.fromRGB(65, 30, 110), -- Placeholder deep purple
                    ThemeID = {
                        BackgroundColor3 = "Toggle.Placeholder|Placeholder"
                    }
                },{
                _183goat:Create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 3, 0.5, 0),
                    ClipsDescendants = true,
                    BackgroundTransparency = 0.8,
                    Size = UDim2.new(0, 16, 0, 16),
                    ZIndex = 15,
                    BackgroundColor3 = Color3.fromRGB(200, 50, 255),
                    ThemeID = {
                        BackgroundColor3 = "Toggle.ToggleVal|Accent"
                    }
                },{
                    _183goat:Create("UICorner", {
                        CornerRadius = UDim.new(0, 32),
                    }),
                }),
                _183goat:Create("UICorner", {
                    CornerRadius = UDim.new(0, 12),
                }),
            })

            function Togglee:Lock()
                Togglee.Locked = true
                LockedElm(Beeee,true)
            end
            function Togglee:UnLock()
                Togglee.Locked = false
                LockedElm(Beeee,false)
            end
            if Togglee.Locked then
                Togglee:Lock()
            end
            function Togglee:SetTitle(Text)
                Title.SetText(Text)
            end

            function Togglee:SetDesc(Text)
                Desc.Visible = true
                Desc.SetText(Text)
            end

            function Togglee:Close()
                Togglee:Destroy()
            end

            if Togglee.Desc then
                Togglee:SetDesc(Togglee.Desc)
            end

            local Val = Togglee.Default
  function Togglee:SetValue(newValue)
                Val = newValue
                if newValue then
                    -- Insane bouncy snap
                    Utility:TweenObject(ToggleV.Frame, {Position = UDim2.new(1, -19, 0.5, 0),BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
                    Utility:TweenObject(ToggleV, {BackgroundColor3 = Color3.fromRGB(180, 50, 255), BackgroundTransparency = 0.15}, 0.25)

                    local flash = _183goat:Create("UIStroke", {
                        Parent = ToggleV,
                        Color = Color3.fromRGB(230, 140, 255),
                        Thickness = 2,
                        Transparency = 0,
                        ZIndex = 20,
                    })
                    Utility:TweenObject(flash, {Thickness = 8, Transparency = 1}, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    task.delay(0.45, function() flash:Destroy() end)
                else
                    Utility:TweenObject(ToggleV.Frame, {Position = UDim2.new(0, 3, 0.5, 0),BackgroundTransparency = 0.8}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    Utility:TweenObject(ToggleV, {BackgroundColor3 = Color3.fromRGB(65, 30, 110), BackgroundTransparency = 0.5}, 0.2)
                end

                spawn(function()
                    pcall(Togglee.Callback, Val)
                end)
                return Togglee
            end


            Togglee:SetValue(Val)
            ToggleTRG.MouseButton1Down:Connect(function()
                -- Shrink down dot slightly on press
                Utility:TweenObject(ToggleV.Frame, {Size = UDim2.new(0, 14, 0, 10),BackgroundTransparency = (Val and 0 or 0.8)}, 0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            end)
            ToggleTRG.MouseButton1Up:Connect(function()
                Utility:TweenObject(ToggleV.Frame, {Size = UDim2.new(0, 16, 0, 16),BackgroundTransparency = (Val and 0 or 0.8)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
            ToggleTRG.MouseLeave:Connect(function()
                Utility:TweenObject(ToggleV.Frame, {Size = UDim2.new(0, 16, 0, 16),BackgroundTransparency = (Val and 0 or 0.8)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
            ToggleTRG.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    Utility:TweenObject(ToggleV.Frame, {Size = UDim2.new(0, 16, 0, 16),BackgroundTransparency = (Val and 0 or 0.8)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end
            end)
            ToggleTRG.MouseButton1Click:Connect(function()
                if Togglee.Locked then return end
                Val = not Val
                
                -- Pop the whole container on toggle
                Utility:TweenObject(Beeee.UIScale, {Scale = 0.95}, 0.1, Enum.EasingStyle.Quad)
                task.delay(0.1, function() Utility:TweenObject(Beeee.UIScale, {Scale = 1.02}, 0.2, Enum.EasingStyle.Back) end)
                
                Togglee:SetValue(Val)
            end)
            Utility:Search(Window, {Title = Togglee.Title, Desc = Togglee.Desc, Icon = "toggle-left",Type = "Toggle", TabTitle = Tab.Title, SelectFn = SelectTab, Frame = Beeee, RightScroll = RightScroll,})
            return Togglee
        end
        function Tab:Slider(Config)
            local Slider = {
                Title = Config.Title or "Slider",
                Desc = Config.Desc or nil,
                Locked = Config.Locked or false,
                Step = Config.Step or 1,
                Value = Config.Value or { Min = 0, Max = 100, Default = 50 },
                Callback = Config.Callback or function() end,
                Locked = Config.Locked,
                SizeY = Config.SizeY or 40,
            }
            local Beeee, SliderElement, Inner = Utility:Element(RightScroll, ElementFrame, Slider.SizeY, "Slider")
            
            Beeee.MouseEnter:Connect(function()
                Utility:TweenObject(Beeee.UIScale, {Scale = 1.02}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
            Beeee.MouseLeave:Connect(function()
                Utility:TweenObject(Beeee.UIScale, {Scale = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
            
            local Title, Desc = Utility:ElText(Inner, Slider.Title, Slider.Desc, "Button")

            local TextContainer = _183goat:Create("Frame", {
                Parent = SliderElement,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ClipsDescendants = true,
                ZIndex = 16,
            }, {
                _183goat:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1),
                }),
                _183goat:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 9),
                }),
            })

            local ValueFrame = _183goat:Create("Frame", {
                Parent = SliderElement,
                AnchorPoint = Vector2.new(0.96, 0.5),
                Position = UDim2.new(0.96, -40, 0.5, 0),
                ClipsDescendants = true,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(0, 110, 0, 16),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(65, 30, 110), -- Placeholder Deep Purple
                ZIndex = 15,
                ThemeID = {
                    BackgroundColor3 = "Slider.Placeholder|Placeholder"
                }
            }, {
                _183goat:Create("UICorner", {
                    CornerRadius = UDim.new(0, 12),
                }),
                _183goat:Create("UIStroke", {
                    LineJoinMode = "Round",
                    Thickness = 0.6,
                    ThemeID = {
                        Color = "Outline"
                    }
                }, {
                    _183goat:Create("UIGradient", {
                        Color = ColorSequence.new(
                            Color3.fromRGB(255, 255, 255),
                            Color3.fromRGB(255, 255, 255)
                        ),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.1),
                            NumberSequenceKeypoint.new(0.5, 1),
                            NumberSequenceKeypoint.new(1, 1)
                        }),
                        Rotation = -100
                    })
                }),
            })

            local DropValue = _183goat:Create("Frame", {
                Parent = ValueFrame,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(200, 50, 255), -- Active fill slider
                ZIndex = 16,
                ThemeID = {
                    BackgroundColor3 = "Slider.SliderPart|Accent"
                }
            }, {

                _183goat:Create("UICorner", {
                    CornerRadius = UDim.new(0, 12),
                }),
            })

            local BGFrame = _183goat:Create("Frame", {
                Parent = SliderElement,
                AnchorPoint = Vector2.new(0.96, 0.5),
                Position = UDim2.new(0.96, 0, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(45, 20, 80), -- Rich slider box
                BackgroundTransparency = 0.5,
                Size = UDim2.new(0, 29, 0, 22),
                ClipsDescendants = true,
                BorderSizePixel = 0,
                ZIndex = 15,
                ThemeID = {
                    BackgroundColor3 = "Slider.Placeholder|Placeholder"
                }
            }, {
                _183goat:Create("UICorner", {
                    CornerRadius = UDim.new(0, 10),
                }),
                _183goat:Create("UIStroke", {
                    LineJoinMode = "Round",
                    Thickness = 0.6,
                    ThemeID = {
                        Color = "Outline"
                    }
                }, {
                    _183goat:Create("UIGradient", {
                        Color = ColorSequence.new(
                            Color3.fromRGB(255, 255, 255),
                            Color3.fromRGB(255, 255, 255)
                        ),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.1),
                            NumberSequenceKeypoint.new(0.5, 1),
                            NumberSequenceKeypoint.new(1, 1)
                        }),
                        Rotation = -110
                    })
                }),
            })

            local SliderTRG = _183goat:Create("TextButton", {
                Parent = ValueFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextTransparency = 1,
                ZIndex = 25,
            })
            
            SliderTRG.MouseButton1Down:Connect(function()
                Utility:TweenObject(DropValue, {BackgroundColor3 = Color3.fromRGB(230, 140, 255)}, 0.15)
            end)
            SliderTRG.MouseButton1Up:Connect(function()
                Utility:TweenObject(DropValue, {BackgroundColor3 = Color3.fromRGB(200, 50, 255)}, 0.25)
            end)

            local BGBox = _183goat:Create("TextBox", {
                Parent = BGFrame,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                TextTransparency = 0,
                ZIndex = 16,
                Size = UDim2.new(1, 0, 1, 0),
                Text = tostring(Slider.Value.Default or 0),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                FontFace = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 10,
                Theme
