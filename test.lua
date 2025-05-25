--[[
    Mayhem UI Library - Executor Version (Conceptual)

    IMPORTANT: This is a TEMPLATE. You MUST replace `DrawingAPI.*` calls
    with the specific drawing functions provided by YOUR EXECUTOR.
    (e.g., Synapse X: Drawing.new(), KRNL: specific krnl functions, etc.)
]]

local MayhemLib = {}
MayhemLib.__index = MayhemLib

-- Assume these services/functions are available or bridged by the executor
-- If not, you'll need to use executor-specific alternatives.
local HttpService = game:GetService("HttpService") -- Or executor's equivalent like 'HttpGet'
local UserInputService = game:GetService("UserInputService") -- Or executor's input functions
local RunService = game:GetService("RunService") -- For RenderStepped or Heartbeat

-- Configuration (remains largely the same conceptually)
local Config = {
    AccentColor = Color3.fromRGB(0, 120, 255),
    BackgroundColor = Color3.fromRGB(25, 25, 25),
    SecondaryBackgroundColor = Color3.fromRGB(40, 40, 40),
    TertiaryBackgroundColor = Color3.fromRGB(55, 55, 55),
    TextColor = Color3.fromRGB(230, 230, 230),
    Font = "GothamSemibold", -- Font name might be handled differently by executors
    WindowPadding = 8,
    ElementPadding = 6,
    CornerRadius = 5,
    DraggableAreaHeight = 32,
    AnimationSpeed = 0.2, -- May not be directly applicable without TweenService or manual anims
}

-- Placeholder for Executor's Drawing API
-- You WILL need to replace these with actual executor functions
local DrawingAPI = {
    Objects = {}, -- To keep track of drawn objects for cleanup/updates
    NextZIndex = 1,

    _track = function(obj)
        table.insert(DrawingAPI.Objects, obj)
        if obj.ZIndex then obj.ZIndex = DrawingAPI.NextZIndex; DrawingAPI.NextZIndex = DrawingAPI.NextZIndex + 1 end
        return obj
    end,

    CreateFrame = function(properties)
        -- EXAMPLE: return Drawing.new("Square") and set properties
        local obj = { Type = "Frame", Visible = true, Position = Vector2.new(0,0), Size = Vector2.new(100,100), Color = Color3.new(1,1,1), CornerRadius = 0, ZIndex = 0 }
        for k,v in pairs(properties or {}) do obj[k] = v end
        print("[DrawingAPI Stub] CreateFrame:", properties.Name or "Unnamed")
        return DrawingAPI._track(obj)
    end,
    CreateText = function(properties)
        -- EXAMPLE: return Drawing.new("Text") and set properties
        local obj = { Type = "Text", Visible = true, Position = Vector2.new(0,0), Text = "Text", Size = 12, Color = Color3.new(1,1,1), Font = "Arial", ZIndex = 0, XAlignment="Left", YAlignment="Top" }
        for k,v in pairs(properties or {}) do obj[k] = v end
        print("[DrawingAPI Stub] CreateText:", properties.Name or "Unnamed", "Text:", properties.Text)
        return DrawingAPI._track(obj)
    end,
    ClearAll = function()
        for _, obj in ipairs(DrawingAPI.Objects) do
            if obj.Remove then obj:Remove() elseif obj.Destroy then obj:Destroy() end
        end
        DrawingAPI.Objects = {}
        DrawingAPI.NextZIndex = 1
        print("[DrawingAPI Stub] ClearAll")
    end,
    -- Add other necessary functions: CreateLine, CreateImage, GetTextBounds, etc.
}


-- Helper function to make Color3 usable by drawing libs that might expect tables or R,G,B
local function colorToDraw(color3)
    -- Adapt this if your executor expects {R=1, G=0, B=0} or similar
    return color3
end

