--[[
    Mayhem UI Library - Executor Version
    Uses Drawing.new() (e.g., for Synapse X, Script-Ware, KRNL with compatible Drawing API)
]]

local MayhemLib = {}
MayhemLib.__index = MayhemLib

-- Executor-provided services (adjust if names differ)
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Configuration
local Config = {
    AccentColor = Color3.fromRGB(0, 120, 255),
    BackgroundColor = Color3.fromRGB(25, 25, 25),
    SecondaryBackgroundColor = Color3.fromRGB(40, 40, 40),
    TertiaryBackgroundColor = Color3.fromRGB(55, 55, 55),
    TextColor = Color3.fromRGB(230, 230, 230),
    FontName = "GothamSemibold",
    WindowPadding = 8,
    ElementPadding = 6,
    CornerRadius = 5,
    DraggableAreaHeight = 32,
    AnimationSpeed = 0.2,
}

-- Initialize DrawingAPI as a table first
local DrawingAPI = {}
DrawingAPI.ACTIVE_DRAWING_OBJECTS = {} 
DrawingAPI.NEXT_ZINDEX = 1

DrawingAPI._track = function(obj)
    if not obj then print("Warning: _track received nil object") return nil end
    table.insert(DrawingAPI.ACTIVE_DRAWING_OBJECTS, obj) 
    pcall(function() 
        obj.ZIndex = DrawingAPI.NEXT_ZINDEX 
    end)
    DrawingAPI.NEXT_ZINDEX = DrawingAPI.NEXT_ZINDEX + 1
    return obj
end

DrawingAPI.CreateFrame = function(properties)
    local obj = Drawing.new("Square")
    obj.Visible = properties.Visible ~= false
    obj.Color = properties.Color or Color3.fromRGB(50,50,50)
    obj.Position = properties.Position or Vector2.new(0,0)
    obj.Size = properties.Size or Vector2.new(100,100)
    obj.Rounding = properties.CornerRadius or 0
    obj.Filled = true
    obj.Thickness = 1
    return DrawingAPI._track(obj) 
end

DrawingAPI.CreateText = function(properties)
    local obj = Drawing.new("Text")
    obj.Visible = properties.Visible ~= false
    obj.Text = properties.Text or ""
    obj.Color = properties.Color or Color3.fromRGB(200,200,200)
    obj.Position = properties.Position or Vector2.new(0,0)
    obj.Size = properties.TextSize or 14

    local fontEnum = Drawing.Fonts.GothamSemibold
    if properties.FontName == "GothamBlack" then fontEnum = Drawing.Fonts.GothamBlack
    elseif properties.FontName == "Arial" then fontEnum = Drawing.Fonts.Arial
    elseif properties.FontName == "Plex" then fontEnum = Drawing.Fonts.Plex
    elseif properties.FontName == "Monospace" then fontEnum = Drawing.Fonts.Monospace
    end
    obj.Font = fontEnum
    obj.Center = (properties.XAlignment == "Center")
    
    local yAlignEnum = Drawing.TextYAlignment.Top
    if properties.YAlignment == "Center" then yAlignEnum = Drawing.TextYAlignment.Center
    elseif properties.YAlignment == "Bottom" then yAlignEnum = Drawing.TextYAlignment.Bottom
    end
    obj.YAlignment = yAlignEnum
    obj.Outline = false
    return DrawingAPI._track(obj) 
end

DrawingAPI.ClearAll = function()
    for i = #DrawingAPI.ACTIVE_DRAWING_OBJECTS, 1, -1 do
        local obj = DrawingAPI.ACTIVE_DRAWING_OBJECTS[i]
        if obj and obj.Remove then
            pcall(obj.Remove, obj)
        end
        table.remove(DrawingAPI.ACTIVE_DRAWING_OBJECTS, i)
    end
    DrawingAPI.NEXT_ZINDEX = 1
end


