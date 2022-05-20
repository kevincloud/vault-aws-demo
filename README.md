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
3. Create the following variables:
   * `aws_region`: The region to create these resources in. Default is `us-east-1`
   * `key_pair`: This is the key pair for being able to SSH into the EC2 instances. Required
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
4. Add your AWS credentials as environment variables. This should be done through Doormat.

Once Terraform has finished creating all resources, the bootstrap process will take 8 to 10 minutes to complete. You can monitor the boostrapping by SSH'ing into Node1, run `sudo su -`, then run `tail -f /var/log/cloud-init-output.log`. CloudInit will add a final entry to the log file indicating that it's complete. Keep in mind if you do login as root prior to CloudInit finishig, you'll likely have to log out of root and back in due to environment variables being set during the boostrap process.

# Running the Demos

Once you SSH into the instance, issue the `sudo su -` command to log in as root. Issue `ls` to see the files and directories available. Items to take note of are:

