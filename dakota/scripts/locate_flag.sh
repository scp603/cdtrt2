#!/bin/bash
# Recursively searches the entire filesystem for the flag pattern
# -r: recursive
# -n: show line numbers
# -E: use extended regex
# 2>/dev/null: silences 'Permission denied' errors for a cleaner terminal

grep -rnE "flag\{.*\}" / 2>/dev/null