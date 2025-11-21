#!/bin/bash

# ... other script content before line 43

# Corrected read command to avoid stdin consumption
read -p "📦 Voulez-vous installer PowerShell Core automatiquement ? (O/n): " response < /dev/tty

# ... other script content in between

# Corrected read command to avoid stdin consumption
read -p "Voulez-vous installer dans /usr/local/bin avec sudo ? [O/n] " -n 1 -r < /dev/tty

# ... other script content after line 260