function MayhemLib:ShowLoadingScreen(testScriptUrl, callbackOnFinish)
    DrawingAPI.ClearAll() -- Clear previous UI if any

    local screenW, screenH = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
    local elements = {}

    elements.Background = DrawingAPI.CreateFrame({
        Name = "LoadingBackground",
        Position = Vector2.new(0, 0),
        Size = Vector2.new(screenW, screenH),
        Color = colorToDraw(Config.BackgroundColor),
        ZIndex = 1000,
    })

    elements.Title = DrawingAPI.CreateText({
        Name = "LoadingTitle",
        Text = "MAYHEM",
        Font = "GothamBlack", -- Ensure executor supports/maps this
        Size = 60,
        Color = colorToDraw(Config.AccentColor),
        Position = Vector2.new(screenW / 2, screenH * 0.35),
        XAlignment = "Center", YAlignment = "Center",
        ZIndex = 1001,
    })
    
    elements.Status = DrawingAPI.CreateText({
        Name = "LoadingStatus",
        Text = "Initializing...",
        Font = Config.Font,
        Size = 18,
        Color = colorToDraw(Config.TextColor),
        Position = Vector2.new(screenW / 2, screenH * 0.5 + 10),
        XAlignment = "Center", YAlignment = "Center",
        ZIndex = 1001,
    })

    local barW, barH = screenW * 0.3, 8
    local barX, barY = screenW / 2 - barW / 2, screenH * 0.5 + 50

    elements.ProgressBarOutline = DrawingAPI.CreateFrame({
        Name = "LoadingBarOutline",
        Position = Vector2.new(barX, barY),
        Size = Vector2.new(barW, barH),
        Color = colorToDraw(Config.SecondaryBackgroundColor),
        CornerRadius = Config.CornerRadius / 2,
        ZIndex = 1001,
    })

    elements.ProgressBarFill = DrawingAPI.CreateFrame({
        Name = "LoadingBarFill",
        Position = Vector2.new(barX, barY), -- Assuming position is top-left for fill
        Size = Vector2.new(0, barH), -- Initial width 0
        Color = colorToDraw(Config.AccentColor),
        CornerRadius = Config.CornerRadius / 2,
        ZIndex = 1002,
    })

    coroutine.wrap(function()
        local function updateProgress(percentage, statusText)
            if elements.Status then elements.Status.Text = statusText end
            if elements.ProgressBarFill then elements.ProgressBarFill.Size = Vector2.new(barW * percentage, barH) end
            -- In a real executor, you'd call a function to redraw or update the drawing object if it doesn't auto-update
            task.wait(0.1) -- Simulate delay
        end

        updateProgress(0.1, "Initializing...")
        task.wait(0.3)
        updateProgress(0.3, "Loading Assets...")
        task.wait(0.5)
        updateProgress(0.6, "Fetching Remote Script...")

        local success, contentOrErr = pcall(function()
            -- Use HttpService or executor's GetAsync/HttpGet
            if HttpService then
                return HttpService:GetAsync(testScriptUrl, true)
            elseif getg and getg().HttpGet then -- Common pattern for some executors
                return getg().HttpGet(testScriptUrl)
            elseif syn and syn.request then -- Synapse X
                 local response = syn.request({Url = testScriptUrl, Method = "GET"})
                 if response.StatusCode == 200 then return response.Body else error(response.StatusMessage) end
            else
                error("No HTTP request function found.")
                return ""
            end
        end)
        
        task.wait(0.5)

        if success then
            updateProgress(0.8, "Executing Script...")
            task.wait(0.2)
            local scriptFunction, scriptError = loadstring(contentOrErr)
            if scriptFunction then
                local execSuccess, execError = pcall(scriptFunction)
                if not execSuccess then
                    updateProgress(0.9, "Execution Error.")
                    warn("[MayhemLib] Error executing test script:", execError)
                    task.wait(1.5)
                else
                    updateProgress(1.0, "Loaded Successfully!")
                end
            else
                updateProgress(0.9, "Loadstring Error.")
                warn("[MayhemLib] Error in loadstring:", scriptError)
                task.wait(1.5)
            end
        else
            updateProgress(0.9, "Fetch Failed.")
            warn("[MayhemLib] Failed to fetch test script:", contentOrErr)
            task.wait(1.5)
        end
        
        task.wait(0.5)

        -- Fade out (conceptual, depends on drawing lib capabilities)
        for _, el in pairs(elements) do
            if el.Remove then el:Remove() elseif el.Destroy then el:Destroy() end
        end
        elements = {} -- Clear table
        DrawingAPI.ClearAll() -- Or selectively remove loading screen elements

        if callbackOnFinish then callbackOnFinish() end
    end)()
end

-- Store active window elements for interaction and updates
local activeWindow = {
    WindowFrame = nil,
    TitleBar = nil,
    TitleText = nil,
    CloseButton = nil,
    TabButtonsContainerY = 0,
    ContentContainerPos = Vector2.new(0,0),
    ContentContainerSize = Vector2.new(0,0),
    Tabs = {}, -- { ButtonObj, ContentFrameObj, Elements = { {Type, Obj, Props, Callback} } }
    ActiveTab = nil,
    DrawnElements = {}, -- All drawing objects associated with this window
    IsDragging = false,
    DragStartMouse = Vector2.new(0,0),
    DragStartPos = Vector2.new(0,0),
}

