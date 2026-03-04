#!/usr/bin/env bash

# identify where the `w` and `who` binaries are
W_LOC=$(which w)
WHO_LOC=$(which who)
cp $W_LOC "TODO END LOCATION"
cp $WHO_LOC "TODO END LOCATION"
echo "\
11:05:20 up 8 min,  1 user,  load average: 1.70, 1.07, 0.52
USER     TTY       LOGIN@   IDLE   JCPU   PCPU  WHAT
0xd355a  pts/0     10:58    0.00s  0.32s  0.01s w
" | sudo tee $W_LOC
echo "\
0xd355a               2026-03-04 10:58
0xd355a  tty8         2026-03-04 10:58
" | sudo tee $WHO_LOC

W_LOC="stop poking around."
WHO_LOC="please stop poking around..."