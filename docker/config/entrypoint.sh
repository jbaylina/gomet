#!/bin/sh

echo "Copying......"
mkdir -p /root/.local/share/io.parity.ethereum/keys/gomet
cp /root/config/keys/* /root/.local/share/io.parity.ethereum/keys/gomet

mkdir -p /root/.local/share/io.parity.ethereum/network
echo /root/config/netkeys/key$NODEID
cp /root/config/netkeys/key$NODEID /root/.local/share/io.parity.ethereum/network/key

# Hand off to the CMD
exec "$@"