local function destroyElement(elementObj)
    if elementObj and elementObj.Remove then elementObj:Remove()
    elseif elementObj and elementObj.Destroy then elementObj:Destroy()
    end
end

local function destroyAllWindowElements()
    for _, elGroup in pairs(activeWindow.DrawnElements) do
        if type(elGroup) == "table" and elGroup.Type then -- Single drawing obj
            destroyElement(elGroup)
        elseif type(elGroup) == "table" then -- Group of drawing objs (like a button with bg and text)
            for _, subEl in pairs(elGroup) do
                destroyElement(subEl)
            end
        end
    end
    activeWindow.DrawnElements = {}
    activeWindow.Tabs = {}
    activeWindow.ActiveTab = nil
end


function MayhemLib:CreateWindow(title, width, height)
    destroyAllWindowElements() -- Clear any existing window

    local startX = (workspace.CurrentCamera.ViewportSize.X - width) / 2
    local startY = (workspace.CurrentCamera.ViewportSize.Y - height) / 2
    activeWindow.CurrentPos = Vector2.new(startX, startY)
    activeWindow.Size = Vector2.new(width, height)

    -- Window Frame
    activeWindow.WindowFrame = DrawingAPI.CreateFrame({
        Name = "WindowFrame",
        Position = activeWindow.CurrentPos,
        Size = activeWindow.Size,
        Color = colorToDraw(Config.BackgroundColor),
        CornerRadius = Config.CornerRadius,
        ZIndex = 100,
    })
    table.insert(activeWindow.DrawnElements, activeWindow.WindowFrame)

    -- Draggable Title Bar
    activeWindow.TitleBar = DrawingAPI.CreateFrame({
        Name = "TitleBar",
        Position = activeWindow.CurrentPos,
        Size = Vector2.new(width, Config.DraggableAreaHeight),
        Color = colorToDraw(Config.SecondaryBackgroundColor),
        CornerRadius = Config.CornerRadius, -- May need specific top-left, top-right radius
        ZIndex = 101,
    })
    -- (You might need to draw title bar with only top corners rounded, depending on executor API)
    table.insert(activeWindow.DrawnElements, activeWindow.TitleBar)

    activeWindow.TitleText = DrawingAPI.CreateText({
        Name = "TitleText",
        Position = activeWindow.CurrentPos + Vector2.new(Config.WindowPadding, Config.DraggableAreaHeight / 2),
        Text = title or "Mayhem UI",
        Font = Config.Font,
        Color = colorToDraw(Config.TextColor),
        Size = 16, -- Executor specific font sizing
        XAlignment = "Left", YAlignment = "Center",
        ZIndex = 102,
    })
    table.insert(activeWindow.DrawnElements, activeWindow.TitleText)

    -- Close Button
    local closeSize = Config.DraggableAreaHeight - 12
    activeWindow.CloseButton = {
        Background = DrawingAPI.CreateFrame({
            Name = "CloseButtonBG",
            Position = activeWindow.CurrentPos + Vector2.new(width - closeSize - Config.WindowPadding / 2, (Config.DraggableAreaHeight - closeSize) / 2),
            Size = Vector2.new(closeSize, closeSize),
            Color = colorToDraw(Config.AccentColor),
            CornerRadius = Config.CornerRadius / 2,
            ZIndex = 102
        }),
        Text = DrawingAPI.CreateText({
            Name = "CloseButtonText",
            Position = activeWindow.CurrentPos + Vector2.new(width - closeSize/2 - Config.WindowPadding/2, Config.DraggableAreaHeight / 2),
            Text = "X", Font = Config.Font, Color = colorToDraw(Color3.new(1,1,1)), Size = 16,
            XAlignment = "Center", YAlignment = "Center", ZIndex = 103
        }),
        Bounds = Rect.new(
            activeWindow.CurrentPos.X + width - closeSize - Config.WindowPadding / 2,
            activeWindow.CurrentPos.Y + (Config.DraggableAreaHeight - closeSize) / 2,
            closeSize,
            closeSize
        )
    }
    table.insert(activeWindow.DrawnElements, activeWindow.CloseButton)

    activeWindow.TabButtonsContainerY = activeWindow.CurrentPos.Y + Config.DraggableAreaHeight + Config.ElementPadding
    
    local contentY = activeWindow.TabButtonsContainerY + (Config.DraggableAreaHeight - 5) + Config.ElementPadding * 1.5
    local contentHeight = height - (contentY - activeWindow.CurrentPos.Y) - Config.WindowPadding

    activeWindow.ContentContainerPos = Vector2.new(activeWindow.CurrentPos.X + Config.WindowPadding, contentY)
    activeWindow.ContentContainerSize = Vector2.new(width - Config.WindowPadding * 2, contentHeight)

    activeWindow.ContentFrame = DrawingAPI.CreateFrame({ -- For clipping/background
        Name = "ContentFrame",
        Position = activeWindow.ContentContainerPos,
        Size = activeWindow.ContentContainerSize,
        Color = colorToDraw(Config.SecondaryBackgroundColor),
        CornerRadius = Config.CornerRadius,
        ZIndex = 101,
        -- Clipping is a feature of the drawing lib, if available
    })
    table.insert(activeWindow.DrawnElements, activeWindow.ContentFrame)

    -- Simplified drag logic
    local inputBeganConn, inputChangedConn, inputEndedConn
    inputBeganConn = UserInputService.InputBegan:Connect(function(input)
        if not activeWindow.WindowFrame or not activeWindow.WindowFrame.Visible then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local titleBarRect = Rect.new(activeWindow.TitleBar.Position, activeWindow.TitleBar.Position + activeWindow.TitleBar.Size)
            if mousePos.X >= titleBarRect.Min.X and mousePos.X <= titleBarRect.Max.X and
               mousePos.Y >= titleBarRect.Min.Y and mousePos.Y <= titleBarRect.Max.Y then
                activeWindow.IsDragging = true
                activeWindow.DragStartMouse = mousePos
                activeWindow.DragStartPos = activeWindow.CurrentPos
            end
            -- Close button click
            if activeWindow.CloseButton and activeWindow.CloseButton.Bounds:Contains(mousePos) then
                destroyAllWindowElements() -- Effectively closes the window
                -- MayhemLib:DestroyWindow() or similar cleanup
                activeWindow.WindowFrame = nil -- Mark as closed
            end
        end
    end)
    
    inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if activeWindow.IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = UserInputService:GetMouseLocation()
            local delta = mousePos - activeWindow.DragStartMouse
            local newPos = activeWindow.DragStartPos + delta
            
            local deltaFromOld = newPos - activeWindow.CurrentPos
            activeWindow.CurrentPos = newPos

            -- Update positions of ALL drawn elements relative to the window
            local function updateElementPosition(element, d)
                if element and element.Position then
                    element.Position = element.Position + d
                end
                if element and element.Bounds and type(element.Bounds.Min) == "Vector2" then -- For click bounds
                    element.Bounds = Rect.new(element.Bounds.Min + d, element.Bounds.Max + d)
                end
            end

            for _, elGroup in ipairs(activeWindow.DrawnElements) do
                if type(elGroup) == "table" and elGroup.Type then -- Single Drawing Object
                    updateElementPosition(elGroup, deltaFromOld)
                elseif type(elGroup) == "table" then -- Group (like button with bg and text)
                     for _, subEl in pairs(elGroup) do
                        updateElementPosition(subEl, deltaFromOld)
                    end
                end
            end
            -- Also update positions of elements within tabs
            for _, tabData in ipairs(activeWindow.Tabs) do
                for _, elData in ipairs(tabData.Elements) do
                     if elData.DrawnObject and elData.DrawnObject.Position then
                        elData.DrawnObject.Position = elData.DrawnObject.Position + deltaFromOld
                    elseif type(elData.DrawnObject) == "table" then -- composite element
                        for _, subEl in pairs(elData.DrawnObject) do
                            updateElementPosition(subEl, deltaFromOld)
                        end
                    end
                end
            end
        end
    end)

    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeWindow.IsDragging = false
        end
    end)
    
    -- TODO: Store connections to disconnect them if window is destroyed
    print("[MayhemLib Stub] Window Created. Remember to implement drawing calls.")
    return MayhemLib -- Return self for chaining or to signify window object
