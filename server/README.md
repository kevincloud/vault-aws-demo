## Auto Unseal with AWS KMS

To setup this demo:

1. Clone this repo to your machine
   ```bash
   git clone https://github.com/kevincloud/vault-aws-demo.git
   ```
2. In the `server` directory in the project directory, create a `terraform.tfvars` file and supply the following information:
   ```
   aws_access_key=
   aws_secret_key=
   key_pair=
   ```
3. Deploy the infrastructure
   ```bash
   terraform apply
   ```
4. Login to the vault server. The `vault-login` output from terraform contains an ssh command, though the key name and location may need to be modified.

### Implementing Auto Unseal

This Vault instance is using defaults to manage the master key, using shamir. Since we're likely to already have secrets, we really don't want to re-initialize Vault. Instead, we'll migrate from Shamir to AWS KMS.

Make sure you have already created a managed key in KMS. We'll need that key id.

#### Step 1. Update Vault Configuration

We'll need to add a few lines to Vault's configuration file, so let's start by stopping the vault service:

```bash
service vault stop
```

Using your favorite editor, edit the `/etc/vault.d/vault.hcl` file and add these lines, replacing <KEYID> with your AWS KMS key id:

```hcl
seal "awskms" {
    region = "us-west-1"
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
