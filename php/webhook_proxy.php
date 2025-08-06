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
