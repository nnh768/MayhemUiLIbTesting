-- MayhemUI (ModuleScript)
-- Version 1.0.0 - For Exploit Script GUIs

local MayhemUI = {}
MayhemUI.__index = MayhemUI

--[[
    Services & Constants
]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
-- local CollectionService = game:GetService("CollectionService") -- For potential global updates (future enhancement)

local SETTINGS = {
    Theme = "Dark",
    AccentColor = Color3.fromRGB(0, 122, 204), -- Default Mayhem Blue
    Font = Enum.Font.GothamSemibold,
    BaseZIndex = 10000, -- High ZIndex for exploit UIs to overlay game UI
    AnimationSpeed = 0.15,
}

local THEMES = {
    Dark = {
        WindowBackground = Color3.fromRGB(28, 28, 28),
        TitleBarBackground = Color3.fromRGB(38, 38, 38),
        ContentBackground = Color3.fromRGB(32, 32, 32),
        ElementBackground = Color3.fromRGB(42, 42, 42),
        ElementHover = Color3.fromRGB(52, 52, 52),
        ElementActive = Color3.fromRGB(62, 62, 62),
        Border = Color3.fromRGB(55, 55, 55),
        PrimaryText = Color3.fromRGB(235, 235, 235),
        SecondaryText = Color3.fromRGB(170, 170, 170),
        DisabledText = Color3.fromRGB(90, 90, 90),
        ScrollBar = Color3.fromRGB(65, 65, 65),
    },
    Light = {
        WindowBackground = Color3.fromRGB(248, 248, 248),
        TitleBarBackground = Color3.fromRGB(238, 238, 238),
        ContentBackground = Color3.fromRGB(242, 242, 242),
        ElementBackground = Color3.fromRGB(228, 228, 228),
        ElementHover = Color3.fromRGB(218, 218, 218),
        ElementActive = Color3.fromRGB(208, 208, 208),
        Border = Color3.fromRGB(200, 200, 200),
        PrimaryText = Color3.fromRGB(25, 25, 25),
        SecondaryText = Color3.fromRGB(85, 85, 85),
        DisabledText = Color3.fromRGB(165, 165, 165),
        ScrollBar = Color3.fromRGB(195, 195, 195),
    }
}
local CurrentTheme = THEMES[SETTINGS.Theme]

local ActiveTweens = setmetatable({}, {__mode = "k"})

--[[ Utility Functions ]]
local function Create(className, properties)
    local inst = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        inst[prop] = value
    end
    return inst
end

local function Animate(instance, propertyTable, speedOverride, easingStyle, easingDirection)
    if ActiveTweens[instance] then ActiveTweens[instance]:Cancel(); ActiveTweens[instance] = nil end
    local tweenInfo = TweenInfo.new(
        speedOverride or SETTINGS.AnimationSpeed,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, propertyTable)
    ActiveTweens[instance] = tween
    tween.Completed:Connect(function() ActiveTweens[instance] = nil end)
    tween:Play()
    return tween
end

-- Custom Signal Implementation
local Signal = {}
Signal.__index = Signal
function Signal.new() local self = setmetatable({}, Signal); self._connections = {}; return self end
function Signal:Connect(func) assert(type(func) == "function", "Signal:Connect expects a function."); local c = {}; table.insert(self._connections, {f=func, id=c}); return c end
function Signal:Disconnect(id) for i=#self._connections,1,-1 do if self._connections[i].id==id then table.remove(self._connections,i); return end end end
function Signal:Fire(...) for _,c in ipairs(self._connections) do task.spawn(c.f, ...) end end
function Signal:Destroy() for i=#self._connections,1,-1 do table.remove(self._connections,i) end end

--[[ Base UI Element ]]
local BaseElement = {}
BaseElement.__index = BaseElement
function BaseElement:InitBase(elementType)
    self.Type = elementType; self.Instance = nil; self.Visible = true; self.Enabled = true
    self.ParentUI = nil; self.ChildrenUI = {}; self.Connections = {}; self.OnDestroy = Signal.new()
end
function BaseElement:SetParent(robloxParentInstance) if self.Instance then self.Instance.Parent = robloxParentInstance end end
function BaseElement:SetVisible(v) self.Visible=v; if self.Instance and self.Instance:IsA("GuiObject") then self.Instance.Visible=v end for _,c in ipairs(self.ChildrenUI) do c:SetVisible(v) end end
function BaseElement:SetEnabled(e) self.Enabled=e; if self.Instance and self.Instance:IsA("GuiButton") then self.Instance.AutoButtonColor = not e end end
function BaseElement:_addConnection(rbxConn) table.insert(self.Connections, rbxConn) end
function BaseElement:Destroy()
    self.OnDestroy:Fire(); self.OnDestroy:Destroy()
    for _,c in ipairs(self.ChildrenUI) do c:Destroy() end; table.clear(self.ChildrenUI)
    for _,c in ipairs(self.Connections) do c:Disconnect() end; table.clear(self.Connections)
    if ActiveTweens[self.Instance] then ActiveTweens[self.Instance]:Cancel(); ActiveTweens[self.Instance]=nil end
    if self.Instance then self.Instance:Destroy(); self.Instance=nil end
    setmetatable(self, nil)
end
local function NewElement(elementType, initializerFunc)
    local obj = setmetatable({}, BaseElement); obj:InitBase(elementType)
    if initializerFunc then initializerFunc(obj) end
    return obj
end

--==============================================================================
-- Window Component
--==============================================================================
MayhemUI.Window = {}
MayhemUI.Window.__index = setmetatable({}, BaseElement)

function MayhemUI.Window.new(title, size, position, draggable, closable)
    local self = NewElement("Window")
    setmetatable(self, MayhemUI.Window)

    size = size or UDim2.fromOffset(450, 350)
    position = position or UDim2.fromScale(0.5, 0.5) -- Centered by default
    draggable = draggable == nil and true or draggable
    closable = closable == nil and true or closable
    
    self.Instance = Create("Frame", {
        Name = "MayhemWindow", Size = size, Position = position, AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CurrentTheme.WindowBackground, BorderSizePixel = 1, BorderColor3 = CurrentTheme.Border,
        Active = true, Draggable = false, Visible = true, ZIndex = SETTINGS.BaseZIndex, ClipsDescendants = true,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self.Instance })

    local titleBarHeight = 30
    self.TitleBar = Create("Frame", { Name = "TitleBar", Parent = self.Instance, Size = UDim2.new(1, 0, 0, titleBarHeight), BackgroundColor3 = CurrentTheme.TitleBarBackground, BorderSizePixel = 0, ZIndex = self.Instance.ZIndex + 1 })
    local titleCorner = Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = self.TitleBar})
    -- Quick hack for top-only corners on title bar (could be improved with 9-slice or multiple frames)
    task.defer(function() if self.TitleBar then Create("Frame", {Name="MaskBottom", Parent=self.TitleBar, BackgroundColor3=self.TitleBar.BackgroundColor3, Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,1,-5.9), BorderSizePixel=0, ZIndex = self.TitleBar.ZIndex-1}) end end)


    self.TitleLabel = Create("TextLabel", { Name = "TitleLabel", Parent = self.TitleBar, Size = UDim2.new(1, -(closable and titleBarHeight or 0) - 10, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Font = SETTINGS.Font, Text = title or "Window", TextColor3 = CurrentTheme.PrimaryText, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = self.TitleBar.ZIndex + 1 })

    if closable then
        self.CloseButton = Create("TextButton", { Name = "CloseButton", Parent = self.TitleBar, Size = UDim2.fromOffset(titleBarHeight, titleBarHeight), Position = UDim2.new(1, -titleBarHeight, 0, 0), BackgroundColor3 = self.TitleBar.BackgroundColor3, Font = Enum.Font.SourceSansBold, Text = "✕", TextColor3 = CurrentTheme.SecondaryText, TextSize = 16, AutoButtonColor = false, ZIndex = self.TitleBar.ZIndex + 1 })
        self:_addConnection(self.CloseButton.MouseEnter:Connect(function() Animate(self.CloseButton, {BackgroundColor3 = Color3.fromRGB(232, 17, 35), TextColor3 = Color3.fromRGB(255,255,255)}, 0.1) end))
        self:_addConnection(self.CloseButton.MouseLeave:Connect(function() Animate(self.CloseButton, {BackgroundColor3 = self.TitleBar.BackgroundColor3, TextColor3 = CurrentTheme.SecondaryText}, 0.1) end))
        self:_addConnection(self.CloseButton.MouseButton1Click:Connect(function() self:Destroy() end))
    end

    self.Content = Create("ScrollingFrame", { -- Using ScrollingFrame for content overflow
        Name = "Content", Parent = self.Instance, Size = UDim2.new(1, -10, 1, -titleBarHeight - 5), Position = UDim2.new(0, 5, 0, titleBarHeight), BackgroundColor3 = CurrentTheme.ContentBackground, BorderSizePixel = 0, ZIndex = self.Instance.ZIndex, ClipsDescendants = true, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = CurrentTheme.ScrollBar, CanvasSize = UDim2.new(0,0,0,0) -- Auto canvas size via UIListLayout
    })
    self.ContentListLayout = Create("UIListLayout", { Parent = self.Content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center })
    Create("UIPadding", { Parent = self.Content, PaddingTop = UDim.new(0,5), PaddingBottom = UDim.new(0,5)})

    if draggable then
        local dragging, dragInput, dragStart, startPos, dragConn
        local function updateDrag() if dragging and dragInput and self.Instance and self.Instance.Parent then local d=dragInput.Position-dragStart; self.Instance.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) elseif not dragging and dragConn then dragConn:Disconnect(); dragConn=nil end end
        self:_addConnection(self.TitleBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if not self.Instance or not self.Instance.Parent then return end; dragging=true;dragStart=i.Position;startPos=self.Instance.Position;i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end); if not dragConn then dragConn=RunService.RenderStepped:Connect(updateDrag) end end end))
        self:_addConnection(self.TitleBar.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dragInput=i end end))
        self.OnDestroy:Connect(function() if dragConn then dragConn:Disconnect() end end)
    end
    return self
