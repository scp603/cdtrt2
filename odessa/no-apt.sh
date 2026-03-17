#!/usr/bin/env bash
# Usage: sudo ./no-apt.sh install | remove | status

cmd_install() {
    if [[ ! -f /etc/apt/sources.list ]]; then
        echo "[!] already deployed — skipping"
        exit 0
    fi
    mv /etc/apt/sources.list /etc/apt/sources.lists
    [[ -d /etc/apt/sources.list.d ]] && mv /etc/apt/sources.list.d/ /etc/apt/sources.lists.d/
    echo "[+] apt broken"
}

cmd_remove() {
    [[ -f /etc/apt/sources.lists ]] && mv /etc/apt/sources.lists /etc/apt/sources.list
    [[ -d /etc/apt/sources.lists.d ]] && mv /etc/apt/sources.lists.d/ /etc/apt/sources.list.d/
    echo "[+] apt restored"
}

cmd_status() {
    [[ -f /etc/apt/sources.list ]] && echo "[+] apt OK" || echo "[-] apt broken (sources.list missing)"
}

case "${1:-install}" in
    install) cmd_install ;;
    remove)  cmd_remove  ;;
    status)  cmd_status  ;;
esac
