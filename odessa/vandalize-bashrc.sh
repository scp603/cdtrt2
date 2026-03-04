#!/usr/bin/env bash
whiteteam_user=""

find / -name ".bashrc" 2>/dev/null | while read -r bashrc; do
    [[ -n "$whiteteam_user" && "$bashrc" == *"$whiteteam_user"* ]] && continue
    echo '
echo '"'"'
    ____
  _|___ \
 (_) __) |
    |__ <
  _ ___) |
 (_)____/
'"'"'' >> "$bashrc"
done
