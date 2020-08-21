#!/bin/bash

# pki + consul-template
curl -sfLo "consul-template.zip" "${CTPL_URL}"
sudo unzip consul-template.zip -d /usr/local/bin/
rm consul-template.zip

sudo bash -c "cat >/etc/vault.d/ct-config.hcl" <<EOT
vault {
  address = "http://localhost:8200"
  token = "$VAULT_TOKEN"
  renew_token = false
}

syslog {
    enabled = true
    facility = "LOCAL5"
}

template {
    contents="{{ with secret \"example_com_pki/issue/web-certs\" \"common_name=www.example.com\" }}{{ .Data.certificate }}{{ end }}"
    destination="/root/pki/www.example.com.crt"
    perms = 0400
    # command = "service nginx restart"
}
EOT

echo "Installing systemd service for Consul Template..."
sudo bash -c "cat >/etc/systemd/system/consul-template.service" <<EOT
[Unit]
Description=Hashicorp Consul Template
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecStart=/usr/local/bin/consul-template -config=/etc/vault.d/ct-config.hcl -pid-file=/var/run/vault/consul-template.pid
SuccessExitStatus=12
ExecReload=/bin/kill -SIGHUP \$MAINPID
ExecStop=/bin/kill -SIGINT \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=always
RestartSec=42s
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl enable consul-template

sudo bash -c "cat >/root/05_pki/s1_enable_pki.sh" <<EOT
clear
cat <<DESCRIPTION
We're going to enable a pki engine to for auto-rolling 
certificates. First we enable the engine, then we'll 
create our root cert for example.com

vault secrets enable -path=example_com_pki pki

vault write -field=certificate \\\\
    example_com_pki/root/generate/internal \\\\
    common_name=example.com > /root/05_pki/ca_cert.crt

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault secrets enable -path=example_com_pki pki > /dev/null

vault write -field=certificate \\
    example_com_pki/root/generate/internal \\
    common_name=example.com > /root/05_pki/ca_cert.crt > /dev/null
EOT
chmod a+x /root/05_pki/s1_enable_pki.sh

sudo bash -c "cat >/root/05_pki/s2_create_role.sh" <<EOT
clear
cat <<DESCRIPTION
Next, we'll create a role which sets the lease times 
and other attributes for certificate generation and 
signing.

vault write example_com_pki/roles/web-certs \\\\
    allowed_domains=example.com \\\\
    allow_subdomains=true \\\\
    ttl=5s \\\\
    max_ttl=30m \\\\
    generate_lease=true

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault write example_com_pki/roles/web-certs \\
    allowed_domains=example.com \\
    allow_subdomains=true \\
    ttl=5s \\
    max_ttl=30m \\
    generate_lease=true > /dev/null
EOT
chmod a+x /root/05_pki/s2_create_role.sh

sudo bash -c "cat >/root/05_pki/s3_create_cert.sh" <<EOT
clear
cat <<DESCRIPTION
Now we can create our first certificate. We'll do this using 
Vault's HTTP API.

curl -s \\\\
    --request POST \\\\
    --header "X-Vault-Token: $VAULT_TOKEN" \\\\
    --data '{"common_name": "www.example.com" }' \\\\
    http://localhost:8200/v1/example_com_pki/issue/web-certs | jq -r .data.certificate > www.example.com.crt

Press any key to continue...
DESCRIPTION

read -n1 kbd

# vault write example_com_pki/issue/web-certs \\
#     common_name=www.example.com

curl -s \\
    --request POST \\
    --header "X-Vault-Token: $VAULT_TOKEN" \\
    --data '{"common_name": "www.example.com" }' \\
    http://localhost:8200/v1/example_com_pki/issue/web-certs | jq -r .data.certificate > www.example.com.crt

EOT
chmod a+x /root/05_pki/s3_create_cert.sh

sudo bash -c "cat >/root/05_pki/s4_autoroll_cert.sh" <<EOT
clear
cat <<DESCRIPTION
On the client server, we'll use the Vault agent to monitor 
certificate management. Vault agent will need to run as a 
service.

service vault start

Press any key to continue...
DESCRIPTION

read -n1 kbd

service consul-template start
EOT
chmod a+x /root/05_pki/s4_autoroll_cert.sh

sudo bash -c "cat >/root/05_pki/s5_monitor.sh" <<EOT
#!/bin/bash

while [ 1 ]; do
    clear
    cat /root/05_pki/www.example.com.crt
    sleep 1
done
EOT
chmod a+x /root/05_pki/s5_monitor.sh

