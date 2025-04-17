#!/bin/bash

# To save disk usage, Disable cache for pip package downloading
ALIAS_LINE="alias pip='pip --no-cache-dir'"
PROFILE_FILE="$HOME/.bash_profile"

# Create file if it doesn't exist
touch "$PROFILE_FILE"

# Append alias only if it doesn't already exist
grep -Fxq "$ALIAS_LINE" "$PROFILE_FILE" || echo "$ALIAS_LINE" >> "$PROFILE_FILE"
