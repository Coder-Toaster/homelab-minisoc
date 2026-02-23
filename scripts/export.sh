#!/usr/bin/env bash
set -euo pipefail

echo "Script started!"
echo 

HOST="$(hostname -s)" # Get hostname
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # Get dir path
MANIFEST="$REPO_ROOT/manifests/router-files.txt" #Get file's path

CONF_DIR="$REPO_ROOT/configs/$HOST" # Get conf dir path
STATE_DIR="$REPO_ROOT/state/$HOST" # Get state dir path

mkdir -p "$CONF_DIR" "$STATE_DIR" # Create conf and state paths if does not exists

# Report to terminal
echo "== Exporting configs to: $CONF_DIR"
echo "== Exporting state   to: $STATE_DIR"
echo "== Manifest          : $MANIFEST"
echo

### --- 1 --- Export config files (whitelisted)
while IFS= read -r p; do
  # trim leading/trailing whitespace
  p="${p#"${p%%[![:space:]]*}"}" # Del whitespace from start 
  p="${p%"${p##*[![:space:]]}"}" # Del whitespace from end

  [[ -z "$p" || "$p" =~ ^# ]] && continue

  if [[ -e "$p" ]]; then
    echo "[CONF] $p"
    sudo rsync -a --relative "$p" "$CONF_DIR/"
  else
    echo "[SKIP] $p (missing)"
  fi
done < "$MANIFEST"

echo


### --- 2 --- Sanitize common secrets 
# When WireGuard is added. This prevents private keys from leaking.
if compgen -G "$CONF_DIR/etc/wireguard/*.conf" > /dev/null; then
  echo "[SANITIZE] WireGuard PrivateKey -> REDACTED"
  sudo sed -i 's/^PrivateKey\s*=.*/PrivateKey = REDACTED/' "$CONF_DIR"/etc/wireguard/*.conf || true
fi

echo


### --- 3 --- Export debug snapshots
echo "[STATE] nft list ruleset"
sudo nft list ruleset > "$STATE_DIR/nft-ruleset.txt"

echo "[STATE] interfaces and addresses"
ip -brief address > "$STATE_DIR/ip-brief-address.txt"

echo "[STATE] routing tables"
ip route > "$STATE_DIR/ip-route-v4.txt"
ip -6 route > "$STATE_DIR/ip-route-v6.txt" || true

echo "[STATE] forwarding flag"
sysctl net.ipv4.ip_forward > "$STATE_DIR/sysctl-ip_forward.txt"

echo "[STATE] listening sockets"
ss -tulpen > "$STATE_DIR/ss-tulpen.txt"

echo
echo "== Export complete."
