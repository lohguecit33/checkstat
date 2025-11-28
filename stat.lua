local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ======================
-- TIER LIST
-- ======================
local TierList = {
    Fruits = {
        Mythical = {"Tiger", "Mammoth", "T-Rex", "Kitsune", "Gas", "Yeti", "Dragon", "Dough", "Spirit", "Shadow", "Venom", "Control", "Blizzard", "Pain", "Portal"},
        Legendary = {"Rumble", "Buddha", "Phoenix", "Gravity", "Magma", "Diamond", "Sound", "Paw", "Quake", "Buddha", "Creation", "Love"},
        Rare = {"Rubber", "Sand", "Light", "Ice", "Flame", "Dark", "Smoke", "Spring", "Falcon"},
        Uncommon = {"Spike", "Bomb", "Chop"},
        Common = {"Spin", "Rocket"}
    },

    Swords = {
        Mythical = {"Cursed Dual Katana", "Dark Blade", "True Triple Katana", "Tushita", "Yama", "Hallow Scythe"},
        Legendary = {"Rengoku", "Saber", "Shark Anchor", "Shisui", "Canvander", "Longsword", "Pole", "Bisento"},
        Rare = {"Wando", "Saddi", "Midnight Blade", "Dragon Trident", "Gravity Cane", "Soul Cane"},
        Uncommon = {"Katana", "Cutlass", "Iron Mace", "Dual Katana"},
        Common = {"Pipe", "Triple Katana", "Dual-Headed Blade"}
    },

    Guns = {
        Mythical = {"Soul Guitar", "Dragonstorm"},
        Legendary = {"Kabucha", "Acidum Rifle", "Venom Bow", "Serpent Bow", "Musket", "Bazooka"},
        Rare = {"Cannon", "Refined Slingshot", "Flintlock"},
        Uncommon = {"Slingshot", "Dual Flintlock"},
        Common = {"Pistol"}
    }
}

-- Fungsi mendeteksi tier
local function getTier(category, itemName)
    local list = TierList[category]
    if not list then return "Unknown" end

    for tier, items in pairs(list) do
        for _, name in ipairs(items) do
            if string.find(itemName, name) then
                return tier
            end
        end
    end
    return "Unknown"
end

-- =========================================================
-- FUNGSI MENGAMBIL DATA INVENTORY DARI SERVER
-- =========================================================
local function getServerInventory()
    local inventoryData = {
        Fruits = {},
        Weapons = {},
        Materials = {}
    }

    pcall(function()
        local args = {[1] = "getInventory"}
        local inv = ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))

        if inv then
            for _, item in pairs(inv) do
                if item.Type == "Blox Fruit" then
                    local cleanName = string.gsub(item.Name, "(.+)-%1", "%1")
                    table.insert(inventoryData.Fruits, cleanName)

                elseif item.Type == "Material" then
                    table.insert(inventoryData.Materials, item.Name)

                elseif item.Type == "Sword" or item.Type == "Gun" then
                    table.insert(inventoryData.Weapons, item.Name)
                end
            end
        end
    end)

    return inventoryData
end

-- =========================================================
-- FUNGSI MENGAMBIL DATA PEMAIN
-- =========================================================
local function getPlayerData()

    local playerData = {
        AccountInfo = {},
        Stats = {},
        Equipment = {},
        Inventory = {
            Fruits = {},
            Swords = {},
            Guns = {},
            Accessories = {},
            Materials = {}
        },
        Timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }

    -- ===== INFO AKUN =====
    playerData.AccountInfo.Username = LocalPlayer.Name
    playerData.AccountInfo.DisplayName = LocalPlayer.DisplayName
    playerData.AccountInfo.UserId = LocalPlayer.UserId

    -- ===== LEVEL DAN STATS =====
    local dataFolder = LocalPlayer:FindFirstChild("Data")
    if dataFolder then
        if dataFolder:FindFirstChild("Level") then
            playerData.Stats.Level = dataFolder.Level.Value
        end
        if dataFolder:FindFirstChild("Beli") then
            playerData.Stats.Beli = dataFolder.Beli.Value
        end
        if dataFolder:FindFirstChild("Fragments") then
            playerData.Stats.Fragments = dataFolder.Fragments.Value
        end
        if dataFolder:FindFirstChild("Race") then
            playerData.Stats.Race = dataFolder.Race.Value
        end
        if dataFolder:FindFirstChild("DevilFruit") then
            playerData.Equipment.EquippedFruit = dataFolder.DevilFruit.Value
        end
    end

    -- ===== MELEE =====
    local character = LocalPlayer.Character
    local meleeList = {
        "Combat", "Superhuman", "Electric Claw", "Dragon Talon",
        "Sharkman Karate", "Death Step", "Godhuman", "Sanguine Art"
    }

    local function isMelee(name)
        for _, m in ipairs(meleeList) do
            if string.lower(name) == string.lower(m) then
                return true
            end
        end
        return false
    end

    local equippedMelee = nil

    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and isMelee(tool.Name) then
                equippedMelee = tool.Name
                _G.LastKnownMelee = tool.Name -- UPDATE JIKA MELEE ADA
                break
            end
        end
    end

    -- Jika sedang pegang sword → pakai melee yang terakhir kali digunakan
    playerData.Equipment.EquippedMelee = equippedMelee or _G.LastKnownMelee


    -- ===== INVENTORY =====
    local serverInventory = getServerInventory()

    -- Fruits (with tier)
    for _, fruitName in ipairs(serverInventory.Fruits) do
        table.insert(playerData.Inventory.Fruits, {
            Name = fruitName,
            Tier = getTier("Fruits", fruitName)
        })
    end

    -- Materials
    for _, mat in ipairs(serverInventory.Materials) do
        table.insert(playerData.Inventory.Materials, mat)
    end

    -- Weapons (Sword/Gun with tier)
    for _, weaponName in ipairs(serverInventory.Weapons) do
        local name = weaponName

        local isSword = getTier("Swords", name) ~= "Unknown"
        local isGun = getTier("Guns", name) ~= "Unknown"

        if isSword then
            table.insert(playerData.Inventory.Swords, {
                Name = name,
                Tier = getTier("Swords", name)
            })

        elseif isGun then
            table.insert(playerData.Inventory.Guns, {
                Name = name,
                Tier = getTier("Guns", name)
            })
        end
    end

    -- Accessories
    if character then
        for _, accessory in ipairs(character:GetDescendants()) do
            if accessory:IsA("Accessory") then
                table.insert(playerData.Inventory.Accessories, accessory.Name)
            end
        end
    end

    return playerData
end

-- =========================================================
-- SIMPAN KE FILE JSON
-- =========================================================
local function saveToJSON()
    local success, errorMsg = pcall(function()
        local data = getPlayerData()
        local jsonData = HttpService:JSONEncode(data)

        local fileName = string.format("bf.%s.json", data.AccountInfo.Username)

        if writefile then
            writefile(fileName, jsonData)
            print("Saved:", fileName)
        else
            print("Executor tidak support writefile!")
            print(jsonData)
        end
    end)

    if not success then
        warn("ERROR EXPORT:", errorMsg)
    end
end

-- =========================================================
-- AUTO EXPORT LOOP
-- =========================================================
local function startAutoExport()
    print("\nBlox Fruits Auto Export v3 WITH TIER SYSTEM")
    wait(3)
    saveToJSON()

    spawn(function()
        while true do
            wait(60)
            saveToJSON()
        end
    end)
end

startAutoExport()
