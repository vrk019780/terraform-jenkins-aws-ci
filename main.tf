provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "terraform_vcn" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "terraform_vcn"
  }
}

resource "aws_subnet" "terraform_subnet" {
  vpc_id                  = aws_vpc.terraform_vcn.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform_subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform_vcn.id

  tags = {
    Name = "terraform_igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terraform_vcn.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.terraform_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ssh_sg" {
  name        = "allow_ssh"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.terraform_vcn.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Tomcat HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

locals {
  index_html = file("${path.module}/index.html")
}

resource "aws_instance" "example" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.terraform_subnet.id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "terraform_instance"
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  provisioner "file" {
    content     = local.index_html
    destination = "/tmp/index.html"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y java-17-amazon-corretto wget tar",
      "sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat || true",
      "TOMCAT_VERSION=9.0.88",
      "wget https://archive.apache.org/dist/tomcat/tomcat-9/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz -P /tmp",
      "sudo mkdir -p /opt/tomcat",
      "sudo tar xf /tmp/apache-tomcat-$TOMCAT_VERSION.tar.gz -C /opt/tomcat --strip-components=1",
      "sudo chown -R tomcat: /opt/tomcat",
      "sudo chmod +x /opt/tomcat/bin/*.sh",
      "sudo -u tomcat /opt/tomcat/bin/startup.sh",
      "echo 'Waiting for Tomcat to start...'",
      "until curl -s http://localhost:8080 >/dev/null; do sleep 5; done",
      "echo '✅ Tomcat is up and running'",
      "sudo mv /tmp/index.html /opt/tomcat/webapps/ROOT/index.html"
    ]
  }
}

resource "null_resource" "wait_for_tomcat" {
  depends_on = [aws_instance.example]

  provisioner "local-exec" {
    command = <<EOC
      echo "⏳ Waiting for Tomcat to respond on port 8080..."
      for i in {1..20}; do
        if curl -s http://${aws_instance.example.public_ip}:8080 | grep -q "My Online Store"; then
          echo "✅ Tomcat is UP and responding!"
          exit 0
        fi
        sleep 10
      done
      echo "❌ Timed out waiting for Tomcat!"
      exit 1
    EOC
  }
}

