#!/bin/bash

# encryption as a service
cd /root/eaas
git clone https://github.com/norhe/transit-app-example.git

sudo bash -c "cat >/root/eaas/s1_enable_transit.sh" <<EOT
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

/root/eaas/app/run
echo "http://$VAULT_IP:5000/"
EOT
chmod a+x /root/eaas/s1_enable_transit.sh

sudo bash -c "cat >/root/eaas/transit-app-example/backend/config.ini" <<EOT
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

sudo bash -c "cat >/root/eaas/transit-app-example/backend/config-x.ini" <<EOT
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

mkdir /root/eaas/app
mv /root/eaas/transit-app-example/backend/* /root/eaas/app
rm -r /root/eaas/transit-app-example

sudo bash -c "cat >/root/eaas/app/run" <<EOT
#!/bin/bash

python3 /root/eaas/app/app.py > /root/eaas/app/log.txt &
EOT
chmod a+x /root/eaas/app/run

sudo bash -c "cat >/root/eaas/s2_reconfig_transit.sh" <<EOT
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

mv /root/eaas/app/config.ini /root/eaas/app/config-z.ini

mv /root/eaas/app/config-x.ini /root/eaas/app/config.ini

/root/eaas/app/run
echo "http://$VAULT_IP:5000/"
EOT
chmod a+x /root/eaas/s2_reconfig_transit.sh