function MayhemLib:ShowLoadingScreen(optionalScriptToLoadUrl, callbackOnFinish)
    DrawingAPI.ClearAll() 

    local screenW, screenH = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
    local elements = {} 

    elements.Background = DrawingAPI.CreateFrame({
        Name = "LoadingBackground", Position = Vector2.new(0, 0), Size = Vector2.new(screenW, screenH),
        Color = Config.BackgroundColor,
    })

    elements.Title = DrawingAPI.CreateText({
        Name = "LoadingTitle", Text = "MAYHEM", FontName = "GothamBlack", TextSize = 60,
        Color = Config.AccentColor, Position = Vector2.new(screenW / 2, screenH * 0.35),
        XAlignment = "Center", YAlignment = "Center",
    })
    
    elements.Status = DrawingAPI.CreateText({
        Name = "LoadingStatus", Text = "Initializing...", FontName = Config.FontName, TextSize = 18,
        Color = Config.TextColor, Position = Vector2.new(screenW / 2, screenH * 0.5 + 10),
        XAlignment = "Center", YAlignment = "Center",
    })

    local barW, barH = screenW * 0.3, 8
    local barX, barY = screenW / 2 - barW / 2, screenH * 0.5 + 50

    elements.ProgressBarOutline = DrawingAPI.CreateFrame({
        Name = "LoadingBarOutline", Position = Vector2.new(barX, barY), Size = Vector2.new(barW, barH),
        Color = Config.SecondaryBackgroundColor, CornerRadius = Config.CornerRadius / 2,
    })

    elements.ProgressBarFill = DrawingAPI.CreateFrame({
        Name = "LoadingBarFill", Position = Vector2.new(barX, barY), Size = Vector2.new(0, barH),
        Color = Config.AccentColor, CornerRadius = Config.CornerRadius / 2,
    })

    coroutine.wrap(function()
        local function updateProgress(percentage, statusText)
            if elements.Status and elements.Status.Text then elements.Status.Text = statusText end
            if elements.ProgressBarFill and elements.ProgressBarFill.Size then elements.ProgressBarFill.Size = Vector2.new(barW * percentage, barH) end
            task.wait(0.05)
        end

        updateProgress(0.1, "Initializing...")
        task.wait(0.2)
        updateProgress(0.3, "Loading Assets...")
        task.wait(0.3)
        
        if optionalScriptToLoadUrl and optionalScriptToLoadUrl ~= "" then
            updateProgress(0.6, "Fetching Remote Script...")
            local success, contentOrErr = pcall(function()
                if syn and syn.request then
                     local response = syn.request({Url = optionalScriptToLoadUrl, Method = "GET"})
                     if response.StatusCode == 200 then return response.Body else error(response.StatusMessage .. " (Code: " .. response.StatusCode .. ")") end
                elseif HttpService then
                    return HttpService:GetAsync(optionalScriptToLoadUrl, true)
                elseif getgenv().HttpGet then
                    return getgenv().HttpGet(optionalScriptToLoadUrl)
                else
                    error("No suitable HTTP request function found in environment.")
                end
            end)
            task.wait(0.2)

            if success then
                updateProgress(0.8, "Executing Script...")
                task.wait(0.1)
                local scriptFunction, scriptError = loadstring(contentOrErr)
                if scriptFunction then
                    local execSuccess, execError = pcall(scriptFunction)
                    if not execSuccess then
                        updateProgress(0.9, "Execution Error.")
                        warn("[MayhemLib] Error executing remote script:", execError)
                        task.wait(1.0)
                    else
                        updateProgress(1.0, "Loaded Successfully!")
                    end
                else
                    updateProgress(0.9, "Loadstring Error.")
                    warn("[MayhemLib] Error in loadstring for remote script:", scriptError)
                    task.wait(1.0)
                end
            else
                updateProgress(0.9, "Fetch Failed.")
                warn("[MayhemLib] Failed to fetch remote script:", contentOrErr)
                task.wait(1.0)
            end
        else
            updateProgress(0.8, "Finalizing...")
            task.wait(0.3)
            updateProgress(1.0, "Ready!")
        end
        
        task.wait(0.3)

        for _, el in pairs(elements) do
            if el and el.Remove then pcall(el.Remove, el) end
        end
        elements = {} 

        if callbackOnFinish then pcall(callbackOnFinish) end
    end)()
end


local activeWindow = {
    CurrentPos = Vector2.new(0,0), Size = Vector2.new(0,0),
    WindowFrame = nil, TitleBar = nil, TitleText = nil, CloseButton = {},
    TabButtonsContainerY = 0,
    ContentContainerPos = Vector2.new(0,0), ContentContainerSize = Vector2.new(0,0), ContentFrame = nil,
    Tabs = {}, ActiveTab = nil,
    IsDragging = false, DragStartMouse = Vector2.new(0,0), DragStartPos = Vector2.new(0,0),
    DrawnElementsInWindow = {} 
}

local function removeDrawingObject(objRef)
    if not objRef then return end
    if type(objRef) == "table" and not objRef.Remove then 
        for _, subEl in pairs(objRef) do
            if subEl and subEl.Remove then pcall(subEl.Remove, subEl) end
        end
    elseif objRef.Remove then 
        pcall(objRef.Remove, objRef)
    end
end

local function destroyCurrentWindowGFX()
    for _, elRef in ipairs(activeWindow.DrawnElementsInWindow) do
        removeDrawingObject(elRef)
    end
    activeWindow.DrawnElementsInWindow = {}
    activeWindow.WindowFrame = nil; activeWindow.TitleBar = nil; activeWindow.TitleText = nil;
    activeWindow.CloseButton = {}; activeWindow.Tabs = {}; activeWindow.ActiveTab = nil;
    activeWindow.ContentFrame = nil;
    MayhemLib._Clickables = {} 
end


