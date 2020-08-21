#!/bin/bash

# Dynamic creds
sudo bash -c "cat >/root/02_database/s1_setup_db.sh" <<EOT
clear
cat <<DESCRIPTION
Let's enable dynamic database secrets and create a role. First, 
We'll configure the secrets engine, then we'll create a role 
with a CREATE USER / GRANT statement.

vault secrets enable database

vault write database/config/sedemovaultdb \\\\
    plugin_name="mysql-database-plugin" \\\\
    connection_url="{{username}}:{{password}}@tcp(${MYSQL_HOST})/" \\\\
    allowed_roles="app-role" \\\\
    username="XXXXXXXX" \\\\
    password="XXXXXXXX"

vault write database/roles/app-role \\\\
    db_name=sedemovaultdb \\\\
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \\\\
    default_ttl="1h" \\\\
    max_ttl="24h"

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault secrets enable database > /dev/null

vault write database/config/sedemovaultdb \\
    plugin_name="mysql-database-plugin" \\
    connection_url="{{username}}:{{password}}@tcp(${MYSQL_HOST})/" \\
    allowed_roles="app-role" \\
    username="${MYSQL_USER}" \\
    password="${MYSQL_PASS}" > /dev/null

vault write database/roles/app-role \\
    db_name=sedemovaultdb \\
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \\
    default_ttl="1h" \\
    max_ttl="24h" > /dev/null

echo "Configuration complete!"
EOT
chmod a+x /root/02_database/s1_setup_db.sh

sudo bash -c "cat >/root/02_database/operators.hcl" <<EOT
path "database/roles/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}

path "database/creds/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}

path "secret/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}
EOT

sudo bash -c "cat >/root/02_database/appdevs.hcl" <<EOT
path "secret/*" {
    capabilities = ["read", "list"]
}
EOT

sudo bash -c "cat >/root/02_database/s2_policies.sh" <<EOT
clear
cat <<DESCRIPTION
Next, we're going to create a couple of policies.

OPERATORS:
path "database/roles/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}

path "database/creds/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}

path "secret/*" {
    capabilities = ["read", "list", "create", "delete", "update"]
}

APPDEVS:
path "secret/*" {
    capabilities = ["read", "list"]
}

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault policy write operators /root/02_database/operators.hcl > /dev/null
vault policy write appdevs /root/02_database/appdevs.hcl > /dev/null
echo "Policies added!"
EOT
chmod a+x /root/02_database/s2_policies.sh

sudo bash -c "cat >/root/02_database/s3_users.sh" <<EOT
clear
cat <<DESCRIPTION
In order to take advantage of those policies, we'll create 
a couple of users and assign the new policies to them.

vault auth enable userpass

vault write auth/userpass/users/james \\\\
    password="superpass" \\\\
    policies="operators"

vault write auth/userpass/users/sally \\\\
    password="superpass" \\\\
    policies="appdevs"

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault auth enable userpass > /dev/null
vault write auth/userpass/users/james \\
    password="superpass" \\
    policies="operators" > /dev/null

vault write auth/userpass/users/sally \\
    password="superpass" \\
    policies="appdevs" > /dev/null

echo "Users added!"
EOT
chmod a+x /root/02_database/s3_users.sh

sudo bash -c "cat >/root/02_database/s4_james_login.sh" <<EOT
clear
cat <<DESCRIPTION
Let's login as James and see what privileges he has.

vault login --method=userpass username=james

Press any key to continue...
DESCRIPTION

read -n1 kbd

export OLD_VAULT_TOKEN=$VAULT_TOKEN
unset VAULT_TOKEN

vault login --method=userpass username=james

vault read database/creds/app-role

export VAULT_TOKEN=$OLD_VAULT_TOKEN
unset OLD_VAULT_TOKEN
EOT
chmod a+x /root/02_database/s4_james_login.sh

sudo bash -c "cat >/root/02_database/s5_sally_login.sh" <<EOT
clear
cat <<DESCRIPTION
Now let's login see if Sally has the same privileges.

vault login --method=userpass username=sally

Press any key to continue...
DESCRIPTION

read -n1 kbd

export OLD_VAULT_TOKEN=$VAULT_TOKEN
unset VAULT_TOKEN

vault login --method=userpass username=sally

vault read database/creds/app-role

export VAULT_TOKEN=$OLD_VAULT_TOKEN
unset OLD_VAULT_TOKEN
EOT
chmod a+x /root/02_database/s5_sally_login.sh
