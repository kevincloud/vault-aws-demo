#!/bin/bash

CURRENT_DIRECTORY="01_database"
# Dynamic creds

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/operators.hcl" <<EOT
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

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/appdevs.hcl" <<EOT
path "secret/*" {
    capabilities = ["read", "list"]
}
EOT

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_interactive.sh" <<EOT
clear
cat <<DESCRIPTION
Let's enable dynamic database secrets and create a role. First, 
We'll configure the secrets engine, then we'll create a role 
with a CREATE USER / GRANT statement.

vault secrets enable database

vault write database/config/$MYSQL_DBNAME \\\\
    plugin_name="mysql-database-plugin" \\\\
    connection_url="{{username}}:{{password}}@tcp(mysqldb.example.com:3306)/" \\\\
    allowed_roles="app-role" \\\\
    username="XXXXXXXX" \\\\
    password="XXXXXXXX"

vault write database/roles/app-role \\\\
    db_name=$MYSQL_DBNAME \\\\
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \\\\
    default_ttl="1h" \\\\
    max_ttl="24h"

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault secrets enable database > /dev/null

vault write database/config/$MYSQL_DBNAME \\
    plugin_name="mysql-database-plugin" \\
    connection_url="{{username}}:{{password}}@tcp(${MYSQL_HOST})/" \\
    allowed_roles="app-role" \\
    username="${DB_USER}" \\
    password="${DB_PASS}" > /dev/null

vault write database/roles/app-role \\
    db_name=$MYSQL_DBNAME \\
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \\
    default_ttl="1h" \\
    max_ttl="24h" > /dev/null

echo "Configuration complete!"

read -n1 kbd

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

vault policy write operators /root/$CURRENT_DIRECTORY/operators.hcl > /dev/null
vault policy write appdevs /root/$CURRENT_DIRECTORY/appdevs.hcl > /dev/null

echo "Policies added!"

read -n1 kbd

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

read -n1 kbd

clear
cat <<DESCRIPTION
Let's login as James and see what privileges he has.

vault login --method=userpass username=james

(password is "superpass")

Press any key to continue...
DESCRIPTION

read -n1 kbd

export OLD_VAULT_TOKEN=\$VAULT_TOKEN
unset VAULT_TOKEN

vault login --method=userpass username=james

vault read database/creds/app-role

export VAULT_TOKEN=\$OLD_VAULT_TOKEN
unset OLD_VAULT_TOKEN

read -n1 kbd

clear
cat <<DESCRIPTION
Now let's login see if Sally has the same privileges.

vault login --method=userpass username=sally

(password is "superpass")

Press any key to continue...
DESCRIPTION

read -n1 kbd

export OLD_VAULT_TOKEN=\$VAULT_TOKEN
unset VAULT_TOKEN

vault login --method=userpass username=sally

vault read database/creds/app-role

export VAULT_TOKEN=\$OLD_VAULT_TOKEN
unset OLD_VAULT_TOKEN

echo "Press any key to continue..."
read -n1 kbd
EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_interactive.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_auto.sh" <<EOT
echo "Configuring Dynamic Database Secrets..."

vault secrets enable database > /dev/null

vault write database/config/$MYSQL_DBNAME \\
    plugin_name="mysql-database-plugin" \\
    connection_url="{{username}}:{{password}}@tcp(${MYSQL_HOST})/" \\
    allowed_roles="app-role" \\
    username="${DB_USER}" \\
    password="${DB_PASS}" > /dev/null

vault write database/roles/app-role \\
    db_name=$MYSQL_DBNAME \\
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \\
    default_ttl="1h" \\
    max_ttl="24h" > /dev/null

vault policy write operators /root/$CURRENT_DIRECTORY/operators.hcl > /dev/null
vault policy write appdevs /root/$CURRENT_DIRECTORY/appdevs.hcl > /dev/null

vault auth enable userpass > /dev/null
vault write auth/userpass/users/james \\
    password="superpass" \\
    policies="operators" > /dev/null

vault write auth/userpass/users/sally \\
    password="superpass" \\
    policies="appdevs" > /dev/null

echo "Done."
EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_auto.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/reset.sh" <<EOT
vault auth disable userpass > /dev/null
vault policy delete appdevs > /dev/null
vault policy delete operators > /dev/null
vault secrets disable database > /dev/null
EOT
chmod a+x /root/$CURRENT_DIRECTORY/reset.sh