end


local tabButtonWidth = 100
local tabButtonHeight = Config.DraggableAreaHeight - 10

function MayhemLib:CreateTab(windowRef, title) -- windowRef is MayhemLib itself for now
    if not activeWindow.WindowFrame then print("Window not created"); return nil end

    local tabIndex = #activeWindow.Tabs + 1
    local tabX = activeWindow.CurrentPos.X + Config.WindowPadding + (tabIndex - 1) * (tabButtonWidth + Config.ElementPadding / 2)
    local tabY = activeWindow.TabButtonsContainerY

    local tabData = {
        Title = title,
        Elements = {}, -- { Type, DrawnObject(s), Props, Callback, Bounds }
        DrawnObjects = {}, -- Store the drawing objects for this tab's content
        IsActive = false,
        NextElementY = activeWindow.ContentContainerPos.Y + Config.ElementPadding, -- Start Y for elements in this tab
    }

    tabData.Button = {
        Background = DrawingAPI.CreateFrame({
            Name = title .. "TabButtonBG",
            Position = Vector2.new(tabX, tabY),
            Size = Vector2.new(tabButtonWidth, tabButtonHeight),
            Color = colorToDraw(Config.TertiaryBackgroundColor),
            CornerRadius = Config.CornerRadius / 1.5,
            ZIndex = 102,
        }),
        Text = DrawingAPI.CreateText({
            Name = title .. "TabButtonText",
            Position = Vector2.new(tabX + tabButtonWidth/2, tabY + tabButtonHeight/2),
            Text = title, Font = Config.Font, Color = colorToDraw(Config.TextColor), Size = 14,
            XAlignment = "Center", YAlignment = "Center", ZIndex = 103,
        }),
        Bounds = Rect.new(tabX, tabY, tabButtonWidth, tabButtonHeight)
    }
    table.insert(activeWindow.DrawnElements, tabData.Button) -- Add to main draw list
    
    local function setActive()
        if activeWindow.ActiveTab == tabData then return end
        
        if activeWindow.ActiveTab then
            activeWindow.ActiveTab.IsActive = false
            activeWindow.ActiveTab.Button.Background.Color = colorToDraw(Config.TertiaryBackgroundColor)
            activeWindow.ActiveTab.Button.Text.Color = colorToDraw(Config.TextColor)
            for _, elData in ipairs(activeWindow.ActiveTab.Elements) do -- Hide elements of old tab
                if elData.DrawnObject and elData.DrawnObject.Visible ~= nil then elData.DrawnObject.Visible = false end
                if type(elData.DrawnObject) == "table" then for _, subEl in pairs(elData.DrawnObject) do if subEl.Visible ~= nil then subEl.Visible = false end end end
            end
        end

        tabData.IsActive = true
        tabData.Button.Background.Color = colorToDraw(Config.AccentColor)
        tabData.Button.Text.Color = colorToDraw(Color3.fromRGB(255,255,255))
        for _, elData in ipairs(tabData.Elements) do -- Show elements of new tab
            if elData.DrawnObject and elData.DrawnObject.Visible ~= nil then elData.DrawnObject.Visible = true end
            if type(elData.DrawnObject) == "table" then for _, subEl in pairs(elData.DrawnObject) do if subEl.Visible ~= nil then subEl.Visible = true end end end
        end
        activeWindow.ActiveTab = tabData
    end
    
    -- Connect click for tab button (needs to be in InputBegan or a RenderStepped check)
    -- For simplicity, this logic needs to be integrated into the main InputBegan handler
    -- or a dedicated click manager loop.
    -- Let's assume a simplified global click handler for now:
    MayhemLib._AddClickable(tabData.Button.Bounds, setActive)

    table.insert(activeWindow.Tabs, tabData)
    if not activeWindow.ActiveTab then setActive() end -- Activate first tab

    return tabData -- Return the tab object so elements can be added to it
