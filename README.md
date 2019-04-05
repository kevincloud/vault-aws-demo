## Auto Unseal with AWS KMS

To setup this demo:

1. Clone this repo to your machine
   ```bash
   git clone https://github.com/kevincloud/vault-aws-demo.git
   ```
2. Create a `terraform.tfvars` file and supply the following information:
   ```
   aws_access_key=<YOUR_AWS_ACCESS_KEY>
   aws_secret_key=<YOUR_AWS_SECRET_KEY>
   key_pair=<YOUR_AWS_KEY_PAIR>
   ```
3. Deploy the infrastructure
   ```bash
   terraform apply
   ```
4. Login to the vault server. The `vault-login` output from terraform contains an ssh command, though the key name and location may need to be modified to match your environment.

### Implementing Auto Unseal

This Vault instance is using defaults to manage the master key, using Shamir's secret sharing. Since we're likely to already have secrets, we really don't want to re-initialize Vault. Instead, we'll migrate from Shamir to AWS KMS.

Make sure you have already created a managed key in KMS. We'll need that key id.

#### Step 1. Update Vault Configuration

Once you're logged in, for the sake of simplicity, let's go ahead and login as root:

```bash
sudo su -
```

We'll need to add a few lines to Vault's configuration file, so let's start by stopping the vault service:

```bash
service vault stop
```

Using your favorite editor, edit the `/etc/vault.d/vault.hcl` file and add these lines, replacing <KEYID> with your AWS KMS key id:

```hcl
seal "awskms" {
    region = "us-west-2"
    kms_key_id = "<KEYID>"
}
```

Now, let start vault back up:

```bash
service vault start
```

#### Step 2. Unseal and Migrate

By default, Vault is sealed upon starting/restarting. So you would normally need to enter a quorum of unseal keys to unseal it. By implementing AWS KSM, we are eliminating the process of unsealing every time the service is restarted.

You can verify Vault is sealed by entering:

```bash
vault status
```

You'll see the specific line:

```bash
...
Sealed                   true
...
```

To complete the key migration, we'll need to manually unseal vault one last time. For this exercise, the unseal keys are located in the ~/init.txt file. Using the first three keys, enter the following commands, replacing <UNSEAL_KEY_X> with the respective key from the init.txt file:

```bash
vault operator unseal -migrate <UNSEAL_KEY_1>
vault operator unseal -migrate <UNSEAL_KEY_2>
vault operator unseal -migrate <UNSEAL_KEY_3>
```

The migration will now be complete. The vault will be unsealed, but to verify auto unseal is active, let's restart vault:

```bash
service vault restart
```

Now when you check the status of Vault:

```bash
vault status
```

You'll see it is unsealed by default:

```bash
...
Sealed                   false
...
```

#### Step 3. Remove Key Shares

We're almost done. Since our master key is managed by an external trusted source, we need to migrate away from a shared key to a single key.

```bash
vault operator rekey -init -target=recovery -key-shares=1 -key-threshold=1
```

Once again, we'll need our unseal keys from before as well as the nonce token provided after the rekey initialization:

```bash
vault operator rekey -target=recovery -key-shares=1 -key-threshold=1 -nonce=<NONCE_TOKEN> <UNSEAL_KEY_1>
vault operator rekey -target=recovery -key-shares=1 -key-threshold=1 -nonce=<NONCE_TOKEN> <UNSEAL_KEY_2>
vault operator rekey -target=recovery -key-shares=1 -key-threshold=1 -nonce=<NONCE_TOKEN> <UNSEAL_KEY_3>
```

Review the status of vault...

```bash
vault status
```

...to ensure all settings are correct:

```bash
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    1
Threshold                1
Version                  1.1.0
Cluster Name             vault-cluster-efcdaac3
Cluster ID               efe63829-a886-1d8d-3c5e-73cb5bc5cf3f
HA Enabled               false
```

Your AWS credentials were automatically added to vault during setup. To verify all data is still intact, simply look up your credentials:

```bash
vault kv get secret/aws
```