end
function MayhemUI.Window:Add(element)
    assert(element and element.Instance, "Window:Add expects a valid UI element.")
    element.Instance.Parent = self.Content
    element.ParentUI = self; table.insert(self.ChildrenUI, element)
    if self.ContentListLayout and element.Instance:IsA("GuiObject") then element.Instance.LayoutOrder = #self.ChildrenUI end
    return self
end
function MayhemUI.Window:SetTitle(t) if self.TitleLabel then self.TitleLabel.Text=t end end
function MayhemUI.Window:Close() self:Destroy() end

--==============================================================================
-- Label Component
--==============================================================================
MayhemUI.Label = {}
MayhemUI.Label.__index = setmetatable({}, BaseElement)
function MayhemUI.Label.new(text, fontSize, alignment, size)
    local self = NewElement("Label")
    setmetatable(self, MayhemUI.Label)
    self.Instance = Create("TextLabel", { Name = "MayhemLabel", Size = size or UDim2.new(1, -10, 0, (fontSize or 14) + 8), BackgroundTransparency = 1, Font = SETTINGS.Font, Text = text or "Label", TextColor3 = CurrentTheme.PrimaryText, TextSize = fontSize or 14, TextXAlignment = alignment or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = SETTINGS.BaseZIndex + 1, ClipsDescendants=true, TextWrapped = true })
    return self
