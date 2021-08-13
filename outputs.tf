output "vault-ip" {
    value = aws_instance.vault-server[*].public_ip
}

output "vault-login" {
    value = {
        for instance in aws_instance.vault-server:
        instance.tags["NodeID"] => "ssh -i ~/keys/${var.key_pair}.pem ubuntu@${instance.public_ip}"
    }
}

output "mysql-host" {
    value = aws_db_instance.vault-mysql.endpoint
}

output "jenkins-ui" {
    value = "http://${aws_instance.jenkins-server.public_ip}:8080"
}

output "jenkins-instance" {
    value = "ssh -i ~/keys/${var.key_pair}.pem ubuntu@${aws_instance.jenkins-server.public_ip}"
}

output "ec2-allow-instance" {
    value = "ssh -i ~/keys/${var.key_pair}.pem ubuntu@${aws_instance.vault-ec2-allow.public_ip}"
}

output "ec2-deny-instance" {
    value = "ssh -i ~/keys/${var.key_pair}.pem ubuntu@${aws_instance.vault-ec2-deny.public_ip}"
}
