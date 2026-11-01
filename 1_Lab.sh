#!/bin/bash

rm -rf ~/cyber_lab ~/.strange_artifact /tmp/lab_cache_* /tmp/secret_backup.bak 2>/dev/null
pkill -f "http.server 8888" 2>/dev/null

echo "[*] Инициализация полигона..."

mkdir -p ~/cyber_lab/logs
mkdir -p ~/cyber_lab/tasks


cat << 'EOF' > ~/.strange_artifact.jpg
[УЛИКА #1]
Ты нашел скрытый файл и проверил его тип! Расширение .jpg было фальшивкой.
Зацепка: злоумышленник оставил бэкап где-то во временных папках системы под именем secret_backup.bak
EOF

mkdir -p /tmp/lab_cache_01/deep/folder
cat << 'EOF' > /tmp/lab_cache_01/deep/folder/secret_backup.bak
[УЛИКА #2]
Отличная работа с find!
Следующий шаг: проанализируй файл ~/cyber_lab/logs/access.log.
Кто-то пытался подобрать пароль к админке. Вычисли топ-3 самых активных IP-адресов.
EOF

mkdir -p /tmp/lab_cache_locked_1 /tmp/lab_cache_locked_2
chmod 000 /tmp/lab_cache_locked_1 /tmp/lab_cache_locked_2 2>/dev/null

LOG_FILE=~/cyber_lab/logs/access.log
> "$LOG_FILE"

for i in {1..42}; do echo "185.220.101.45 - - [01/Nov/2026:10:15:$((10+i)) +0300] \"POST /admin/login HTTP/1.1\" 401 512 \"FAILED_LOGIN\"" >> "$LOG_FILE"; done
for i in {1..25}; do echo "45.155.205.10 - - [01/Nov/2026:10:16:$((10+i)) +0300] \"POST /wp-login.php HTTP/1.1\" 403 256 \"FAILED_LOGIN\"" >> "$LOG_FILE"; done
for i in {1..12}; do echo "192.168.1.105 - - [01/Nov/2026:10:17:$((10+i)) +0300] \"GET /index.html HTTP/1.1\" 200 1024 \"OK\"" >> "$LOG_FILE"; done
for i in {1..5};  do echo "10.0.0.5 - - [01/Nov/2026:10:18:$((10+i)) +0300] \"GET /style.css HTTP/1.1\" 200 4096 \"OK\"" >> "$LOG_FILE"; done
for i in {1..3};  do echo "172.16.0.22 - - [01/Nov/2026:10:19:$((10+i)) +0300] \"POST /api/v1/auth HTTP/1.1\" 500 128 \"ERROR_DB\"" >> "$LOG_FILE"; done

shuf "$LOG_FILE" -o "$LOG_FILE"

if command -v python3 &>/dev/null; then
    nohup python3 -m http.server 8888 --bind 127.0.0.1 >/dev/null 2>&1 &
fi

mkdir -p /tmp/lab_cache_02/dump
for i in {1..30}; do
    echo "System dump file #$i. Nothing interesting here. Status: OK" > "/tmp/lab_cache_02/dump/dump_$i.txt"
done

echo "FLAG: V2VsbCBEb25lISBMaW51eCBhbmQgT1NJIGJhc2ljcyBtYXN0ZXJlZCEK" >> "/tmp/lab_cache_02/dump/dump_17.txt"
echo "[+] Полигон успешно развернут!"
