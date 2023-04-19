#!/bin/bash


FILE_PATH="/var/log/suid_sgid.txt"
if [ ! -f "$FILE_PATH" ]
then touch "$FILE_PATH"
fi
#2>/dev/null
find / -mount -xdev -type f '(' -perm -4000 -o -perm -2000 ')' > "/tmp/suid_sgid.txt"
if cmp -s "/tmp/suid_sgid.txt" "$FILE_PATH"; then
echo "Il n'y a pas de changement"
else
echo "Nouveaux fichiers SUID/SGID"
diff "/tmp/suid_sgid.txt" "$FILE_PATH" > "/tmp/diff.txt"
cat "/tmp/diff.txt"
cp "/tmp/suid_sgid.txt" "$FILE_PATH"
fi

rm "/tmp/suid_sgid.txt"