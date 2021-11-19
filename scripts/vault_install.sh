#!/bin/sh
# Configures the Vault server for a database secrets demo

echo "Preparing to install Vault..."
echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

export DEBIAN_FRONTEND=noninteractive
sudo apt-get -y update > /dev/null 2>&1
# sudo apt-get -y upgrade > /dev/null 2>&1
sudo apt-get install -y unzip jq cowsay mysql-client postgresql-client-13 > /dev/null 2>&1
sudo apt-get install -y python3 python3-pip
pip3 install awscli Flask mysql-connector-python hvac

mkdir /etc/vault.d
mkdir -p /opt/vault
mkdir -p /root/.aws
mkdir -p /var/run/vault
mkdir -p /var/raft${NODE_INDEX}

export CLIENT_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
export PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

echo "Update hosts file..."
COUNT=1
while [ $COUNT -le ${NUM_NODES} ]; do
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

. /etc/environment

# Server configuration
sudo bash -c "cat >/etc/vault.d/vault.hcl" <<EOT
storage "raft" {
  path = "/var/raft${NODE_INDEX}"
  node_id = "node${NODE_INDEX}"
  retry_join {
     auto_join = "provider=aws addr_type=public_v4 region=${AWS_REGION} tag_key=${AUTOJOIN_KEY} tag_value=${AUTOJOIN_VALUE}"
     auto_join_scheme = "http"
  }
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
export TOKEN_DB_HOST=`echo '${POSTGRES_HOST}' | awk -F ":" '/1/ {print $1}'`

echo "Setting up environment variables..."
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /home/ubuntu/.profile
echo "export VAULT_TOKEN=$VAULT_TOKEN" >> /home/ubuntu/.profile
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /root/.profile
echo "export VAULT_TOKEN=$VAULT_TOKEN" >> /root/.profile

export NODE_INDEX=${NODE_INDEX}
export NUM_NODES=${NUM_NODES}
export AMI_ID=${AMI_ID}
export AWS_REGION=${AWS_REGION}
export MYSQL_HOST=${MYSQL_HOST}
export MYSQL_DBNAME=${MYSQL_DBNAME}
export POSTGRES_HOST=${POSTGRES_HOST}
export POSTGRES_DBNAME=${POSTGRES_DBNAME}
export DB_USER=${DB_USER}
export DB_PASS=${DB_PASS}
export AWS_KMS_KEY_ID=${AWS_KMS_KEY_ID}
export VAULT_URL=${VAULT_URL}
export VAULT_LICENSE=${VAULT_LICENSE}
export CTPL_URL=${CTPL_URL}
export ROLE_ARN=${ROLE_ARN}

sleep 20

IS_LEADER=$(curl -s http://127.0.0.1:8200/v1/sys/leader | jq -r .is_self)

if [ "$IS_LEADER" = "true" ]; then
    # Setup demos
    echo "Setup demos..."
    mkdir /root/01_database
    mkdir /root/02_ec2auth
    mkdir /root/03_eaas
    mkdir /root/04_pki
    mkdir /root/05_tokenization
    mkdir /root/06_fpe

    cd /root
    git clone --single-branch --branch ${GIT_BRANCH} https://github.com/kevincloud/vault-aws-demo.git

    . /root/vault-aws-demo/scripts/01_database.sh
    . /root/vault-aws-demo/scripts/02_ec2auth.sh
    . /root/vault-aws-demo/scripts/03_eaas.sh
    . /root/vault-aws-demo/scripts/04_pki.sh
    . /root/vault-aws-demo/scripts/05_tokenization.sh
    . /root/vault-aws-demo/scripts/06_fpe.sh

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

    echo "Configuring Complete Vault..."
    sudo bash -c "cat >/root/runall.sh" <<EOT
clear
echo -e "\n\n\n\n\n\n\n\n"
echo "                    ****************************************"
echo "                    * Part 1: Dynamic Database Secrets     *"
echo "                    ****************************************"
read -n1 kbd
clear
. /root/01_database/run_interactive.sh

clear
echo -e "\n\n\n\n\n\n\n\n"
echo "                    ****************************************"
echo "                    * Part 2: AWS IAM Authentication       *"
echo "                    ****************************************"
read -n1 kbd
clear
. /root/02_ec2auth/run_interactive.sh

clear
echo -e "\n\n\n\n\n\n\n\n"
echo "                    ****************************************"
echo "                    * Part 3: Encryption as a Service      *"
echo "                    ****************************************"
read -n1 kbd
clear
. /root/03_eaas/run_interactive.sh

clear
echo -e "\n\n\n\n\n\n\n\n"
echo "                    ****************************************"
echo "                    * Part 4: Tokenization with PostgreSQL *"
echo "                    ****************************************"
read -n1 kbd
clear
. /root/05_tokenization/run_interactive.sh

clear
echo -e "\n\n\n\n\n\n\n\n"
echo "                    ****************************************"
echo "                    * Part 5: Format-Preserving Encryption *"
echo "                    ****************************************"
read -n1 kbd
clear
. /root/06_fpe/run_interactive.sh

clear
echo -e "\n\n\n\n\n\n\n\n"
echo "                    ****************************************"
echo "                    * Part 6: PKI Automated Rotation       *"
echo "                    ****************************************"
read -n1 kbd
clear
. /root/04_pki/run_interactive.sh
EOT
    chmod a+x /root/runall.sh

    sudo bash -c "cat >/root/resetall.sh" <<EOT
echo "Resetting all configurations..."
. /root/01_database/reset.sh
. /root/02_ec2auth/reset.sh
. /root/03_eaas/reset.sh
. /root/04_pki/reset.sh
. /root/05_tokenization/reset.sh
. /root/06_fpe/reset.sh
echo "Done."
EOT
    chmod a+x /root/resetall.sh

    # Add our AWS secrets
    curl \
        --header "X-Vault-Token: $VAULT_TOKEN" \
        --request POST \
        --data '{"data": { "username": "vault_user", "password": "Super$ecret1" } }' \
        http://127.0.0.1:8200/v1/secret/data/creds


    #### Uncomment the rest for integrating Jenkins
    # vault secrets enable -path="jenkins" -version=2 kv
    # vault kv put jenkins/tfdata tftoken="$/{/TF_API_TOKEN/}/"

    # vault auth enable -path="jenkinsauth-aws" aws > /dev/null

    # vault policy write "jenkins-policy" > /dev/null -<<EOF
# path "jenkins/*" {
#     capabilities = ["list", "read"]
# }
# EOF

    # vault write \
    #     auth/aws/role/jenkins-role \
    #     auth_type=iam \
    #     policies=jenkins-policy \
    #     max_ttl=7d \
    #     bound_iam_principal_arn=$/{/JENKINS_ARN/}/ > /dev/null
fi

echo "Vault installation complete."

#
