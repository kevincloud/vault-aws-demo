#!/bin/sh
# Configures the Vault server for a database secrets demo

echo "Preparing to install Vault..."
echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -y update > /dev/null 2>&1
sudo apt-get -y upgrade > /dev/null 2>&1
sudo apt-get install -y unzip jq cowsay mysql-client > /dev/null 2>&1
sudo apt-get install -y python3 python3-pip
pip3 install awscli Flask mysql-connector-python hvac

mkdir /etc/vault.d
mkdir -p /opt/vault
mkdir -p /root/.aws
mkdir -p /var/run/vault
mkdir -p /var/raft${NODE_INDEX}

export CLIENT_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
export PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

sudo bash -c "cat >/root/.aws/config" <<EOT
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
aws_session_token=${AWS_SESSION_TOKEN}
EOT
sudo bash -c "cat >/root/.aws/credentials" <<EOT
[default]
aws_access_key_id=${AWS_ACCESS_KEY}
aws_secret_access_key=${AWS_SECRET_KEY}
aws_session_token=${AWS_SESSION_TOKEN}
EOT

echo "Update hosts file..."
COUNT=1
while [ $COUNT -le $NUM_NODES ]; do
    sed -i '1s/^/10.0.10.2'$COUNT' node'$COUNT'\n/' /etc/hosts
    COUNT=$(($COUNT+1))
done

echo "Installing Vault..."
curl -sfLo "vault.zip" "${VAULT_URL}"
sudo unzip vault.zip -d /usr/local/bin/

sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

sudo tee -a /etc/environment <<EOF
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true
EOF

source /etc/environment

RETRY_JOIN=""
if [ ${NODE_INDEX} -ne 1 ]; then
    RETRY_JOIN=$'\n'"  retry_join {"$'\n'"    leader_api_addr = ""http://10.0.10.21:8200"""$'\n'"  }"$'\n'
fi

# Server configuration
sudo bash -c "cat >/etc/vault.d/vault.hcl" <<EOT
storage "raft" {
  path = "/var/raft${NODE_INDEX}"
  node_id = "node${NODE_INDEX}"
  $RETRY_JOIN
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = true
}

seal "awskms" {
    region = "${AWS_REGION}"
    kms_key_id = "${AWS_KMS_KEY_ID}"
}

cluster_addr = "http://$CLIENT_IP:8201"
api_addr = "http://$PUBLIC_IP:8200"
disable_mlock = true
ui = true
EOT

# Set Vault up as a systemd service
echo "Installing systemd service for Vault..."
sudo bash -c "cat >/etc/systemd/system/vault.service" <<EOT
[Unit]
Description=HashiCorp Vault
Requires=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
PIDFile=/var/run/vault/vault.pid
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl -log-level=debug -tls-skip-verify
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=42s
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl start vault
sudo systemctl enable vault

sleep 10

if [ ${NODE_INDEX} -ne 1 ]; then
    echo "Node configuration complete."
    exit 1
fi

echo "Initializing Vault..."
export VAULT_IP=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -recovery-shares=1 -recovery-threshold=1 > /root/init.txt 2>&1
export VAULT_TOKEN=`cat /root/init.txt | sed -n -e '/^Initial Root Token/ s/.*\: *//p'`
export DB_HOST=`echo '${MYSQL_HOST}' | awk -F ":" '/1/ {print $1}'`

export NODE_INDEX=${NODE_INDEX}
export NUM_NODES=${NUM_NODES}
export AWS_ACCESS_KEY=${AWS_ACCESS_KEY}
export AWS_SECRET_KEY=${AWS_SECRET_KEY}
export AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
export AMI_ID=${AMI_ID}
export AWS_REGION=${AWS_REGION}
export MYSQL_HOST=${MYSQL_HOST}
export MYSQL_USER=${MYSQL_USER}
export MYSQL_PASS=${MYSQL_PASS}
export AWS_KMS_KEY_ID=${AWS_KMS_KEY_ID}
export VAULT_URL=${VAULT_URL}
export VAULT_LICENSE=${VAULT_LICENSE}
export CTPL_URL=${CTPL_URL}

