#!/bin/bash

CURRENT_DIRECTORY="03_eaas"
# encryption as a service
cd /root/$CURRENT_DIRECTORY
git clone https://github.com/norhe/transit-app-example.git

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/transit-app-example/backend/config.ini" <<EOT
[DEFAULT]
LogLevel = WARN

[DATABASE]
Address=$DB_HOST
Port=3306
User=${DB_USER}
Password=${DB_PASS}
Database=my_app

[VAULT]
Enabled=False
DynamicDBCreds=False
ProtectRecords=False
Address=http://localhost:8200
Token=$VAULT_TOKEN
KeyPath=lob_a/workshop/transit
KeyName=customer-key
EOT

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/transit-app-example/backend/config-x.ini" <<EOT
[DEFAULT]
LogLevel = WARN

[DATABASE]
Address=$DB_HOST
Port=3306
User=${DB_USER}
Password=${DB_PASS}
Database=my_app

[VAULT]
Enabled=True
DynamicDBCreds=False
ProtectRecords=False
Address=http://localhost:8200
Token=$VAULT_TOKEN
KeyPath=lob_a/workshop/transit
KeyName=customer-key
EOT

mkdir /root/$CURRENT_DIRECTORY/app
mv /root/$CURRENT_DIRECTORY/transit-app-example/backend/* /root/$CURRENT_DIRECTORY/app
rm -r /root/$CURRENT_DIRECTORY/transit-app-example

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/app/run" <<EOT
#!/bin/bash

python3 /root/$CURRENT_DIRECTORY/app/app.py > /root/$CURRENT_DIRECTORY/app/log.txt &
EOT
chmod a+x /root/$CURRENT_DIRECTORY/app/run

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_interactive.sh" <<EOT
clear
cat <<DESCRIPTION
The transit engine enables you to create encryption keys 
for developers to use to easily encrypt sensitive data. Let's 
enable the transit engine and create a key

# Enable the secret engine
vault secrets enable -path=lob_a/workshop/transit transit

# Create our customer key
vault write -f lob_a/workshop/transit/keys/customer-key

Press any key to continue...
DESCRIPTION

read -n1 kbd

# Enable the secret engine
vault secrets enable -path=lob_a/workshop/transit transit > /dev/null

# Create our customer key
vault write -f lob_a/workshop/transit/keys/customer-key > /dev/null

cd /root/$CURRENT_DIRECTORY/app
./run
echo "http://$VAULT_IP:5000/"

echo "Configuration complete!"

read -n1 kbd

clear
cat <<DESCRIPTION
By default, this application doesn't make use of the transit 
engine. So let's enable to transit engine within the application.

CONFIG.INI
----------
...
Password=XXXXXX
Database=my_app

[VAULT]
Enabled=True
DynamicDBCreds=False
ProtectRecords=False
...

Press any key to continue...
DESCRIPTION

read -n1 kbd

pkill python3

mv /root/$CURRENT_DIRECTORY/app/config.ini /root/$CURRENT_DIRECTORY/app/config-z.ini

mv /root/$CURRENT_DIRECTORY/app/config-x.ini /root/$CURRENT_DIRECTORY/app/config.ini

cd /root/$CURRENT_DIRECTORY/app
echo "http://$VAULT_IP:5000/"
./run
cd ..
echo "Press any key to continue..."
read -n1 kbd
EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_interactive.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_auto.sh" <<EOT
echo "Configuring Transit Engine..."
# Enable the secret engine
vault secrets enable -path=lob_a/workshop/transit transit > /dev/null

# Create our customer key
vault write -f lob_a/workshop/transit/keys/customer-key > /dev/null

EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_auto.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/reset.sh" <<EOT
vault secrets disable lob_a/workshop/transit > /dev/null
EOT
chmod a+x /root/$CURRENT_DIRECTORY/reset.sh
