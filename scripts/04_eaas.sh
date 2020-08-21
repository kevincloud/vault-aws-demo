#!/bin/bash

# encryption as a service
cd /root/04_eaas
git clone https://github.com/norhe/transit-app-example.git

sudo bash -c "cat >/root/04_eaas/s1_enable_transit.sh" <<EOT
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

cd /root/04_eaas/app
./run
echo "http://$VAULT_IP:5000/"
EOT
chmod a+x /root/04_eaas/s1_enable_transit.sh

sudo bash -c "cat >/root/04_eaas/transit-app-example/backend/config.ini" <<EOT
[DEFAULT]
LogLevel = WARN

[DATABASE]
Address=$DB_HOST
Port=3306
User=${MYSQL_USER}
Password=${MYSQL_PASS}
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

sudo bash -c "cat >/root/04_eaas/transit-app-example/backend/config-x.ini" <<EOT
[DEFAULT]
LogLevel = WARN

[DATABASE]
Address=$DB_HOST
Port=3306
User=${MYSQL_USER}
Password=${MYSQL_PASS}
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

mkdir /root/04_eaas/app
mv /root/04_eaas/transit-app-example/backend/* /root/04_eaas/app
rm -r /root/04_eaas/transit-app-example

sudo bash -c "cat >/root/04_eaas/app/run" <<EOT
#!/bin/bash

python3 /root/04_eaas/app/app.py > /root/04_eaas/app/log.txt &
EOT
chmod a+x /root/04_eaas/app/run

sudo bash -c "cat >/root/04_eaas/s2_reconfig_transit.sh" <<EOT
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

mv /root/04_eaas/app/config.ini /root/04_eaas/app/config-z.ini

mv /root/04_eaas/app/config-x.ini /root/04_eaas/app/config.ini

cd /root/04_eaas/app
./run
echo "http://$VAULT_IP:5000/"
EOT
chmod a+x /root/04_eaas/s2_reconfig_transit.sh
