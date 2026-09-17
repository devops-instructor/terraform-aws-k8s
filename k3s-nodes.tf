# K3s Server
resource "aws_instance" "k3s_server" {
  ami           = "ami-096f5760b00bcd95c" # Ubuntu Server 24.04 LTS
  instance_type = "t3.small"
  key_name      = "k8s-keypair"

  vpc_security_group_ids = [aws_security_group.k8s_nodes_sg.id]

  tags = {
    Name = "k3s-server"
  }
}

# K3s Workers
resource "aws_instance" "k3s_worker" {
  count = 1

  ami           = "ami-096f5760b00bcd95c" # Ubuntu Server 24.04 LTS
  instance_type = "t3.small"
  key_name      = "k8s-keypair"

  vpc_security_group_ids = [aws_security_group.k8s_nodes_sg.id]

  tags = {
    Name = "k3s-worker-${count.index + 1}"
  }
}

resource "aws_security_group" "k8s_nodes_sg" {
  name = "k8s-nodes-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Solo para laboratorio
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Inventario Ansible
resource "local_file" "inventory" {
  content = <<-EOF
[k3s_server]
k3s-server ansible_host=${aws_instance.k3s_server.public_ip} private_ip=${aws_instance.k3s_server.private_ip}

[k3s_workers]
%{ for i, worker in aws_instance.k3s_worker ~}
k3s-worker-${i + 1} ansible_host=${worker.public_ip} private_ip=${worker.private_ip}
%{ endfor ~}

[all:vars]
ansible_user=ubuntu
EOF

  filename = "${path.module}/inventory.ini"
}

output "server_ip" {
  value = aws_instance.k3s_server.public_ip
}

output "worker_ips" {
  value = aws_instance.k3s_worker[*].public_ip
}