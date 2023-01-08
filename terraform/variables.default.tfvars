aws_region = ""
tags = {
  application_name = ""
  owner            = ""
  environment      = ""
  prefix           = ""
  costCenter       = ""
  tagVersion       = ""
  project          = ""
}
ssh_public_key      = "ssh-rsa AAAAB3.....axbcQ== user@hostname"
ssm_tunnel_instance_server = "./templates/ssm-tunnel-instance-server.tpl"
ssm_tunnel_instance_client = "./templates/ssm-tunnel-instance-client.tpl"