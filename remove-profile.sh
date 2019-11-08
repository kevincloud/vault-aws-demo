aws iam remove-role-from-instance-profile --instance-profile-name vault-kms-unseal --role-name vault-kms-role-unseal
aws iam delete-role-policy --role-name vault-kms-role-unseal --policy-name Vault-KMS-Unseal
aws iam delete-role --role-name vault-kms-role-unseal
aws iam delete-instance-profile --instance-profile-name vault-kms-unseal
