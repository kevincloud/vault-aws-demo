# ec2 auth

sudo bash -c "cat >/root/03_ec2auth/s1_setup_auth.sh" <<EOT
clear
cat <<DESCRIPTION
We're going to configure Vault to integrate with 
AWS using EC2 metadata for authentication. In this config, 
we're going to authenticate using the AMI ID.

vault auth enable aws

vault write auth/aws/config/client \\\\
    secret_key=XXXXXXXXXX \\\\
    access_key=XXXXXX

vault policy write "db-policy" -<<EOF
path "database/creds/app-role" {
    capabilities = ["list", "read"]
}
EOF

vault write \\\\
    auth/aws/role/app-db-role \\\\
    auth_type=ec2 \\\\
    policies=db-policy \\\\
    max_ttl=1h \\\\
    disallow_reauthentication=false \\\\
    bound_ami_id=${AMI_ID}

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault auth enable aws > /dev/null

vault write auth/aws/config/client \\
    secret_key=${AWS_SECRET_KEY} \\
    access_key=${AWS_ACCESS_KEY} > /dev/null

vault policy write "db-policy" > /dev/null -<<EOF
path "database/creds/app-role" {
    capabilities = ["list", "read"]
}
EOF

vault write \\
    auth/aws/role/app-db-role \\
    auth_type=ec2 \\
    policies=db-policy \\
    max_ttl=1h \\
    disallow_reauthentication=false \\
    bound_ami_id=${AMI_ID} > /dev/null
EOT
chmod a+x /root/03_ec2auth/s1_setup_auth.sh