function MayhemLib:CreateWindow(title, width, height)
    destroyCurrentWindowGFX() 
    DrawingAPI.NEXT_ZINDEX = 100 

    local startX = (workspace.CurrentCamera.ViewportSize.X - width) / 2
    local startY = (workspace.CurrentCamera.ViewportSize.Y - height) / 2
    activeWindow.CurrentPos = Vector2.new(startX, startY)
    activeWindow.Size = Vector2.new(width, height)

    activeWindow.WindowFrame = DrawingAPI.CreateFrame({
        Position = activeWindow.CurrentPos, Size = activeWindow.Size,
        Color = Config.BackgroundColor, CornerRadius = Config.CornerRadius,
    }); table.insert(activeWindow.DrawnElementsInWindow, activeWindow.WindowFrame)

    activeWindow.TitleBar = DrawingAPI.CreateFrame({
        Position = activeWindow.CurrentPos,
        Size = Vector2.new(width, Config.DraggableAreaHeight),
        Color = Config.SecondaryBackgroundColor, CornerRadius = Config.CornerRadius, 
    }); table.insert(activeWindow.DrawnElementsInWindow, activeWindow.TitleBar)

    activeWindow.TitleText = DrawingAPI.CreateText({
        Position = activeWindow.CurrentPos + Vector2.new(Config.WindowPadding, Config.DraggableAreaHeight / 2),
        Text = title or "Mayhem UI", FontName = Config.FontName, TextSize = 16, Color = Config.TextColor,
        XAlignment = "Left", YAlignment = "Center",
    }); table.insert(activeWindow.DrawnElementsInWindow, activeWindow.TitleText)

    local closeSize = Config.DraggableAreaHeight - 12
    local closeButtonX = activeWindow.CurrentPos.X + width - closeSize - Config.WindowPadding / 2
    local closeButtonY = activeWindow.CurrentPos.Y + (Config.DraggableAreaHeight - closeSize) / 2
    activeWindow.CloseButton.Background = DrawingAPI.CreateFrame({
        Position = Vector2.new(closeButtonX, closeButtonY), Size = Vector2.new(closeSize, closeSize),
        Color = Config.AccentColor, CornerRadius = Config.CornerRadius / 2,
    }); table.insert(activeWindow.DrawnElementsInWindow, activeWindow.CloseButton.Background)
    activeWindow.CloseButton.Text = DrawingAPI.CreateText({
        Position = Vector2.new(closeButtonX + closeSize / 2, closeButtonY + closeSize / 2),
        Text = "X", FontName = Config.FontName, TextSize = 16, Color = Color3.fromRGB(255,255,255),
        XAlignment = "Center", YAlignment = "Center",
    }); table.insert(activeWindow.DrawnElementsInWindow, activeWindow.CloseButton.Text)
    activeWindow.CloseButton.Bounds = Rect.new(closeButtonX, closeButtonY, closeButtonX + closeSize, closeButtonY + closeSize)


    activeWindow.TabButtonsContainerY = activeWindow.CurrentPos.Y + Config.DraggableAreaHeight + Config.ElementPadding
    
    local contentY = activeWindow.TabButtonsContainerY + (Config.DraggableAreaHeight - 5) + Config.ElementPadding * 1.5
    local contentHeight = height - (contentY - activeWindow.CurrentPos.Y) - Config.WindowPadding

    activeWindow.ContentContainerPos = Vector2.new(activeWindow.CurrentPos.X + Config.WindowPadding, contentY)
    activeWindow.ContentContainerSize = Vector2.new(width - Config.WindowPadding * 2, contentHeight)

    activeWindow.ContentFrame = DrawingAPI.CreateFrame({
        Position = activeWindow.ContentContainerPos, Size = activeWindow.ContentContainerSize,
        Color = Config.SecondaryBackgroundColor, CornerRadius = Config.CornerRadius,
    }); table.insert(activeWindow.DrawnElementsInWindow, activeWindow.ContentFrame)
    
    if not MayhemLib._WindowInputConnected then
        UserInputService.InputBegan:Connect(function(input)
            if not activeWindow.WindowFrame or activeWindow.WindowFrame.Visible == false then return end -- Check if window is active
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                
                -- Check title bar AFTER close button, so close button takes precedence
                if activeWindow.CloseButton.Bounds and activeWindow.CloseButton.Bounds:Contains(mousePos) then
                    destroyCurrentWindowGFX()
                    return -- Stop further processing for this click
                end

                local titleBarRect = Rect.new(activeWindow.TitleBar.Position, activeWindow.TitleBar.Position + activeWindow.TitleBar.Size)
                if titleBarRect:Contains(mousePos) then
                    activeWindow.IsDragging = true
                    activeWindow.DragStartMouse = mousePos
                    activeWindow.DragStartPos = activeWindow.CurrentPos
                    -- Do not return here, allow clickables to be checked if not dragging
                end
                
                -- Handle general clickable elements only if not currently dragging
                if not activeWindow.IsDragging and MayhemLib._Clickables then
                    for _, clickable in ipairs(MayhemLib._Clickables) do
                        if clickable.IsActive() and clickable.Bounds:Contains(mousePos) then
                            pcall(clickable.Callback)
                            -- break -- Process one click per input event (optional, can be problematic with overlapping elements)
                        end
                    end
                end
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if activeWindow.IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                if not activeWindow.WindowFrame or activeWindow.WindowFrame.Visible == false then 
                    activeWindow.IsDragging = false; 
                    return 
                end

                local mousePos = UserInputService:GetMouseLocation()
                local delta = mousePos - activeWindow.DragStartMouse
                local newBasePos = activeWindow.DragStartPos + delta
                
                local actualDelta = newBasePos - activeWindow.CurrentPos
                activeWindow.CurrentPos = newBasePos

                local function updateElementPositionRecursive(element, d)
                    if not element then return end
                    if type(element) == "table" and not element.Position and not element.Remove then 
                        for _, subEl in pairs(element) do updateElementPositionRecursive(subEl, d) end
                    elseif element.Position then 
                        element.Position = element.Position + d
                    end
                    if element.Bounds and type(element.Bounds.Min) == "Vector2" then 
                        element.Bounds = Rect.new(element.Bounds.Min + d, element.Bounds.Max + d)
                    end
                end
                
                for _, elRef in ipairs(activeWindow.DrawnElementsInWindow) do
                    updateElementPositionRecursive(elRef, actualDelta)
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- If it was a drag, just end drag.
                -- If it was a click (IsDragging is false), clickables were handled in InputBegan.
                activeWindow.IsDragging = false
            end
        end)
        MayhemLib._WindowInputConnected = true
    end
    
    return MayhemLib