end
function MayhemUI.Label:SetText(t) if self.Instance then self.Instance.Text=t end return self end
function MayhemUI.Label:SetColor(c) if self.Instance then self.Instance.TextColor3=c end return self end

--==============================================================================
-- Button Component
--==============================================================================
MayhemUI.Button = {}
MayhemUI.Button.__index = setmetatable({}, BaseElement)
function MayhemUI.Button.new(text, callback, size)
    local self = NewElement("Button")
    setmetatable(self, MayhemUI.Button)
    self.OnClick = Signal.new(); if callback then self.OnClick:Connect(callback) end
    self.Instance = Create("TextButton", { Name = "MayhemButton", Size = size or UDim2.new(1, -10, 0, 30), BackgroundColor3 = CurrentTheme.ElementBackground, Font = SETTINGS.Font, Text = text or "Button", TextColor3 = CurrentTheme.PrimaryText, TextSize = 14, AutoButtonColor = false, ZIndex = SETTINGS.BaseZIndex + 1 })
    Create("UICorner", {CornerRadius = UDim.new(0,4), Parent = self.Instance})
    Create("UIStroke", {Color = CurrentTheme.Border, Thickness = 1, Parent = self.Instance, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    local nBg,hBg,aBg = CurrentTheme.ElementBackground,CurrentTheme.ElementHover,CurrentTheme.ElementActive
    self:_addConnection(self.Instance.MouseEnter:Connect(function() if not self.Enabled then return end Animate(self.Instance, {BackgroundColor3=hBg}) end))
    self:_addConnection(self.Instance.MouseLeave:Connect(function() if not self.Enabled then return end Animate(self.Instance, {BackgroundColor3=nBg}) end))
    self:_addConnection(self.Instance.MouseButton1Down:Connect(function() if not self.Enabled then return end Animate(self.Instance, {BackgroundColor3=aBg},0.05) end))
    self:_addConnection(self.Instance.MouseButton1Up:Connect(function() if not self.Enabled then return end Animate(self.Instance, {BackgroundColor3 = self.Instance.MouseEnter and hBg or nBg}) end))
    self:_addConnection(self.Instance.MouseButton1Click:Connect(function() if not self.Enabled then return end self.OnClick:Fire() end))
    self.OnDestroy:Connect(function() self.OnClick:Destroy() end)
    return self
end
function MayhemUI.Button:SetText(t) if self.Instance then self.Instance.Text=t end return self end
function MayhemUI.Button:SetEnabled(e) BaseElement.SetEnabled(self,e); if self.Instance then if not e then Animate(self.Instance, {BackgroundColor3=CurrentTheme.ElementBackground,TextColor3=CurrentTheme.DisabledText}); self.Instance.UIStroke.Enabled=false else Animate(self.Instance, {BackgroundColor3=CurrentTheme.ElementBackground,TextColor3=CurrentTheme.PrimaryText}); self.Instance.UIStroke.Enabled=true end end end

--==============================================================================
-- Toggle (Checkbox-like) Component
--==============================================================================
MayhemUI.Toggle = {}
MayhemUI.Toggle.__index = setmetatable({}, BaseElement)
function MayhemUI.Toggle.new(text, initialValue, callback)
    local self = NewElement("Toggle"); setmetatable(self, MayhemUI.Toggle)
    self.Value = initialValue or false; self.OnChanged = Signal.new(); if callback then self.OnChanged:Connect(callback) end
    self.Instance = Create("Frame", { Name="MayhemToggleContainer", Size=UDim2.new(1,-10,0,24), BackgroundTransparency=1 })
    local bS=18; self.Box = Create("Frame",{Name="ToggleBox",Parent=self.Instance,Size=UDim2.fromOffset(bS,bS),Position=UDim2.new(0,0,0.5,-(bS/2)),BackgroundColor3=CurrentTheme.ElementBackground,BorderColor3=CurrentTheme.Border,BorderSizePixel=1});Create("UICorner",{CornerRadius=UDim.new(0,3),Parent=self.Box})
    self.Check = Create("Frame",{Name="ToggleCheck",Parent=self.Box,Size=UDim2.new(0.7,0,0.7,0),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=SETTINGS.AccentColor,BorderSizePixel=0,Visible=self.Value});Create("UICorner",{CornerRadius=UDim.new(0,2),Parent=self.Check})
    self.Label = Create("TextLabel",{Name="ToggleLabel",Parent=self.Instance,Size=UDim2.new(1,-(bS+8),1,0),Position=UDim2.new(0,bS+8,0,0),BackgroundTransparency=1,Font=SETTINGS.Font,Text=text or "Toggle",TextColor3=CurrentTheme.PrimaryText,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
    self.ClickDetector = Create("TextButton",{Name="ToggleClick",Parent=self.Instance,Size=UDim2.new(1,0,1,0),Text="",BackgroundTransparency=1,AutoButtonColor=false})
    local function updateVis() Animate(self.Check,{Visible=self.Value},0.1); if self.Value then Animate(self.Box,{BackgroundColor3=SETTINGS.AccentColor,BorderColor3=SETTINGS.AccentColor},0.1) else Animate(self.Box,{BackgroundColor3=CurrentTheme.ElementBackground,BorderColor3=CurrentTheme.Border},0.1) end end; updateVis()
    self:_addConnection(self.ClickDetector.MouseButton1Click:Connect(function() if not self.Enabled then return end self.Value=not self.Value; updateVis(); self.OnChanged:Fire(self.Value) end))
    self:_addConnection(self.ClickDetector.MouseEnter:Connect(function() if not self.Enabled or self.Value then return end Animate(self.Box,{BorderColor3=SETTINGS.AccentColor}) end))
    self:_addConnection(self.ClickDetector.MouseLeave:Connect(function() if not self.Enabled or self.Value then return end Animate(self.Box,{BorderColor3=CurrentTheme.Border}) end))
    self.OnDestroy:Connect(function() self.OnChanged:Destroy() end)
    return self
end
function MayhemUI.Toggle:SetValue(v, fireEvent) fireEvent = fireEvent == nil and true or fireEvent; if self.Value~=v then self.Value=v; local function uV() Animate(self.Check,{Visible=self.Value},0.1); if self.Value then Animate(self.Box,{BackgroundColor3=SETTINGS.AccentColor,BorderColor3=SETTINGS.AccentColor},0.1) else Animate(self.Box,{BackgroundColor3=CurrentTheme.ElementBackground,BorderColor3=CurrentTheme.Border},0.1) end end; uV(); if fireEvent then self.OnChanged:Fire(self.Value) end end return self end
function MayhemUI.Toggle:GetValue() return self.Value end

--==============================================================================
-- InputField Component
--==============================================================================
MayhemUI.InputField = {}
MayhemUI.InputField.__index = setmetatable({}, BaseElement)
function MayhemUI.InputField.new(placeholderText, isPassword, callback)
    local self = NewElement("InputField"); setmetatable(self, MayhemUI.InputField)
    self.OnChanged=Signal.new(); self.OnFocusLost=Signal.new(); self.OnEnterPressed=Signal.new(); if callback then self.OnChanged:Connect(callback) end
    self.Instance = Create("Frame",{Name="MayhemInputContainer",Size=UDim2.new(1,-10,0,32),BackgroundColor3=CurrentTheme.ElementBackground,BorderColor3=CurrentTheme.Border,BorderSizePixel=1});Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=self.Instance})
    self.TextBox = Create("TextBox",{Name="MayhemTextBox",Parent=self.Instance,Size=UDim2.new(1,-16,1,-8),Position=UDim2.fromOffset(8,4),BackgroundTransparency=1,Font=SETTINGS.Font,Text="",PlaceholderText=placeholderText or "Enter text...",PlaceholderColor3=CurrentTheme.SecondaryText,TextColor3=CurrentTheme.PrimaryText,TextSize=14,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=self.Instance.ZIndex+1}); if isPassword then self.TextBox.TextMasked=true end
    local focBrd,normBrd = SETTINGS.AccentColor,CurrentTheme.Border
    self:_addConnection(self.TextBox.FocusGained:Connect(function() Animate(self.Instance,{BorderColor3=focBrd}) end))
    self:_addConnection(self.TextBox.FocusLost:Connect(function(eP) Animate(self.Instance,{BorderColor3=normBrd});self.OnFocusLost:Fire(self.TextBox.Text,eP);self.OnChanged:Fire(self.TextBox.Text);if eP then self.OnEnterPressed:Fire(self.TextBox.Text) end end))
    self.OnDestroy:Connect(function() self.OnChanged:Destroy();self.OnFocusLost:Destroy();self.OnEnterPressed:Destroy() end)
    return self
end
function MayhemUI.InputField:SetText(t) if self.TextBox then self.TextBox.Text=tostring(t) end return self end
function MayhemUI.InputField:GetText() return self.TextBox and self.TextBox.Text or "" end
function MayhemUI.InputField:Clear() self:SetText("") return self end
function MayhemUI.InputField:SetPlaceholder(p) if self.TextBox then self.TextBox.PlaceholderText=p end return self end

--==============================================================================
-- Slider Component
--==============================================================================
MayhemUI.Slider = {}
MayhemUI.Slider.__index = setmetatable({}, BaseElement)
function MayhemUI.Slider.new(min, max, initialValue, step, callback)
    local self = NewElement("Slider"); setmetatable(self, MayhemUI.Slider); self.Min=min or 0; self.Max=max or 100; self.Value=initialValue or self.Min; self.Step=step or 1; self.OnChanged=Signal.new(); if callback then self.OnChanged:Connect(callback) end
    local tH,thS=6,16; self.Instance=Create("Frame",{Name="MayhemSliderContainer",Size=UDim2.new(1,-10,0,thS+4),BackgroundTransparency=1})
    self.Track=Create("Frame",{Name="SliderTrack",Parent=self.Instance,Size=UDim2.new(1,-thS,0,tH),Position=UDim2.new(0,thS/2,0.5,-tH/2),BackgroundColor3=CurrentTheme.ElementBackground,BorderColor3=CurrentTheme.Border,BorderSizePixel=1});Create("UICorner",{CornerRadius=UDim.new(0,tH/2),Parent=self.Track})
    self.Fill=Create("Frame",{Name="SliderFill",Parent=self.Track,Size=UDim2.new(0,0,1,0),BackgroundColor3=SETTINGS.AccentColor,BorderSizePixel=0});Create("UICorner",{CornerRadius=UDim.new(0,tH/2),Parent=self.Fill})
    self.Thumb=Create("Frame",{Name="SliderThumb",Parent=self.Instance,Size=UDim2.fromOffset(thS,thS),Position=UDim2.new(0,0,0.5,-thS/2),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=CurrentTheme.ElementHover,BorderColor3=SETTINGS.AccentColor,BorderSizePixel=2,ZIndex=self.Instance.ZIndex+1});Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=self.Thumb})
    self.ValueLabel=Create("TextLabel",{Name="SliderValueLabel",Parent=self.Thumb,Size=UDim2.new(1,0,1,0),Visible=false,BackgroundTransparency=1,Font=SETTINGS.Font,TextColor3=CurrentTheme.PrimaryText,TextSize=10,TextStrokeTransparency=0.7, TextStrokeColor3=Color3.new(0,0,0)})
    local function updateVis(fireEvent, noAnim) local p=math.clamp((self.Value-self.Min)/(self.Max-self.Min),0,1); local tPW=self.Track.AbsoluteSize.X; local tAP=self.Track.AbsolutePosition.X; local thAP=self.Thumb.AbsolutePosition.X
        if noAnim then self.Fill.Size=UDim2.new(p,0,1,0); self.Thumb.Position=UDim2.new(0,(thS/2)+(p*tPW),0.5,0) else Animate(self.Fill,{Size=UDim2.new(p,0,1,0)}); Animate(self.Thumb,{Position=UDim2.new(0,(thS/2)+(p*tPW),0.5,0)}) end
        self.ValueLabel.Text=string.format("%.2f",self.Value):gsub("%.?0+$",""); if fireEvent then self.OnChanged:Fire(self.Value) end
    end; self:SetValue(self.Value,false,true)
    local dragging,dragConn; local function handleDrag(iP) if not self.Instance or not self.Track then return end; local rX=iP.X-self.Track.AbsolutePosition.X; local tPW=self.Track.AbsoluteSize.X; local p=math.clamp(rX/tPW,0,1); local nV=self.Min+p*(self.Max-self.Min); if self.Step>0 then nV=math.floor(nV/self.Step+0.5)*self.Step end; nV=math.clamp(nV,self.Min,self.Max); if self.Value~=nV then self.Value=nV; updateVis(true) end end
    local function startDrag() dragging=true; Animate(self.Thumb,{Size=UDim2.fromOffset(thS*1.2,thS*1.2)},0.1); if not dragConn then dragConn=RunService.RenderStepped:Connect(function() if dragging then handleDrag(UserInputService:GetMouseLocation()) end end) end end
    local function endDrag() dragging=false; Animate(self.Thumb,{Size=UDim2.fromOffset(thS,thS)},0.1); if dragConn then dragConn:Disconnect(); dragConn=nil end end
    self:_addConnection(self.Track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then handleDrag(i.Position); startDrag() end end))
    self:_addConnection(self.Thumb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then startDrag() end end))
    self:_addConnection(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and dragging then endDrag() end end))
    self.OnDestroy:Connect(function() self.OnChanged:Destroy(); if dragConn then dragConn:Disconnect() end end)
    return self
