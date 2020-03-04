#!/bin/sh
# Configures the Vault server for a database secrets demo

echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -y update > /dev/null 2>&1
sudo apt-get -y upgrade > /dev/null 2>&1
sudo apt-get install -y unzip jq python3 python3-pip > /dev/null 2>&1
pip3 install awscli

sudo bash -c "cat >/root/s1_vault_login.sh" <<EOT
#!/bin/bash

# Get instance signature
pkcs7=\$(curl -s \\
  "http://169.254.169.254/latest/dynamic/instance-identity/pkcs7" | tr -d '\n')

# Create data payload
data=\$(cat <<EOF
{
  "role": "app-db-role",
  "pkcs7": "\$pkcs7"
}
EOF
)

# Login and retrieve client token
curl --request POST \\
  --data "\$data" \\
  "http://${VAULT_IP}:8200/v1/auth/aws/login" | jq . > auth.txt

export CLIENT_TOKEN="\$(cat auth.txt | jq -r .auth.client_token | tr -d '\n')"

echo \$CLIENT_TOKEN
EOT
chmod a+x /root/s1_vault_login.sh

sudo bash -c "cat >/root/s2_get_creds.sh" <<EOT
!#/bin/bash

curl \\
    --header "X-Vault-Token: \$CLIENT_TOKEN" \\
    http://${VAULT_IP}:8200/v1/database/creds/app-role | jq 
EOT
chmod a+x /root/s2_get_creds.sh
