#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "[-] Ошибка: запусти скрипт через sudo (sudo ./start_crypto.sh)"
  exit 1
fi

REAL_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo ~$REAL_USER)
LAB_DIR="$USER_HOME/crypto_lab"

echo "[*] Очистка старых данных полигона..."
userdel -rf backup_admin 2>/dev/null
rm -rf "$LAB_DIR" /home/backup_admin 2>/dev/null

for pkg in john openssl; do
  if ! command -v $pkg &>/dev/null; then
    echo "[*] Установка недостающего пакета: $pkg..."
    apt-get update -qq && apt-get install -y -qq $pkg
  fi
done

echo "[*] Развертывание крипто-полигона в $LAB_DIR..."
mkdir -p "$LAB_DIR/wordlists"
mkdir -p "$LAB_DIR/leaks"


REAL_PASS=$(echo "Y3liZXJwdW5rMjA3Nwo=" | base64 -d)

for i in {1..10}; do
  cat << EOF > "$LAB_DIR/wordlists/dict_$i.txt"
admin123
password
qwerty2026
letmein
welcome1
dragon
master
sunshine
EOF
  if [ "$i" -eq 7 ]; then
    # В 7-й словарь добавляем целевой пароль
    echo "$REAL_PASS" >> "$LAB_DIR/wordlists/dict_$i.txt"
  else
    # В остальные добавляем мусор, чтобы отличались хеши
    echo "corrupted_entry_$RANDOM_$i" >> "$LAB_DIR/wordlists/dict_$i.txt"
  fi
done

ETALON_HASH=$(sha256sum "$LAB_DIR/wordlists/dict_7.txt" | awk '{print $1}')
echo "$ETALON_HASH  Эталонный_словарь_аудитора" > "$LAB_DIR/wordlists/etalon_sha256.txt"

SALT="NaCl99"
HASH=$(openssl passwd -1 -salt "$SALT" "$REAL_PASS")

useradd -m -s /bin/bash -p "$HASH" backup_admin
chmod 700 /home/backup_admin

cat << EOF > "$LAB_DIR/leaks/shadow_leak.txt"
# Дамп утекшей конфигурации аутентификации:
backup_admin:$HASH:19662:0:99999:7:::
EOF

AES_KEY=$(echo "U3VwZXJTZWNyZXRLZXlfQUVTMjU2XyEK" | base64 -d)
AES_KEY_HEX=$(echo -n "$AES_KEY" | xxd -p | tr -d '\n')

FLAG_TEXT="FLAG{CrYpt0_H4sh_And_AES_M4st3r3d_By_You!}"

echo "$FLAG_TEXT" | openssl enc -aes-256-cbc -pbkdf2 -salt -out /home/backup_admin/vault.enc -k "$AES_KEY"

# Оставляем заметку и историю команд от лица сисадмина
cat << EOF > /home/backup_admin/admin_notes.txt
[Заметка администратора резервного копирования]
1. Контейнер с главным секретом (vault.enc) зашифрован алгоритмом AES-256-CBC (с флагом -pbkdf2).
2. Пароль (ключ) от контейнера я перевел в HEX-формат и спрятал в скрытом файле в этой же папке,
   чтобы никто случайно не прочитал его открытым текстом.
3. Точную команду шифрования можно посмотреть в моей истории команд (.bash_history).
EOF

cat << EOF > /home/backup_admin/.key_hex
# Ключ от AES-контейнера в формате HEX (переведи его обратно в текст через xxd -r -p):
$AES_KEY_HEX
EOF

cat << 'EOF' > "$LAB_DIR/README.txt"
===================================================================
     БРИФИНГ: ЛАБОРАТОРНАЯ РАБОТА ПО КРИПТОГРАФИИ И ХЕШАМ
===================================================================

В системе обнаружена закрытая папка пользователя `backup_admin` (/home/backup_admin).
Попробуй заглянуть в неё: `ls -la /home/backup_admin` -> ты получишь Permission denied.
Твоя цель — пройти цепочку из хеширования, брутфорса, кодирования и шифрования,
чтобы зайти под этим пользователем и расшифровать его секретный контейнер.

[ЭТАП 1: Контроль целостности (SHA-256)]
1. Перейди в папку `~/crypto_lab/wordlists/`. Там лежат 10 словарей (`dict_1.txt` .. `dict_10.txt`).
2. Девять из них были повреждены. В файле `etalon_sha256.txt` записан SHA-256 хеш
   единственного неповрежденного словаря.
3. Посчитай `sha256sum` для всех словарей и найди тот, чей хеш совпадает с эталоном.

[ЭТАП 2: Взлом соленого хеша (MD5 + Salt) и смена пользователя]
1. Изучи файл утечки `~/crypto_lab/leaks/shadow_leak.txt`.
   Обрати внимание на формат хеша: `$1$NaCl99$...`
   - Что означает `$1$`? (Какой это алгоритм?)
   - Какая строка здесь выступает в роли «соли» (Salt)?
2. Используй утилиту `john` (John the Ripper) и найденный на Этапе 1 словарь,
   чтобы подобрать пароль к этому хешу:
   `john --wordlist=<путь_к_правильному_словарю> ~/crypto_lab/leaks/shadow_leak.txt`
   *(Если john скажет, что хеш уже сбручен ранее, посмотри ответ через `john --show ...`)*
3. Переключись на пользователя `backup_admin` с помощью найденного пароля:
   `su - backup_admin`

[ЭТАП 3: Анализ улик и декодирование ключа (Hex -> Text)]
1. Теперь ты внутри `/home/backup_admin`! Проверь это командами `whoami` и `pwd`.
2. Осмотри все файлы (включая скрытые: `ls -la`).
3. Прочитай `admin_notes.txt`, `.bash_history` и скрытый файл `.key_hex`.
4. Декодируй строку из `.key_hex` обратно в обычный текст (с помощью `xxd -r -p`),
   чтобы получить ключ для расшифровки контейнера `vault.enc`.

[ЭТАП 4: Расшифровка симметричного шифра (AES-256)]
1. В `.bash_history` видно, как именно администратор зашифровал файл `vault.enc`.
2. Выполни обратную операцию (расшифровку с флагом `-d`) с помощью `openssl`,
   передав найденный на Этапе 3 ключ, и прочитай финальный флаг!
===================================================================
EOF

cat << 'EOF' > /home/backup_admin/.bash_history
ls -la
whoami
openssl enc -aes-256-cbc -pbkdf2 -salt -in raw_flag.txt -out vault.enc -k "<REDACTED_KEY>"
shred -u raw_flag.txt
exit
EOF

chown -R backup_admin:backup_admin /home/backup_admin
chown -R "$REAL_USER:$REAL_USER" "$LAB_DIR"


echo "[+] Полигон успешно развернут!"
echo "[+] Инструкция для старта: cat ~/crypto_lab/README.txt"