end

-- Internal: manage clickables. In real executor UI, this is handled by its event system.
MayhemLib._Clickables = {}
MayhemLib._AddClickable = function(bounds, callback)
    table.insert(MayhemLib._Clickables, {Bounds = bounds, Callback = callback})
end
-- This would be checked in UserInputService.InputBegan
-- (This is a very simplified click handling for example purposes)
if not MayhemLib._ClickListenerAttached then
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not activeWindow.WindowFrame or (activeWindow.WindowFrame.Visible == false) then return end
            local mousePos = UserInputService:GetMouseLocation()
            for _, clickable in ipairs(MayhemLib._Clickables) do
                -- Check if clickable is part of active tab or always visible (like tab buttons)
                local isRelevant = false
                if activeWindow.ActiveTab then
                    for _, elData in ipairs(activeWindow.ActiveTab.Elements) do
                        if elData.Bounds == clickable.Bounds and elData.DrawnObject and (elData.DrawnObject.Visible == nil or elData.DrawnObject.Visible) then
                           isRelevant = true; break
                        end
                    end
                end
                -- Check tab buttons
                for _, tabItem in ipairs(activeWindow.Tabs) do
                    if tabItem.Button and tabItem.Button.Bounds == clickable.Bounds then
                        isRelevant = true; break
                    end
                end


                if isRelevant and clickable.Bounds:Contains(mousePos) then
                    clickable.Callback()
                    break -- Process one click
                end
            end
        end
    end)
    MayhemLib._ClickListenerAttached = true
