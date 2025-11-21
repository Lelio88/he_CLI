#!/bin/bash

# Original script with modifications
...

# Modification on line 43
read -p "📦 Voulez-vous installer PowerShell Core automatiquement ? (O/n): " response < /dev/tty
...

# Modification on line 260
read -p "Voulez-vous installer dans /usr/local/bin avec sudo ? [O/n] " -n 1 -r < /dev/tty
...