end

MayhemLib._Clickables = {} 
local tabButtonWidth = 100
local tabButtonHeight = Config.DraggableAreaHeight - 10

function MayhemLib:CreateTab(windowRefIgnored, title) 
    if not activeWindow.WindowFrame then print("Window not created"); return nil end

    local tabIndex = #activeWindow.Tabs + 1
    local tabX = activeWindow.CurrentPos.X + Config.WindowPadding + (tabIndex - 1) * (tabButtonWidth + Config.ElementPadding / 2)
    local tabY = activeWindow.TabButtonsContainerY

    local tabData = {
        Title = title, Elements = {}, DrawnObjects = {}, IsActive = false, Button = {},
        NextElementY = activeWindow.ContentContainerPos.Y + Config.ElementPadding,
    }

    tabData.Button.Background = DrawingAPI.CreateFrame({
        Position = Vector2.new(tabX, tabY), Size = Vector2.new(tabButtonWidth, tabButtonHeight),
        Color = Config.TertiaryBackgroundColor, CornerRadius = Config.CornerRadius / 1.5,
    }); table.insert(activeWindow.DrawnElementsInWindow, tabData.Button.Background)
    tabData.Button.Text = DrawingAPI.CreateText({
        Position = Vector2.new(tabX + tabButtonWidth/2, tabY + tabButtonHeight/2), Text = title,
        FontName = Config.FontName, TextSize = 14, Color = Config.TextColor,
        XAlignment = "Center", YAlignment = "Center",
    }); table.insert(activeWindow.DrawnElementsInWindow, tabData.Button.Text)
    tabData.Button.Bounds = Rect.new(tabX, tabY, tabX + tabButtonWidth, tabY + tabButtonHeight)
    
    local function setActive()
        if activeWindow.ActiveTab == tabData then return end
        
        if activeWindow.ActiveTab then 
            activeWindow.ActiveTab.IsActive = false
            activeWindow.ActiveTab.Button.Background.Color = Config.TertiaryBackgroundColor
            activeWindow.ActiveTab.Button.Text.Color = Config.TextColor
            for _, elData in ipairs(activeWindow.ActiveTab.Elements) do
                if elData.DrawnObject and elData.DrawnObject.Visible ~= nil then elData.DrawnObject.Visible = false end
                if type(elData.DrawnObject) == "table" then 
                    for _, subEl in pairs(elData.DrawnObject) do 
                        if subEl and subEl.Visible ~= nil then subEl.Visible = false end 
                    end 
                end
            end
        end

        tabData.IsActive = true 
        tabData.Button.Background.Color = Config.AccentColor
        tabData.Button.Text.Color = Color3.fromRGB(255,255,255)
        for _, elData in ipairs(tabData.Elements) do
            if elData.DrawnObject and elData.DrawnObject.Visible ~= nil then elData.DrawnObject.Visible = true end
            if type(elData.DrawnObject) == "table" then 
                for _, subEl in pairs(elData.DrawnObject) do 
                    if subEl and subEl.Visible ~= nil then subEl.Visible = true end 
                end 
            end
        end
        activeWindow.ActiveTab = tabData
    end
    
    table.insert(MayhemLib._Clickables, {Bounds = tabData.Button.Bounds, Callback = setActive, IsActive = function() return activeWindow.WindowFrame ~= nil and activeWindow.WindowFrame.Visible ~= false end}) -- Tab buttons active if window is visible

    table.insert(activeWindow.Tabs, tabData)
    if not activeWindow.ActiveTab then setActive() end

    return tabData
end

