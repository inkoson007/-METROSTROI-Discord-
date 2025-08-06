# Discord DCH Notify
Аддон для Garry's Mod, который интегрируется с системой Диспетчера Metrostroi. Он отправляет уведомления о ключевых событиях системы диспетчера (ДЦХ/ДСЦП) в ваш канал Discord. Аддон использует PHP-прокси для обхода ограничений на отправку запросов напрямую из GMod в Discord.

**Необходимый аддон:** [Мастерская Steam::Metrostroi Dispatcher](https://github.com/Alexell/metrostroi_dispatcher)

![Garry's Mod & Discord Logo](https://koffee-project.site/img/koffee-logo.png)

## 📝 Описание
Этот аддон для Garry's Mod интегрируется с Metrostroi и отправляет уведомления о ключевых событиях Диспетчерской Системы (ДЦХ/ДСЦП) в ваш Discord-канал. Он использует PHP-прокси для обхода ограничений на отправку запросов из GMod напрямую в Discord.

## ✨ Особенности
* **Уведомления о ДЦХ:** Сообщает, когда игрок заступает на пост диспетчера или покидает его.
* **Уведомления о ДСЦП:** Отправляет уведомления о назначении и снятии ДСЦП.
* **Уведомления о смене интервала:** Сообщает о смене интервала ДЦХ.

---

## 🛠️ Установка

Процесс установки состоит из двух шагов: настройка PHP-прокси и установка самого аддона в Garry's Mod.

### Шаг 1: Настройка PHP-прокси
1.  Создайте файл с именем `webhook_proxy.php` на вашем веб-сервере.
2.  Скопируйте и вставьте следующий код в этот файл:
    ```php
    <?php
    // === Discord Webhook Proxy ===
    // Автор: INK 
    // webhook_proxy.php

    // Установи свой Discord Webhook ниже:
    $discord_webhook_url = "https://ВАШ_URL_ВЕБХУКА_DISCORD";

    // Получение JSON-запроса
    $input = file_get_contents('php://input');
    if (!$input) {
        http_response_code(400);
        echo "Нет входных данных";
        exit;
    }

    // Отправка в Discord
    $ch = curl_init($discord_webhook_url);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
    curl_setopt($ch, CURLOPT_POSTFIELDS, $input);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Content-Length: ' . strlen($input)
    ]);

    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    http_response_code($http_code);
    echo $response;
    ```
3.  **Важно:** Замените `https://ВАШ_URL_ВЕБХУКА_DISCORD` на URL вашего Discord-вебхука. Вы можете получить его в настройках Discord-канала.
4.  Сохраните и загрузите файл на ваш веб-сервер. Запомните полный URL к этому файлу (например, `http://mywebsite.com/webhook_proxy.php`).

### Шаг 2: Установка аддона GMod
1.  Создайте папку `discord_dhc_notify` в директории `addons` вашего GMod сервера.
2.  Внутри этой папки создайте еще одну папку `lua`.
3.  Внутри папки `lua` создайте папку `autorun`.
4.  Создайте файл `discord_dhc_notify.lua` внутри папки `autorun`. Полный путь будет `addons/discord_dhc_notify/lua/autorun/discord_dhc_notify.lua`.
5.  Скопируйте и вставьте следующий код в этот файл:
    ```lua
    --> Developer By INK <--------------------------------------------------------------------------------

    -- Конфигурация --------------------------------------------------------------------------------
    local PROXY_URL = "http://ВАШ_ДОМЕН/webhook_proxy.php"
    local LOGGING_ENABLED = true
    local DEFAULT_AVATAR = "https://ВАШ_URL" -- для аватара 
    local BOT_AVATAR = "https://ВАШ_URL" -- для аватара 

    local function LogMessage(msg)
        if LOGGING_ENABLED then
            print("[ДЦХ System] " .. msg)
        end
    end
    ---------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    local function SafeGetNick(ply)
        if IsValid(ply) and ply:IsPlayer() then
            local success, result = pcall(function() return ply:Nick() end)
            if success then return result end
        end
        return "Неизвестный"
    end
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    local function GetPlayerAvatar(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return DEFAULT_AVATAR end
        local steamid64 = ply:SteamID64()
        if not steamid64 then return DEFAULT_AVATAR end
        return "[https://avatars.akamai.steamstatic.com/](https://avatars.akamai.steamstatic.com/)" .. string.sub(steamid64, -2) .. "/" .. steamid64 .. "_full.jpg"
    end
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    function SendToDiscord(embed, ply)
        if IsValid(ply) and ply:IsPlayer() then
            embed.thumbnail = { url = GetPlayerAvatar(ply) }
        end

        local payload = {
            embeds = {embed},
            username = "ДЦХ Монитор",
            avatar_url = BOT_AVATAR
        }

        local jsonPayload = util.TableToJSON(payload)
        if not jsonPayload then
            LogMessage("Ошибка: не удалось преобразовать таблицу в JSON")
            return
        end

        HTTP({
            url = PROXY_URL,
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json"
            },
            body = jsonPayload,
            success = function(code, body, headers)
                if code ~= 204 and code ~= 200 then
                    LogMessage("Ошибка отправки через прокси: Код "..code..". Ответ: "..tostring(body))
                else
                    LogMessage("Уведомление успешно отправлено через прокси")
                end
            end,
            failed = function(err)
                LogMessage("Ошибка HTTP запроса к прокси: " .. tostring(err))
            end
        })
    end
    --------------------------------------------------------------------------------
    -- Хук: Игрок заступил на пост ДЦХ --------------------------------------------------------------------------------
    hook.Add("MDispatcher.TookPost", "DiscordNotify_TookPost", function(nick, ply)
        nick = nick or SafeGetNick(ply)
        local embed = {
            title = "🚔 Назначение на пост ДЦХ",
            description = "**" .. nick .. "** заступил на пост диспетчера",
            color = 0x3498db,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
        }
        SendToDiscord(embed, ply)
        LogMessage(nick .. " заступил на пост ДЦХ")
    end)
    --------------------------------------------------------------------------------
    -- Хук: Игрок покинул пост ДЦХ --------------------------------------------------------------------------------
    hook.Add("MDispatcher.FreedPost", "DiscordNotify_FreedPost", function(nick, ply)
        nick = nick or SafeGetNick(ply)
        local embed = {
            title = "🚔 Освобождение поста ДЦХ",
            description = "**" .. nick .. "** покинул пост диспетчера",
            color = 0xe74c3c,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
        }
        SendToDiscord(embed, ply)
        LogMessage(nick .. " покинул пост ДЦХ")
    end)
    --------------------------------------------------------------------------------
    -- Хук: Изменение интервала --------------------------------------------------------------------------------
    hook.Add("MDispatcher.SetInt", "DiscordNotify_SetInt", function(nick, interval, ply)
        nick = nick or SafeGetNick(ply)
        local embed = {
            title = "⏱ Изменение интервала",
            description = "**" .. nick .. "** установил интервал: **" .. interval .. "**",
            color = 0xf1c40f,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
        }
        SendToDiscord(embed, ply)
        LogMessage(nick .. " изменил интервал на " .. interval)
    end)
    --------------------------------------------------------------------------------
    -- Хук: Назначение ДСЦП --------------------------------------------------------------------------------
    hook.Add("MDispatcher.DSCPSet", "DiscordNotify_DSCPSet", function(message, ply)
        local embed = {
            title = "🚦 Назначение ДСЦП",
            description = message,
            color = 0x2ecc71,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
        }
        SendToDiscord(embed, ply)
        LogMessage("Назначен ДСЦП: " .. message)
    end)
    --------------------------------------------------------------------------------
    -- Хук: Снятие ДСЦП --------------------------------------------------------------------------------
    hook.Add("MDispatcher.DSCPUnset", "DiscordNotify_DSCPUnset", function(message, ply)
        local embed = {
            title = "🚦 Снятие ДСЦП",
            description = message,
            color = 0xe74c3c,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
        }
        SendToDiscord(embed, ply)
        LogMessage("Снят ДСЦП: " .. message)
    end)
    --------------------------------------------------------------------------------
    LogMessage("[✅] -> Система Discord уведомлений для ДЦХ/ДСЦП загружена V1.3 <-")
    ```
6.  **Важно:** Замените `http://ВАШ_ДОМЕН/webhook_proxy.php` на URL вашего PHP-прокси-скрипта.
7.  Перезапустите ваш сервер Garry's Mod.
