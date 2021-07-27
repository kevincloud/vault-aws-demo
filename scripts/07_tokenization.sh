#!/bin/bash

CURRENT_DIRECTORY="07_tokenization"
sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_interactive.sh" <<EOT
clear
cat <<DESCRIPTION
First we need to enable the transform engine, then
create a role which we can use for tokenizing
sensitive information

vault secrets enable transform

vault write transform/role/mobile-pay transformations=credit-card

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault secrets enable transform > /dev/null

vault write transform/role/mobile-pay transformations=credit-card > /dev/null

echo "Configuration complete!"

read -n1 kbd

clear
cat <<DESCRIPTION
Next, we need to create a connection to our
PostgreSQL instance and database, and create 
the schema vault needs to use in the database

vault write transform/stores/postgres \\\\
    type=sql \\\\
    driver=postgres \\\\
    supported_transformations=tokenization \\\\
    connection_string='postgresql://{{username}}:{{password}}@localhost/root?sslmode=disable' \\\\
    username=XXXXX \\\\
    password=XXXXX

vault write transform/stores/postgres/schema transformation_type=tokenization \\\\
    username=XXXXX password=XXXXX

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault write transform/stores/postgres \\
    type=sql \\
    driver=postgres \\
    supported_transformations=tokenization \\
    connection_string='postgresql://{{username}}:{{password}}@localhost/root?sslmode=disable' \\
    username=${DB_USER} \\
    password=${DB_PASS} > /dev/null

vault write transform/stores/postgres/schema transformation_type=tokenization \\
    username=${DB_USER} password=${DB_PASS} > /dev/null

echo "Configuration complete!"

read -n1 kbd
cat <<DESCRIPTION
Finally, we need to create the tokenization engine
for the role we created. This one will be called
credit-card.

vault write transform/transformations/tokenization/credit-card \
    allowed_roles=mobile-pay \
    max_ttl=24h \
    stores=postgres

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault write transform/transformations/tokenization/credit-card \
    allowed_roles=mobile-pay \
    max_ttl=24h \
    stores=postgres

echo "Configuration complete!"

read -n1 kbd
clear
cat <<DESCRIPTION
Now that our configuration is complete, we can 
watch tokenization in action. Let's create a token

vault write transform/encode/mobile-pay \\\\
    transformation=credit-card \\\\
    value="1234-1234-1234-1234"

psql -h postgres.example.com -d postgresdbname -U postgresuser

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault write transform/encode/mobile-pay \\
    transformation=credit-card \\
    value="1234-1234-1234-1234"

echo "select * from tokens" | PGPASSWORD=$DB_PASS psql -h $TOKEN_DB_HOST -d $POSTGRES_DBNAME -U $DB_USER
EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_interactive.sh


# # enable engine
# vault secrets enable transform

# # create role
# vault write transform/role/mobile-pay transformations=credit-card

# create external storage
# vault write transform/stores/postgres \
#     type=sql \
#     driver=postgres \
#     supported_transformations=tokenization \
#     connection_string='postgresql://{{username}}:{{password}}@localhost/root?sslmode=disable' \
#     username=root \
#     password=SuperSecret1
#     username=${DB_USER} \
#     password=${DB_PASS}

# # create schema in database
# vault write transform/stores/postgres/schema transformation_type=tokenization \
#     username=root password=SuperSecret1
#     username=${DB_USER} password=${DB_PASS}

# create tokenization engine
# vault write transform/transformations/tokenization/credit-card \
#     allowed_roles=mobile-pay \
#     max_ttl=24h \
#     stores=postgres

# psql command:
# echo "select * from tokens" | PGPASSWORD=SuperSecret1 psql -h kevinctokenizationdb.cjm7z941xa9c.us-east-1.rds.amazonaws.com -d kevinctokenizationdb -U root
# PGPASSWORD=$DB_PASS psql -h $TOKEN_DB_HOST -d $POSTGRES_DBNAME -U $DB_USER

# create client policy
sudo bash -c "cat >/root/$CURRENT_DIRECTORY/client_policy.hcl" <<EOT
# To request data encoding using any of the roles
# Specify the role name in the path to narrow down the scope
path "transform/encode/mobile-pay" {
   capabilities = [ "update" ]
}

# To request data decoding using any of the roles
# Specify the role name in the path to narrow down the scope
path "transform/decode/mobile-pay" {
   capabilities = [ "update" ]
}

# To validate the token
path "transform/validate/mobile-pay" {
   capabilities = [ "update" ]
}

# To retrieve the metadata belong to the token
path "transform/metadata/mobile-pay" {
   capabilities = [ "update" ]
}

# To check and see if the secret is tokenized
path "transform/tokenized/mobile-pay" {
   capabilities = [ "update" ]
}
EOT