end


local function addElementToTab(tabData, elementInfo, height)
    if not tabData then print("Invalid tab."); return nil end

    local elX = activeWindow.ContentContainerPos.X + Config.ElementPadding
    local elY = tabData.NextElementY
    local elWidth = activeWindow.ContentContainerSize.X - Config.ElementPadding * 2
    
    -- Update position for drawing objects
    if elementInfo.DrawnObject and elementInfo.DrawnObject.Position then
        elementInfo.DrawnObject.Position = Vector2.new(elX, elY)
        elementInfo.DrawnObject.Size = Vector2.new(elWidth, height)
         if elementInfo.DrawnObject.Visible ~= nil then elementInfo.DrawnObject.Visible = tabData.IsActive end
    elseif type(elementInfo.DrawnObject) == "table" then -- For composite elements
        for _, subEl in pairs(elementInfo.DrawnObject) do
            -- Adjust sub-element positions relative to elX, elY
            -- This needs careful handling based on how composite elements are defined
             if subEl.Visible ~= nil then subEl.Visible = tabData.IsActive end
        end
    end
    
    elementInfo.Bounds = Rect.new(elX, elY, elWidth, height)
    table.insert(tabData.Elements, elementInfo)
    table.insert(activeWindow.DrawnElements, elementInfo.DrawnObject) -- Also add to main draw list for positioning on drag

    tabData.NextElementY = elY + height + Config.ElementPadding
    return elementInfo -- Or the main drawn object
end


function MayhemLib:CreateLabel(tabData, text)
    local h = 20
    local drawnText = DrawingAPI.CreateText({
        Name = "Label_" .. text:sub(1,10),
        Text = text, Font = Config.Font, Color = colorToDraw(Config.TextColor), Size = 14,
        XAlignment = "Left", YAlignment = "Top", ZIndex = 110,
        -- Position and Size will be set by addElementToTab
    })
    return addElementToTab(tabData, {Type = "Label", DrawnObject = drawnText, Text = text}, h)
end

function MayhemLib:CreateButton(tabData, text, callback)
    local h = 30
    local elX = activeWindow.ContentContainerPos.X + Config.ElementPadding -- Placeholder, set in addElement
    local elY = tabData.NextElementY -- Placeholder
    local elWidth = activeWindow.ContentContainerSize.X - Config.ElementPadding * 2 -- Placeholder

    local buttonElement = {
        DrawnObject = {
            Background = DrawingAPI.CreateFrame({
                Name = "ButtonBG_"..text:sub(1,5),
                Color = colorToDraw(Config.AccentColor), CornerRadius = Config.CornerRadius, ZIndex = 110,
            }),
            Text = DrawingAPI.CreateText({
                Name = "ButtonText_"..text:sub(1,5), Text = text, Font = Config.Font,
                Color = colorToDraw(Color3.fromRGB(255,255,255)), Size = 14,
                XAlignment = "Center", YAlignment = "Center", ZIndex = 111,
            })
        },
        Callback = callback,
        Type = "Button"
    }
    
    local addedEl = addElementToTab(tabData, buttonElement, h)
    
    -- Update actual positions for the sub-drawing objects based on final placement
    if addedEl and addedEl.Bounds then
        addedEl.DrawnObject.Background.Position = addedEl.Bounds.Min
        addedEl.DrawnObject.Background.Size = addedEl.Bounds.Max - addedEl.Bounds.Min
        addedEl.DrawnObject.Text.Position = addedEl.Bounds.Min + (addedEl.Bounds.Max - addedEl.Bounds.Min) / 2
        if callback then MayhemLib._AddClickable(addedEl.Bounds, callback) end
    end
    return addedEl
end

-- Add CreateToggle, CreateTextbox, CreateSlider, CreateMultiLineEdit similarly...
-- These will be more complex as they involve more drawing parts and interaction logic.
-- For example, a Toggle needs a box and a checkmark, and click logic to change state and color.
-- A Textbox needs a background, text display, cursor, and input capture (VERY executor-specific).

print("[MayhemLib Executor Template] Loaded. Replace DrawingAPI calls with your executor's specifics.")

return MayhemLib
