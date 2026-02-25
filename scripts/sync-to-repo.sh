#!/usr/bin/env bash
set -euo pipefail

# Git-reposiroty path
REPO_DIR="/home/socadmin/netlab"
DEST_SUBDIR="hosts/soc-firewallRouter"

# FIles to be copied
FILES=(
  "/etc/nftables.conf"
  "/etc/kea/kea-dhcp4.conf"
  "/etc/netplan/01-router.yaml"
)

# With what permissions is the file copied to repo
# 0644
# 0600 
MODE="0600"

# Check whom owns the files 
OWNER="${SUDO_USER:-$USER}"
GROUP="$(id -gn "$OWNER")"

DEST_DIR="$REPO_DIR/$DEST_SUBDIR"

# Make sure to be in git repo
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "[ERR] $REPO_DIR ei ole git-repo (puuttuu .git)."
  exit 1
fi

# Create dir dest and set ownership + permissions
install -d -o "$OWNER" -g "$GROUP" -m 0755 "$DEST_DIR"

for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    out="$DEST_DIR/$(basename "$f")"
    echo "[OK] copying: $f -> $out (owner=$OWNER mode=$MODE)"
    # install copu and set owenserhsip and permissions at one time
    install -o "$OWNER" -g "$GROUP" -m "$MODE" "$f" "$out"
  else
    echo "[WARN] not found (skip): $f"
  fi
done

echo
echo "[NEXT]"
echo "  cd \"$REPO_DIR\""
echo "  git status"
echo "  git diff"
