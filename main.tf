resource "aws_security_group" "allow_ssh_jenkins"{
  
  name = "allow_ssh_jenkins"
  description = "Allowing port 22 for SSH access"
    
    # usually we allow everything in egress
  egress { #outgoing traffic and we dont need to authenticate
    from_port        = 0
    to_port          = 0
    protocol         = "-1" #-1 for everything
    cidr_blocks      = ["0.0.0.0/0"] #allow from everyone
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress { # incoming traffic
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_jenkins"
  }
  
}

module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins"
  ami= data.aws_ami.ami_info.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.allow_ssh_jenkins.id]
  subnet_id              = "subnet-03718395d9ae148ca"
  user_data = file("jenkins.sh")

  tags = {
        Name= "jenkins"
    }
  root_block_device=[
    {
        volume_size = 50
        volume_type = "gp3"
        delete_on_termination = true
    }
  ]
  
}
module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"
  ami= data.aws_ami.ami_info.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.allow_ssh_jenkins.id]
  subnet_id              = "subnet-03718395d9ae148ca"
  user_data = file("jenkins-agent.sh")

  tags = {
        Name= "jenkins-agent"
    }
  root_block_device=[
    {
        volume_size = 50
        volume_type = "gp3"
        delete_on_termination = true
    }
  ]
  
}
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip
      ]
      allow_overwrite = true
    }
  ]

}