local function addElementToTab(tabData, elementMeta, height)
    if not tabData then print("Invalid tab for AddElement."); return nil end

    local elX = activeWindow.ContentContainerPos.X + Config.ElementPadding
    local elY = tabData.NextElementY
    local elWidth = activeWindow.ContentContainerSize.X - Config.ElementPadding * 2
    
    elementMeta.Bounds = Rect.new(elX, elY, elX + elWidth, elY + height)

    local function setupDrawnObject(dObj, isComposite)
        if not dObj then return end
        if isComposite then -- dObj is a table of drawing objects (e.g., button's bg and text)
            for _, subEl in pairs(dObj) do
                 if subEl and subEl.Visible ~= nil then subEl.Visible = tabData.IsActive end
                 -- Relative positioning of sub-elements is assumed to be handled by Create<Element>
                 -- Here, we ensure they are added to the main draw list for dragging and cleanup
                 table.insert(activeWindow.DrawnElementsInWindow, subEl) 
            end
        else -- dObj is a single drawing object
            if dObj.Position then dObj.Position = Vector2.new(elX, elY) end
            -- Text size is handled by Drawing.new("Text").Size, not frame size
            if dObj.Size and (not dObj.Text) then dObj.Size = Vector2.new(elWidth, height) end 
            if dObj.Visible ~= nil then dObj.Visible = tabData.IsActive end
            table.insert(activeWindow.DrawnElementsInWindow, dObj) 
        end
    end

    setupDrawnObject(elementMeta.DrawnObject, type(elementMeta.DrawnObject) == "table" and not elementMeta.DrawnObject.Remove)
    
    table.insert(tabData.Elements, elementMeta)
    tabData.NextElementY = elY + height + Config.ElementPadding
    
    if elementMeta.Callback then 
        table.insert(MayhemLib._Clickables, {
            Bounds = elementMeta.Bounds,
            Callback = elementMeta.Callback,
            IsActive = function() 
                return activeWindow.WindowFrame ~= nil and activeWindow.WindowFrame.Visible ~= false and 
                       tabData.IsActive and 
                       (elementMeta.DrawnObject and ((type(elementMeta.DrawnObject) == "table" and elementMeta.DrawnObject.Background and elementMeta.DrawnObject.Background.Visible ~= false) or (elementMeta.DrawnObject.Visible ~= false)) or true) 
            end
        })
    end
    return elementMeta
end

function MayhemLib:CreateLabel(tabData, text)
    local h = 20
    local drawnText = DrawingAPI.CreateText({
        Text = text, FontName = Config.FontName, Color = Config.TextColor, TextSize = 14,
        XAlignment = "Left", YAlignment = "Top", 
    })
    -- For labels, DrawnObject is the text itself. No separate background managed by default here.
    return addElementToTab(tabData, {Type = "Label", DrawnObject = drawnText, Text = text}, h)
end

function MayhemLib:CreateButton(tabData, text, callback)
    local h = 30
    -- Base positions for layout within the tab (will be set by addElementToTab)
    local elX_relative = 0 
    local elY_relative = 0 
    local elWidth = activeWindow.ContentContainerSize.X - Config.ElementPadding * 2

    -- The positions here are relative to the element's own container, which will be placed by addElementToTab
    local buttonComposite = {
        Background = DrawingAPI.CreateFrame({
            Position = Vector2.new(elX_relative, elY_relative), Size = Vector2.new(elWidth, h), -- Position will be set by addElementToTab
            Color = Config.AccentColor, CornerRadius = Config.CornerRadius,
        }),
        Text = DrawingAPI.CreateText({
            Position = Vector2.new(elX_relative + elWidth/2, elY_relative + h/2), Text = text, FontName = Config.FontName, -- Position relative to Background, then all shifted by addElementToTab
            Color = Color3.fromRGB(255,255,255), TextSize = 14,
            XAlignment = "Center", YAlignment = "Center",
        })
    }
    -- addElementToTab will handle setting the actual screen positions of these composite parts based on elX, elY of the tab content area.
    return addElementToTab(tabData, {Type = "Button", DrawnObject = buttonComposite, Callback = callback}, h)
end


print("[MayhemLib] Executor UI Library Loaded.")
return MayhemLib
