terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = "eu-west-1"
  shared_credentials_file = "./keys/aws/key"
  profile                 = "default"  
}

resource "aws_key_pair" "alice" {
  key_name   = "alice"
  public_key = file("./keys/ssh/id_rsa.pub")
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "alice" {
  key_name      = aws_key_pair.alice.key_name
  
  ami           = "ami-0aef57767f5404a3c"
  instance_type = "t2.micro"

  vpc_security_group_ids = [ aws_security_group.allow_ingress.id, aws_security_group.allow_egress.id ]
}

resource "aws_security_group" "allow_ingress" {
  vpc_id      = data.aws_vpc.default.id
  
  name        = "allow_ingress"
  description = "Allow ingress"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_egress" {
  vpc_id      = data.aws_vpc.default.id

  name        = "allow_egress"
  description = "Allow egress"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.alice.id
}

data "template_file" "inventory" {
  template = file("./terraform/_templates/inventory.tpl")
  
  vars = {
    user = "ubuntu"
    host = join("", ["alice ansible_host=", aws_eip.ip.public_ip])
  }
}

resource "local_file" "save_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory"
}