sleep 20

# Setup demos
echo "Setup demos..."
# UNSEAL_KEY_1=`cat /root/init.txt | sed -n -e '/^Unseal Key 1/ s/.*\: *//p'`
# UNSEAL_KEY_2=`cat /root/init.txt | sed -n -e '/^Unseal Key 2/ s/.*\: *//p'`
# UNSEAL_KEY_3=`cat /root/init.txt | sed -n -e '/^Unseal Key 3/ s/.*\: *//p'`
# mkdir /root/01_unseal
# mkdir /root/02_cluster
mkdir /root/03_database
mkdir /root/04_ec2auth
mkdir /root/05_eaas
mkdir /root/06_pki

cd /root
git clone --single-branch --branch ${GIT_BRANCH} https://github.com/kevincloud/vault-aws-demo.git

# . /root/vault-aws-demo/scripts/01_unseal.sh
# . /root/vault-aws-demo/scripts/02_cluster.sh
. /root/vault-aws-demo/scripts/03_database.sh
. /root/vault-aws-demo/scripts/04_ec2auth.sh
. /root/vault-aws-demo/scripts/05_eaas.sh
. /root/vault-aws-demo/scripts/06_pki.sh

echo "Setting up environment variables..."
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /home/ubuntu/.profile
echo "export VAULT_TOKEN=$VAULT_TOKEN" >> /home/ubuntu/.profile
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /root/.profile
echo "export VAULT_TOKEN=$VAULT_TOKEN" >> /root/.profile

# echo "Unsealing Vault..."
# vault operator unseal $UNSEAL_KEY_1
# vault operator unseal $UNSEAL_KEY_2
# vault operator unseal $UNSEAL_KEY_3

echo "Wait for cluster to come online..."
CLUSTER_STATUS=`vault status | grep 'HA Cluster' | sed -rn 's/HA Cluster[ ]*(.*)/\1/p'`
while [ "$CLUSTER_STATUS" = "n/a" ]; do
    sleep 2
    CLUSTER_STATUS=`vault status | grep 'HA Cluster' | sed -rn 's/HA Cluster[ ]*(.*)/\1/p'`
done

sleep 10

echo ""
vault status
echo ""

# vault login $VAULT_TOKEN
echo "Enable KV2 secrets engine..."
vault secrets enable -path="secret" -version=2 kv

echo "Enable audit logging..."
vault audit enable file file_path=/var/log/vault_audit.log

if [ ${NODE_INDEX} -eq 1 ]; then
    echo "Licensing Vault..."
    vault write sys/license text=${VAULT_LICENSE}
fi

# sudo bash -c "cat >/root/unseal" <<EOT
# vault operator unseal $UNSEAL_KEY_1 > /dev/null
# vault operator unseal $UNSEAL_KEY_2 > /dev/null
# vault operator unseal $UNSEAL_KEY_3 > /dev/null
# EOT
# chmod +x /root/unseal

sudo bash -c "cat >/root/runall.sh" <<EOT
echo "Configuring Complete Vault..."
# . /root/01_unseal/runall.sh
# . /root/02_cluster/runall.sh
. /root/03_database/runall.sh
. /root/04_ec2auth/runall.sh
. /root/05_eaas/runall.sh
. /root/06_pki/runall.sh
EOT
chmod a+x /root/runall.sh

# Add our AWS secrets
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "aws_access_key": "${AWS_ACCESS_KEY}", "aws_secret_key": "${AWS_SECRET_KEY}" } }' \
    http://127.0.0.1:8200/v1/secret/data/aws

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "vault_user", "password": "Super$ecret1" } }' \
    http://127.0.0.1:8200/v1/secret/data/creds

if [ "${AUTO_UNSEAL}" = "on" ]; then
    /root/01_unseal/runall.sh
fi

echo "Vault installation complete."
