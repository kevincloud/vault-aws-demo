#!/bin/bash

CURRENT_DIRECTORY="05_tokenization"
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
    connection_string='postgresql://{{username}}:{{password}}@mypostgres/mydb?sslmode=disable' \\\\
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
    connection_string='postgresql://{{username}}:{{password}}@${TOKEN_DB_HOST}/${POSTGRES_DBNAME}?sslmode=disable' \\
    username=${DB_USER} \\
    password=${DB_PASS} > /dev/null

vault write transform/stores/postgres/schema transformation_type=tokenization \\
    username=${DB_USER} password=${DB_PASS} > /dev/null

echo "Configuration complete!"

read -n1 kbd

clear
cat <<DESCRIPTION
Finally, we need to create the tokenization engine
for the role we created. This one will be called
credit-card.

vault write transform/transformations/tokenization/credit-card \\\\
    allowed_roles=mobile-pay \\\\
    max_ttl=24h \\\\
    stores=postgres

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault write transform/transformations/tokenization/credit-card \\
    allowed_roles=mobile-pay \\
    max_ttl=24h \\
    stores=postgres >/dev/null

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
    value="1234-1234-1234-1234" >./current_token.txt

CC_TOKEN=\$(cat ./current_token.txt | awk -F ' ' 'NR>2{print \$2}')

echo ""
echo "The token is: \$CC_TOKEN"

echo ""
echo "select * from tokens" | PGPASSWORD=$DB_PASS psql -h $TOKEN_DB_HOST -d $POSTGRES_DBNAME -U $DB_USER

read -n1 kbd

clear
cat <<DESCRIPTION
And let's decode the token to obtain the original value

vault write transform/encode/mobile-pay \\\\
    transformation=credit-card \\\\
    value="XXXXX"

DESCRIPTION

read -n1 kbd

vault write transform/decode/mobile-pay \\
    transformation=credit-card \\
    value="\$CC_TOKEN"
echo ""

EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_interactive.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_auto.sh" <<EOT
vault secrets enable transform > /dev/null

vault write transform/role/mobile-pay transformations=credit-card > /dev/null

vault write transform/stores/postgres \\
    type=sql \\
    driver=postgres \\
    supported_transformations=tokenization \\
    connection_string='postgresql://{{username}}:{{password}}@${TOKEN_DB_HOST}/${POSTGRES_DBNAME}?sslmode=disable' \\
    username=${DB_USER} \\
    password=${DB_PASS} > /dev/null

vault write transform/stores/postgres/schema transformation_type=tokenization \\
    username=${DB_USER} password=${DB_PASS} > /dev/null

vault write transform/transformations/tokenization/credit-card \\
    allowed_roles=mobile-pay \\
    max_ttl=24h \\
    stores=postgres >/dev/null

EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_auto.sh