end
function MayhemUI.Slider:SetValue(nV,fE,noA) fE=fE==nil and true or fE; nV=math.clamp(nV,self.Min,self.Max); if self.Step>0 then nV=math.floor(nV/self.Step+0.5)*self.Step end; if self.Value~=nV or noA then self.Value=nV; local p=math.clamp((self.Value-self.Min)/(self.Max-self.Min),0,1); local tPW=self.Track and self.Track.AbsoluteSize.X or 200; local thS=self.Thumb and self.Thumb.AbsoluteSize.X or 16
    if noA then if self.Fill then self.Fill.Size=UDim2.new(p,0,1,0) end; if self.Thumb then self.Thumb.Position=UDim2.new(0,(thS/2)+(p*tPW),0.5,0) end else if self.Fill then Animate(self.Fill,{Size=UDim2.new(p,0,1,0)}) end; if self.Thumb then Animate(self.Thumb,{Position=UDim2.new(0,(thS/2)+(p*tPW),0.5,0)}) end end
    if self.ValueLabel then self.ValueLabel.Text=string.format("%.2f",self.Value):gsub("%.?0+$","") end; if fE then self.OnChanged:Fire(self.Value) end end return self end
function MayhemUI.Slider:GetValue() return self.Value end
function MayhemUI.Slider:ShowValueLabel(v) self.ValueLabel.Visible=v return self end

