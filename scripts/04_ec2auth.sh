# ec2 auth

CURRENT_DIRECTORY="04_ec2auth"
# enable ec2 auth
sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_interactive.sh" <<EOT
clear
cat <<DESCRIPTION
We're going to configure Vault to integrate with 
AWS using EC2 metadata for authentication. In this config, 
we're going to authenticate using the AMI ID.

vault auth enable aws

vault policy write "db-policy" -<<EOF
path "database/creds/app-role" {
    capabilities = ["list", "read"]
}
EOF

vault write \\\\
    auth/aws/role/app-db-role \\\\
    auth_type=iam \\\\
    policies=db-policy \\\\
    max_ttl=1h \\\\
    bound_iam_principal_arn=${ROLE_ARN}

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault auth enable aws > /dev/null

vault policy write "db-policy" > /dev/null -<<EOF
path "database/creds/app-role" {
    capabilities = ["list", "read"]
}
EOF

vault write \\
    auth/aws/role/app-db-role \\
    auth_type=iam \\
    policies=db-policy \\
    max_ttl=1h \\
    bound_iam_principal_arn=${ROLE_ARN} > /dev/null
EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_interactive.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_auto.sh" <<EOT
echo "Configuring AWS Authentication..."

vault auth enable aws > /dev/null

vault policy write "db-policy" > /dev/null -<<EOF
path "database/creds/app-role" {
    capabilities = ["list", "read"]
}
EOF

vault write \\
    auth/aws/role/app-db-role \\
    auth_type=iam \\
    policies=db-policy \\
    max_ttl=1h \\
    bound_iam_principal_arn=${ROLE_ARN} > /dev/null

echo "Done."
EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_auto.sh
