terraform { 
  cloud { 
    
    organization = "SeeSquared" 

    workspaces { 
      name = "remote-exec" 
    } 
  } 
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2 in us-east-1
  instance_type          = "t2.micro"
  key_name               = "remote-exec"
  vpc_security_group_ids = [aws_security_group.ssh.id]

#  provisioner "remote-exec" {
#    inline = [
#      "echo 'ENV VARS:'",
#      "echo HOME=$HOME",
#      "echo USER=$USER",
#      "echo PATH=$PATH",
#      "echo '${var.private_key}'",
#      "echo AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY",
#      "echo AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID",
#    ]
#
#    connection {
#      type        = "ssh"
#      user        = "ec2-user"
#      private_key = var.private_key
#      host        = self.public_ip
#    }
#  }

  tags = {
    Name = "TF Remote Exec Example"
    key1 = "value1"
    key2 = "value2"
  }
}

resource "null_resource" "remote-exec" {
  depends_on = [aws_instance.example]

  triggers = {
    build_number = timestamp()
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ENV VARS:'",
      "echo HOME=$HOME",
      "echo USER=$USER",
      "echo PATH=$PATH",
      "echo '${var.private_key}'",
      "echo AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY",
      "echo AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.private_key
      host        = aws_instance.example.public_ip
    }
  }
}
