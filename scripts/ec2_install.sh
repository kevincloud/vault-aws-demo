#!/bin/sh
# Configures the Vault server for a database secrets demo

echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -y update > /dev/null 2>&1
# sudo apt-get -y upgrade > /dev/null 2>&1
sudo apt-get install -y unzip jq python3 python3-pip > /dev/null 2>&1
pip3 install awscli

sudo bash -c "cat >/root/sign_request.py" <<EOT
#!/usr/bin/env python
# -What-------------------------------------------------------------------------
# This script creates a request to the AWS Security Token Service API
# with the action "GetCallerIdentity" and then signs the request using the
# AWS credentials. It was modified from the python 2.x example published by
# J. Thompson, the author of the Vault IAM auth method, at the vault support
# mailing list. https://groups.google.com/forum/#!topic/vault-tool/Mfi3O-lW60I
# -Why--------------------------------------------------------------------------
# We are using python here instead of bash to take advantage of the boto3 library
# which facilitates this work by an order of magnitude
# -What-for---------------------------------------------------------------------
# This is useful for authenticating to Vault, because a client can use
# this script to generate this request and this request is sent with the
# login attempt to the Vault server. Vault then executes this request and gets
# the response from GetCallerIdentity, which tells who is trying to authenticate
# ------------------------------------------------------------------------------

import botocore.session
from botocore.awsrequest import create_request_object
import json
import base64
import sys

def headers_to_go_style(headers):
    retval = {}
    for k, v in headers.items():
        if isinstance(v, bytes):
            retval[k] = [str(v, 'utf-8')]
        else:
            retval[k] = [v]
    return retval

def generate_vault_request(awsIamServerId):
    session = botocore.session.get_session()
    client = session.create_client('sts')
    endpoint = client._endpoint
    operation_model = client._service_model.operation_model('GetCallerIdentity')
    request_dict = client._convert_to_request_dict({}, operation_model)

    request_dict['headers']['X-Vault-AWS-IAM-Server-ID'] = awsIamServerId

    request = endpoint.create_request(request_dict, operation_model)

    return {
        'iam_http_request_method': request.method,
        'iam_request_url':         str(base64.b64encode(bytes(request.url, 'utf-8')), 'utf-8'),
        'iam_request_body':        str(base64.b64encode(bytes(request.body, 'utf-8')), 'utf-8'),
        'iam_request_headers':     str(base64.b64encode(bytes(json.dumps(headers_to_go_style(dict(request.headers))), 'utf-8')), 'utf-8'), # It's a CaseInsensitiveDict, which is not JSON-serializable
    }

if __name__ == "__main__":
    awsIamServerId = sys.argv[1]
    print(json.dumps(generate_vault_request(awsIamServerId)))
EOT


sudo bash -c "cat >/root/s1_vault_login.sh" <<EOT
#!/bin/bash
clear
cat <<DESCRIPTION
Our application can login without needing to pass secrets.

# Get signed URL
signed_request=\\\$(python3 /root/sign_request.py ${VAULT_IP})
iam_request_url=\\\$(echo \\\$signed_request | jq -r .iam_request_url)
iam_request_body=\\\$(echo \\\$signed_request | jq -r .iam_request_body)
iam_request_headers=\\\$(echo \\\$signed_request | jq -r .iam_request_headers)

# Create data payload
data=\\\$(cat <<EOF
{
  "role": "app-db-role",
  "iam_http_request_method": "POST",
  "iam_request_url": "\\\$iam_request_url",
  "iam_request_body": "\\\$iam_request_body",
  "iam_request_headers": "\\\$iam_request_headers"
}
EOF
)

# Login and retrieve client token
curl -s \\\\
  --request POST \\\\
  --data "\\\$data" \\\\
  "http://${VAULT_IP}:8200/v1/auth/aws/login"

Press any key to continue...
DESCRIPTION

read -n1 kbd

# Get signed URL
signed_request=\$(python3 /root/sign_request.py ${VAULT_IP})
iam_request_url=\$(echo \$signed_request | jq -r .iam_request_url)
iam_request_body=\$(echo \$signed_request | jq -r .iam_request_body)
iam_request_headers=\$(echo \$signed_request | jq -r .iam_request_headers)

# Create data payload
data=\$(cat <<EOF
{
  "role": "app-db-role",
  "iam_http_request_method": "POST",
  "iam_request_url": "\$iam_request_url",
  "iam_request_body": "\$iam_request_body",
  "iam_request_headers": "\$iam_request_headers"
}
EOF
)

# Login and retrieve client token
curl -s \\
  --request POST \\
  --data "\$data" \\
  "http://${VAULT_IP}:8200/v1/auth/aws/login" | jq . > auth.txt

export CLIENT_TOKEN="\$(cat auth.txt | jq -r .auth.client_token | tr -d '\n')"

if [ "\$CLIENT_TOKEN" != "null" ]; then
  echo "Your token is: \$CLIENT_TOKEN"
else
  cat auth.txt | jq -r .errors[0]
fi
EOT
chmod a+x /root/s1_vault_login.sh

sudo bash -c "cat >/root/s2_get_creds.sh" <<EOT
#!/bin/bash
clear
cat <<DESCRIPTION
Once we've logged in an have received a token, we can access 
the secrets associated with the role we've logged in with.

curl -s \\\\
    --header "X-Vault-Token: \\\$CLIENT_TOKEN" \\\\
    http://${VAULT_IP}:8200/v1/database/creds/app-role | jq 

Press any key to continue...
DESCRIPTION

read -n1 kbd

curl -s \\
    --header "X-Vault-Token: \$CLIENT_TOKEN" \\
    http://${VAULT_IP}:8200/v1/database/creds/app-role | jq 
EOT
chmod a+x /root/s2_get_creds.sh
