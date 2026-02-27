-- =====================================================
-- DISCORD WEBHOOK NOTIFICATION SCRIPT
-- Untuk Roblox: Notifikasi player join/leave + tag role
-- =====================================================

-- =====================================================
-- KONFIGURASI (UBAH SESUAI PUNYA ANDA!)
-- =====================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1450176835970138142/5n71qT8fsfCiKfHG3eyZpjnExAu3nN5Ku2wyDAr7iH_5e0po6JNMSFwu_-W4D4CfZjqh"
local ROLE_ID = "944397737607184484"  -- Bisa "@everyone" atau ID role (contoh: "123456789012345678")
local SERVER_NAME = "Fenn" -- Nama server untuk display

-- =====================================================
-- FUNGSI KIRIM KE DISCORD
-- =====================================================
local function sendToDiscord(title, description, color, ping)
    local HttpService = game:GetService("HttpService")
    
    -- Validasi webhook
    if not WEBHOOK_URL or WEBHOOK_URL == "" then
        warn("[ERROR] Webhook URL tidak dikonfigurasi!")
        return
    end
    
    -- Format content untuk ping role
    local content = ""
    if ping then
        if ping == "@everyone" or ping == "@here" then
            content = ping .. " "
        else
            content = "<@&" .. ping .. "> "
        end
    end
    
    -- Buat embed Discord
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 5814783,
            ["footer"] = {
                ["text"] = SERVER_NAME .. " • " .. os.date("%Y-%m-%d %H:%M:%S")
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
    }
    
    -- Payload lengkap
    local payload = {
        ["content"] = content,
        ["embeds"] = embed
    }
    
    -- Kirim
    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
    end)
    
    if success then
        print("[DISCORD] Notifikasi terkirim")
    else
        warn("[DISCORD] Gagal kirim: " .. tostring(err))
    end
end

-- =====================================================
-- HANDLER PLAYER JOIN
-- =====================================================
local function onPlayerJoined(player)
    -- Tunggu sampai data player lengkap
    player:WaitForChild("DisplayName")
    
    -- Format pesan
    local title = "🟢 PLAYER JOINED"
    local desc = string.format(
        "**%s** telah bergabung ke server!\n\n**Informasi Pemain:**\n• Username: `%s`\n• Display Name: `%s`\n• User ID: `%s`\n• Account Age: `%d` hari",
        player.DisplayName,
        player.Name,
        player.DisplayName,
        player.UserId,
        player.AccountAge
    )
    
    sendToDiscord(title, desc, 5763719, false) -- Warna hijau
end

-- =====================================================
-- HANDLER PLAYER LEAVE
-- =====================================================
local function onPlayerLeaving(player)
    -- Format pesan
    local title = "🔴 PLAYER LEFT"
    local desc = string.format(
        "**%s** telah meninggalkan server!\n\n**Informasi Pemain:**\n• Username: `%s`\n• Display Name: `%s`\n• User ID: `%s`\n• Lama Main: `%d detik`",
        player.DisplayName or player.Name,
        player.Name,
        player.DisplayName or player.Name,
        player.UserId,
        player:GetAttribute("TimeJoined") and (os.time() - player:GetAttribute("TimeJoined")) or 0
    )
    
    sendToDiscord(title, desc, 16711680, ROLE_ID) -- Warna merah + tag role
end

-- =====================================================
-- HANDLER PLAYER CHAT (OPSIONAL)
-- =====================================================
local function onPlayerChat(player, message)
    -- Hanya aktif jika diaktifkan (bisa di-uncomment)
    --[[
    if string.lower(message) == "ping" then
        local title = "💬 PLAYER CHAT"
        local desc = string.format(
            "**%s** mengirim pesan:\n> %s",
            player.DisplayName or player.Name,
            message
        )
        sendToDiscord(title, desc, 16776960, false) -- Warna kuning
    end
    ]]
end

-- =====================================================
-- SETUP & CONNECTION
-- =====================================================
local Players = game:GetService("Players")

-- Simpan waktu join di attribute player
local function setupPlayer(player)
    player:SetAttribute("TimeJoined", os.time())
end

-- Connect events
Players.PlayerAdded:Connect(function(player)
    setupPlayer(player)
    onPlayerJoined(player)
end)

Players.PlayerRemoving:Connect(onPlayerLeaving)

-- Chat event (optional)
local function setupChat()
    local success, result = pcall(function()
        return require(game:GetService("ServerScriptService").ChatServiceRunner)
    end)
    
    if success then
        local ChatService = require(game:GetService("ServerScriptService").ChatService)
        ChatService:RegisterProcessCommandsFunction("WebhookNotif", function(speakerName, message)
            local player = Players:FindFirstChild(speakerName)
            if player then
                onPlayerChat(player, message)
            end
        end)
    end
end

-- Setup chat (uncomment jika mau)
-- setupChat()

print("[SYSTEM] Discord Webhook Notifier siap!")
print("[SYSTEM] Webhook: " .. WEBHOOK_URL)
print("[SYSTEM] Role ID: " .. ROLE_ID)
