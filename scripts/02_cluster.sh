#!/bin/bash

CURRENT_DIRECTORY="02_cluster"
# Auto unseal
sudo bash -c "cat >/root/$CURRENT_DIRECTORY/s1_configure.sh" <<EOT
if [ $NODE_INDEX -eq 1 ]; then
    exit 1
fi

echo "Join cluster..."

# vault operator raft join http://node1:8200

echo "Done."
EOT
chmod a+x /root/$CURRENT_DIRECTORY/s1_configure.sh
