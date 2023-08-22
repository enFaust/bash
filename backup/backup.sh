#!/bin/bash

BOT_TOKEN="your_token"
CHAT_ID="your_chat_id"

SOURCE_DIR="source_path"
BACKUP_DIR="backup_path"

BACKUP_DATE="$(date +'%Y%m%d')1"

if ! command -v rsync >/dev/null; then
    echo "Утилита rsync не установлена. Установите ее перед использованием."
    exit 1
fi

if ! command -v gzip >/dev/null; then
    echo "Утилита gzip не установлена. Установите ее перед использованием."
    exit 1
fi

if ! command -v mutt >/dev/null; then
    echo "Утилита mutt не установлена. Установите ее перед использованием."
    exit 1
fi

if ! command -v curl >/dev/null; then
    echo "Утилита curl не установлена. Установите ее перед использованием."
    exit 1
fi

# Создание инкрементальной копии
if [ $(ls -1 "$BACKUP_DIR" | wc -l) -gt 0 ]; then
    LATEST_FILE=$(ls -1t "$BACKUP_DIR" | head -n 1)
    ln -sfn "$LATEST_FILE" "$BACKUP_DIR/previous_backup"
    rsync -a --delete --link-dest="$BACKUP_DIR/previous_backup" "$SOURCE_DIR" "$BACKUP_DIR/backup_$BACKUP_DATE"
else
    rsync -a "$SOURCE_DIR" "$BACKUP_DIR/backup_$BACKUP_DATE"
fi

# Компрессия резервной копии
cd $BACKUP_DIR
tar -czf "backup_$BACKUP_DATE.tar.gz" "backup_$BACKUP_DATE"
rm -rd "backup_$BACKUP_DATE"

echo "Резервная копия завершена."

FILE_PATH="$BACKUP_DIR/backup_$BACKUP_DATE.tar.gz"

echo "$FILE_PATH"

if [ ! -f "$FILE_PATH" ]; then
    echo "File not found: $FILE_PATH"
    exit 1
fi

# Отправка бэкапа в телеграм
curl -F "chat_id=$CHAT_ID" -F document=@"$FILE_PATH" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"

echo "Резервная копия отправлена в Telegram."

RECIPIENT="recepient@gmail.com"
MAIL_SUBJECT="Today Backup"
BODY="Please find the attached file."


mutt -s "Today Backup" -i "$BODY" -a "$FILE_PATH" "$RECIPIENT"

echo "Резервная копия отправлена на почту $RECIPIENT."