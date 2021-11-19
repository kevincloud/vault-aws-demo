#!/bin/bash

CURRENT_DIRECTORY="06_fpe"
sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_interactive.sh" <<EOT
clear
cat <<DESCRIPTION
First we need to enable the transform engine for fpe, 
then create a role which we can use for encrypting
sensitive information

vault secrets enable -path=transform-fpe transform

vault write transform-fpe/role/payments \\\\
    transformations=credit-card

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault secrets enable -path=transform-fpe transform > /dev/null

vault write transform-fpe/role/payments \\
  transformations=credit-card > /dev/null

echo "Configuration complete!"

read -n1 kbd

clear
cat <<DESCRIPTION
Next, we need to tell our role which format 
template to use during the encryption process

vault write transform-fpe/transformations/fpe/credit-card \\\\
    template="builtin/creditcardnumber" \\\\
    tweak_source=internal \\\\
    allowed_roles=payments

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault write transform-fpe/transformations/fpe/credit-card \\
    template="builtin/creditcardnumber" \\
    tweak_source=internal \\
    allowed_roles=payments > /dev/null

echo "Configuration complete!"

read -n1 kbd
clear
cat <<DESCRIPTION
Now that our configuration is complete, we can 
watch format-preserving encryption in action. 
Let's encrypt a credit card number.

vault write transform-fpe/encode/payments \\\\
    transformation=credit-card \\\\
    value="1234-1234-1234-1234"

Press any key to continue...
DESCRIPTION

read -n1 kbd

vault write transform-fpe/encode/payments \\
    transformation=credit-card \\
    value="1234-1234-1234-1234" >./current_token.txt

CC_TOKEN=\$(cat ./current_token.txt | awk -F ' ' 'NR>2{print \$2}')

echo ""
echo "The token is: \$CC_TOKEN"

read -n1 kbd

clear
cat <<DESCRIPTION
And let's decode the token to obtain the original value

vault write transform-fpe/decode/payments \\\\
    transformation=credit-card \\\\
    value="XXXXX"

DESCRIPTION

read -n1 kbd

vault write transform-fpe/decode/payments \\
    transformation=credit-card \\
    value="\$CC_TOKEN"
echo ""

echo "Press any key to continue..."
read -n1 kbd
EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_interactive.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/run_auto.sh" <<EOT

vault secrets enable -path=transform-fpe transform > /dev/null

vault write transform-fpe/role/payments \\
  transformations=credit-card > /dev/null

vault write transform-fpe/transformations/fpe/credit-card \\
    template="builtin/creditcardnumber" \\
    tweak_source=internal \\
    allowed_roles=payments > /dev/null

EOT
chmod a+x /root/$CURRENT_DIRECTORY/run_auto.sh

sudo bash -c "cat >/root/$CURRENT_DIRECTORY/reset.sh" <<EOT
vault secrets disable transform-fpe > /dev/null
EOT
chmod a+x /root/$CURRENT_DIRECTORY/reset.sh