--==============================================================================
-- Dropdown Component
--==============================================================================
MayhemUI.Dropdown = {}
MayhemUI.Dropdown.__index = setmetatable({}, BaseElement)
function MayhemUI.Dropdown.new(options, initialSelectionIndex, callback)
    local self = NewElement("Dropdown"); setmetatable(self, MayhemUI.Dropdown)
    self.Options=options or {"Opt1"}; self.SelectedOption=nil; self.SelectedIndex=-1; self.IsOpen=false; self.OnChanged=Signal.new(); if callback then self.OnChanged:Connect(callback) end
    self.Instance=Create("Frame",{Name="MayhemDropdown",Size=UDim2.new(1,-10,0,30),BackgroundColor3=CurrentTheme.ElementBackground,BorderColor3=CurrentTheme.Border,BorderSizePixel=1,ClipsDescendants=false});Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=self.Instance})
    self.CurrentValueLabel=Create("TextLabel",{Parent=self.Instance,Name="DropdownVal",Size=UDim2.new(1,-25,1,0),Position=UDim2.fromOffset(8,0),BackgroundTransparency=1,Font=SETTINGS.Font,TextColor3=CurrentTheme.PrimaryText,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
    self.Arrow=Create("TextLabel",{Parent=self.Instance,Name="DropdownArrow",Size=UDim2.fromOffset(20,20),Position=UDim2.new(1,-22,0.5,-10),BackgroundTransparency=1,Font=Enum.Font.SourceSansBold,Text="▼",TextColor3=CurrentTheme.SecondaryText,TextSize=16})
    self.OptionsListFrame=Create("ScrollingFrame",{Name="DropdownOpts",Parent=self.Instance,Visible=false,Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,2),BackgroundColor3=CurrentTheme.ElementBackground,BorderColor3=CurrentTheme.Border,BorderSizePixel=1,ZIndex=self.Instance.ZIndex+10,ScrollBarThickness=6,ScrollBarImageColor3=CurrentTheme.ScrollBar});Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=self.OptionsListFrame});local lL=Create("UIListLayout",{Parent=self.OptionsListFrame,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})
    local function selectOpt(idx,txt,fire) self.SelectedOption=txt;self.SelectedIndex=idx;self.CurrentValueLabel.Text=txt;if fire==nil or fire then self.OnChanged:Fire(txt,idx) end end
    local function toggleOpen(forceState) self.IsOpen = forceState ~= nil and forceState or not self.IsOpen; Animate(self.Arrow,{Rotation=self.IsOpen and 180 or 0},0.1); self.OptionsListFrame.Visible=self.IsOpen; if self.IsOpen then local mH=150; local rH=#self.Options*24+lL.Padding.Offset*(#self.Options+1); local lH=math.min(mH,rH); self.OptionsListFrame.Size=UDim2.new(1,0,0,lH); local sG=self.Instance:FindFirstAncestorOfClass("ScreenGui") or game:GetService("CoreGui"); self.OptionsListFrame.Parent=sG; local aP=self.Instance.AbsolutePosition; local aSY=self.Instance.AbsoluteSize.Y; self.OptionsListFrame.Position=UDim2.fromOffset(aP.X,aP.Y+aSY+2); self.OptionsListFrame.Size=UDim2.new(0,self.Instance.AbsoluteSize.X,0,lH); self.OptionsListFrame.ZIndex=SETTINGS.BaseZIndex+1000 else self.OptionsListFrame.Parent=self.Instance; self.OptionsListFrame.Position=UDim2.new(0,0,1,2) end end
    self:_addConnection(self.Instance.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then toggleOpen() end end))
    local function populate() for _,c in ipairs(self.OptionsListFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end; for i,oT in ipairs(self.Options) do local oB=Create("TextButton",{Name="Opt"..i,Parent=self.OptionsListFrame,Size=UDim2.new(1,0,0,22),BackgroundColor3=CurrentTheme.ElementBackground,Font=SETTINGS.Font,Text=oT,TextColor3=CurrentTheme.PrimaryText,TextSize=13,AutoButtonColor=false,LayoutOrder=i});Create("UICorner",{CornerRadius=UDim.new(0,3),Parent=oB}); self:_addConnection(oB.MouseEnter:Connect(function() Animate(oB,{BackgroundColor3=CurrentTheme.ElementHover}) end)); self:_addConnection(oB.MouseLeave:Connect(function() Animate(oB,{BackgroundColor3=CurrentTheme.ElementBackground}) end)); self:_addConnection(oB.MouseButton1Click:Connect(function() selectOpt(i,oT,true); toggleOpen(false) end)) end end; populate()
    if #self.Options>0 then selectOpt(initialSelectionIndex or 1,self.Options[initialSelectionIndex or 1],false) else self.CurrentValueLabel.Text="No options" end
    local clickOutsideConn; self.OnDestroy:Connect(function() self.OnChanged:Destroy(); if self.OptionsListFrame.Parent~=self.Instance then self.OptionsListFrame:Destroy() end; if clickOutsideConn then clickOutsideConn:Disconnect() end end)
    clickOutsideConn = UserInputService.InputBegan:Connect(function(input) if self.IsOpen and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then local obj=input.GuiObjectAtPosition; if not (obj and (obj==self.Instance or obj:IsDescendantOf(self.Instance) or obj==self.OptionsListFrame or obj:IsDescendantOf(self.OptionsListFrame))) then toggleOpen(false) end end end)
    self:_addConnection(clickOutsideConn) -- Ensure this connection is managed
    return self
end
function MayhemUI.Dropdown:SetOptions(newOpts, initialIdx) self.Options=newOpts; local function pop() for _,c in ipairs(self.OptionsListFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end; for i,oT in ipairs(self.Options) do local oB=Create("TextButton",{Name="Opt"..i,Parent=self.OptionsListFrame,Size=UDim2.new(1,0,0,22),BackgroundColor3=CurrentTheme.ElementBackground,Font=SETTINGS.Font,Text=oT,TextColor3=CurrentTheme.PrimaryText,TextSize=13,AutoButtonColor=false,LayoutOrder=i});Create("UICorner",{CornerRadius=UDim.new(0,3),Parent=oB}); self:_addConnection(oB.MouseEnter:Connect(function() Animate(oB,{BackgroundColor3=CurrentTheme.ElementHover}) end)); self:_addConnection(oB.MouseLeave:Connect(function() Animate(oB,{BackgroundColor3=CurrentTheme.ElementBackground}) end)); self:_addConnection(oB.MouseButton1Click:Connect(function() self.SelectedOption=oT;self.SelectedIndex=i;self.CurrentValueLabel.Text=oT;self.OnChanged:Fire(oT,i); self.IsOpen=false;Animate(self.Arrow,{Rotation=0},0.1);self.OptionsListFrame.Visible=false;self.OptionsListFrame.Parent=self.Instance;self.OptionsListFrame.Position=UDim2.new(0,0,1,2) end)) end end; pop(); if #self.Options>0 then self:Select(initialIdx or 1,false) else self.CurrentValueLabel.Text="No options";self.SelectedOption=nil;self.SelectedIndex=-1 end return self end
function MayhemUI.Dropdown:Select(optId,fire) local fI=-1;local fO=nil;if type(optId)=="number" then if optId>=1 and optId<=#self.Options then fI=optId;fO=self.Options[optId] end elseif type(optId)=="string" then for i,o in ipairs(self.Options) do if o==optId then fI=i;fO=o;break end end end; if fI~=-1 then self.SelectedOption=fO;self.SelectedIndex=fI;self.CurrentValueLabel.Text=fO;if fire==nil or fire then self.OnChanged:Fire(fO,fI) end end return self end
function MayhemUI.Dropdown:GetSelected() return self.SelectedOption,self.SelectedIndex end

--==============================================================================
-- Main Library API & Config
--==============================================================================
function MayhemUI:CreateScreen(name)
    name = name or "MayhemScreen_"..math.random(1000,9999)
    local screenGui = Create("ScreenGui", { Name = name, Parent = game:GetService("CoreGui"), ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = SETTINGS.BaseZIndex, ResetOnSpawn = false })
    return screenGui
end
function MayhemUI:SetTheme(themeName) if THEMES[themeName] then SETTINGS.Theme=themeName; CurrentTheme=THEMES[themeName]; warn("MayhemUI: Theme changed. Full refresh of existing UI elements for theme updates is not implemented in this version.") else warn("MayhemUI: Theme '"..tostring(themeName).."' not found.") end end
function MayhemUI:SetAccentColor(c) assert(typeof(c)=="Color3","Accent must be Color3"); SETTINGS.AccentColor=c; warn("MayhemUI: Accent changed. Full refresh not implemented.") end
function MayhemUI:SetFont(f) assert(typeof(f)=="EnumItem" and f.EnumType==Enum.Font,"Font must be Enum.Font"); SETTINGS.Font=f; warn("MayhemUI: Font changed. Full refresh not implemented.") end

return MayhemUI
