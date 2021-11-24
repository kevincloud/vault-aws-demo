## Multi-feature Vault Demo running on AWS

# Features

* Auto unseal with AWS KMS
* Dynamic Database Secrets with RDS MySQL
* AWS IAM Authentication
* Encryption as a Service
* Automated PKI cert rotation
* Tokenization with PostgreSQL
* Format-Preserving Encryption

# Demo setup

1. Fork this repo (https://github.com/kevincloud/vault-aws-demo.git)
2. Create a workspace in Terraform Cloud using your newly-forked repo as the VCS
3. Create the following variables either by updating `terraform.tfvars` if you'r using CLI or API driven runs or using Terraform Cloud/Enterprise provider (Step 4)
   * `aws_region`: The region to create these resources in. Default is `us-east-1`
   * `key_pair`: This is the key pair for being able to SSH into the EC2 instances. It assumes you already have a key pair in the region you're deploying in (Required)
   * `instance_type`: The name of the instance type to create for each EC2 instance. Default is `t3.small`
   * `db_instance_type`: The name of the instance type to use for the MySQL and PostgreSQL RDS instances. Default is `t3.small`
   * `num_nodes`: The total number of nodes to create for the cluster. This should be `1`, `3`, or `5` to satisfy `raft` requirements.
   * `db_user`: The username for the database instances. Default is `root`
   * `db_pass`: The password for the database instances. Required
   * `mysql_dbname`: The MySQL DB instance name. Default is `sedemovaultdb`
   * `postgres_dbname`: The PostgreSQL DB instance name. Default is `tokenizationdb`
   * `kms_key_id`: Your KMS Key ID to use for Auto Unseal. Required
   * `vault_dl_url`: The download URL for Vault. Default points to version 1.9.0
   * `vault_license`: The Vault Enterprise license key. Default is empty (not required)
   * `consul_tpl_url`: The download URL for Consul Template. Default points to 0.27.2
   * `autojoin_key`: The tag key used for Raft Storage auto-join. Default is `vault_server_cluster`
   * `autojoin_value`: The tag value used for Raft Storage auto-join. Default is `vault_raft`
   * `prefix`: A unique identifier to use when naming resources. Required
   * `git_branch`: The git branch to use when cloning this repo for running scripts. Default is `master`
   * `owner`: The email address of the person setting up this demo. Required
   * `se_region`: The region of the SE setting up this demo. Required
   * `purpose`: The purpose of this coonfiguration. Default is already set
   * `ttl`: The time-to-live for this configuration. Required
   * `terraform`: Whether this configuration is managed by Terraform. Default is `true`
4. If you're using Terraform Enterprise/Cloud, you can use the `tfe` Terraform provider under `tfe` subdirectory and update the variables in your workspace. Then run `terraform init` and `terraform apply` to push all variables to your TFE/TFC workspace. (You need to make sure you have exported your TFE/TFC TOKEN as an enviornment variable)
5. Add your AWS credentials as environment variables (this should be done through Doormat)

```
 doormat aws --account $AWS_ACCOUNT_NUMBER --tf-push --tf-workspace $TFC_WORKSPACE --tf-organization $TFC_ORGANIZATION
```
6. Now you can trigger a run to deploy the demo setup!

7. Once the infrastructure is deployed login to the vault server. The `vault-login` output from terraform contains an ssh command, though the key name and location may need to be modified to match your environment.

8. SSH into the Vault server and ensure it's up and unsealed. Note: recovery key is in `/root/init.txt`

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

Some fake credentials were automatically added to vault during setup. To verify all data is still intact, simply look up your credentials:

```bash
vault kv get secret/creds
```

You should see:

```bash
====== Metadata ======
Key              Value
---              -----
created_time     2019-04-05T18:01:18.980320626Z
deletion_time    n/a
destroyed        false
version          1

====== Data ======
Key         Value
---         -----
password    Super$ecret1
username    vault_user
```

# Demo Workflow

From here you can launch each of the demos by executing either each one individually  or run them all using `runall.sh`

```
/root # 
01_database  02_ec2auth  03_eaas  04_pki  05_tokenization  06_fpe  init.txt  resetall.sh  runall.sh  snap  vault-aws-demo
```


