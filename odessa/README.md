# Tooling descriptions

## Map
```
├── compromise-w-who.sh
├── evil-timer
│   ├── deploy-evil-timer.sh
│   ├── python2-certbot.service
│   └── python2-certbot.timer
├── infinite-users.sh
├── README.md
└── vandalize-bashrc.sh
```

## Desc
| tool name | functionality |
| --- | --- |
| compromise-w-who.sh | Moves the `w` and `who` binaries to the `/run/runit/` directory and adds a `.so` to the end for a bit more hiding, then makes a fake `who` entry and a bait `w` entry |
| evil-timer | i dunno |
| infinite-users.sh | nologin is now is symlinked in bash, meaning we can login as any user on the system with `nologin` as its shell, it will also get root perms i just need to figure that out |
| vandalize-bashrc.sh | searches the machine for .bashrc files and adds a big `:3` to them |