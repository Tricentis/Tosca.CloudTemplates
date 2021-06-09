data "aws_ami" "toscaserver_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.toscaserver_ami_name]
  }

  filter {
    name   = "tag:Version"
    values = [var.toscaserver_ami_version]
  }

  owners = [var.toscaserver_ami_owner]
}

resource "aws_instance" "toscaserver" {
  ami                         = data.aws_ami.toscaserver_ami.id
  instance_type               = var.toscaserver_instance_type
  get_password_data           = false
  monitoring                  = false
  key_name                    = var.toscaserver_key_pair_name
  vpc_security_group_ids      = [aws_security_group.sg_services.id]
  subnet_id                   = aws_subnet.subnet_services.id
  associate_public_ip_address = true
  user_data                   = templatefile("${path.module}/user_data.tpl", { 
      postdeploy_script_path = "C:\\ProgramData\\ToscaPostDeploy\\PostDeploy-ToscaServerAWS.ps1",
      toscaserver_uri        = "x",
      database_fqdn           = aws_db_instance.rds_db.address 
    })

  tags = {
    Name        = "${var.environment_name}-toscaserver"
    Environment = var.environment_name
  }
}

resource "aws_eip" "server_eip" {
  instance = aws_instance.toscaserver.id
  vpc      = true
}