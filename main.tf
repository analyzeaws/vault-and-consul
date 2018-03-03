# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VAULT SERVER CLUSTER, AN ELB, AND A CONSUL SERVER CLUSTER IN AWS
# This is an example of how to use the vault-cluster and vault-elb modules to deploy a Vault cluster in AWS with an
# Elastic Load Balancer (ELB) in front of it. This cluster uses Consul, running in a separate cluster, as its storage
# backend.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = "${var.aws_region}"
}

#----------------------------------------------------------------------------------------------------------------------
# create a non default VPC, with public and private subnet, spanning AZ's
#----------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source = "modules/aws-vpc"
  aws_region = "${var.aws_region}"
  environment= "vault-consul"

  availability_zones = {
    us-east-1 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }

}

# Terraform 0.9.5 suffered from https://github.com/hashicorp/terraform/issues/14399, which causes this template the
# conditionals in this template to fail.
terraform {
  required_version = ">= 0.9.3, != 0.9.5"
}

# ---------------------------------------------------------------------------------------------------------------------
# AUTOMATICALLY LOOK UP THE LATEST PRE-BUILT AMI
# This repo contains a CircleCI job that automatically builds and publishes the latest AMI by building the Packer
# template at /examples/vault-consul-ami upon every new release. The Terraform data source below automatically looks up
# the latest AMI so that a simple "terraform apply" will just work without the user needing to manually build an AMI and
# fill in the right value.
#
# !! WARNING !! These example AMIs are meant only convenience when initially testing this repo. Do NOT use these example
# AMIs in a production setting as those TLS certificate files are publicly available from the Module repo containing
# this code.
#
# NOTE: This Terraform data source must return at least one AMI result or the entire template will fail. See
# /_ci/publish-amis-in-new-account.md for more information.
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "vault_consul" {
  most_recent = true

  # If we change the AWS Account in which test are run, update this value.
  owners = ["self"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["vault-consul-ubuntu-*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE VAULT SERVER CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "vault_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/hashicorp/terraform-aws-vault//modules/vault-cluster?ref=v0.0.1"
  source = "modules/vault-cluster"

  cluster_name  = "${var.vault_cluster_name}"
  cluster_size  = "${var.vault_cluster_size}"
  instance_type = "${var.vault_instance_type}"

  ami_id    = "${var.ami_id == "" ? data.aws_ami.vault_consul.image_id : var.ami_id}"

  # primary used to select the vault binary and uploaded certs to start vault with
  user_data = "${data.template_file.user_data_vault_cluster.rendered}"

  vpc_id     = "${data.aws_vpc.vault_consul.id}"

  #subnet_ids = "${data.aws_subnet_ids.default.ids}"
  # changed to explicitly use ALL the public subnet(s) on the created VPC
  subnet_ids = "${module.vpc.public_subnets}"

  # Tell each Vault server to register in the ELB.
  load_balancers = ["${module.vault_elb.load_balancer_name}"]

  # Do NOT use the ELB for the ASG health check, or the ASG will assume all sealed instances are unhealthy and
  # repeatedly try to redeploy them.
  health_check_type = "EC2"

  # To make testing easier, we allow requests from any IP address here but in a production deployment, we *strongly*
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  # production: limit this to set of known address(s) only
  
  allowed_ssh_cidr_blocks            = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks        = ["0.0.0.0/0"]
  allowed_inbound_security_group_ids = []
  ssh_key_name                       = "${var.ssh_key_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES FOR CONSUL
# To allow our Vault servers to automatically discover the Consul servers, we need to give them the IAM permissions from
# the Consul AWS Module's consul-iam-policies module.
# ---------------------------------------------------------------------------------------------------------------------

module "consul_iam_policies_servers" {
  #source = "github.com/hashicorp/terraform-aws-consul//modules/consul-iam-policies?ref=v0.0.2"
  # Changed to use local policy version
  source = "modules/consul-iam-policies"

  iam_role_id = "${module.vault_cluster.iam_role_id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH VAULT SERVER WHEN IT'S BOOTING
# This script will configure and start Vault
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_vault_cluster" {
  template = "${file("${path.module}/examples/root-example/user-data-vault.sh")}"

  vars {
    aws_region               = "${var.aws_region}"
    consul_cluster_tag_key   = "${var.consul_cluster_tag_key}"
    consul_cluster_tag_value = "${var.consul_cluster_name}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE ELB
# ---------------------------------------------------------------------------------------------------------------------

module "vault_elb" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/hashicorp/terraform-aws-vault//modules/vault-elb?ref=v0.0.1"
  source = "modules/vault-elb"

  name = "${var.vault_cluster_name}"

  vpc_id     = "${data.aws_vpc.vault_consul.id}"
  #subnet_ids = "${data.aws_subnet_ids.default.ids}"
  # changed to explicitly use ALL the public subnet(s) on the created VPC
  subnet_ids = "${module.vpc.public_subnets}"


  # To make testing easier, we allow requests from any IP address here but in a production deployment, we *strongly*
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]

  # In order to access Vault over HTTPS, we need a domain name that matches the TLS cert
  create_dns_entry = "${var.create_dns_entry}"

  # Terraform conditionals are not short-circuiting, so we use join as a workaround to avoid errors when the
  # aws_route53_zone data source isn't actually set: https://github.com/hashicorp/hil/issues/50
  #hosted_zone_id = "${var.create_dns_entry ? join("", data.aws_route53_zone.selected.*.zone_id) : ""}"
  hosted_zone_id = "${var.hosted_zone_domain_name}"

  domain_name = "${var.vault_domain_name}"
}

# Look up the Route 53 Hosted Zone by domain name
/*
data "aws_route53_zone" "selected" {
  count = "${var.create_dns_entry}"
  name  = "${var.hosted_zone_domain_name}."
}
*/

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "consul_cluster" {
  #source = "github.com/hashicorp/terraform-aws-consul//modules/consul-cluster?ref=v0.0.2"
  #changed to use local pulled down version
  source = "modules/consul-cluster"

  cluster_name  = "${var.consul_cluster_name}"
  cluster_size  = "${var.consul_cluster_size}"
  instance_type = "${var.consul_instance_type}"

  # The EC2 Instances will use these tags to automatically discover each other and form a cluster
  cluster_tag_key   = "${var.consul_cluster_tag_key}"
  cluster_tag_value = "${var.consul_cluster_name}"

  ami_id    = "${var.ami_id == "" ? data.aws_ami.vault_consul.image_id : var.ami_id}"
  user_data = "${data.template_file.user_data_consul.rendered}"

  vpc_id     = "${data.aws_vpc.vault_consul.id}"
  #subnet_ids = "${data.aws_subnet_ids.default.ids}"
  # changed to explicitly use ALL the private subnet(s) on the created VPC
  subnet_ids = "${module.vpc.private_subnets}"

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.

  # TBD, change this to allow only vault to talk to consul 
  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  
  # TBD, change this to allow only vault to talk to consul 
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = "${var.ssh_key_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_consul" {
  template = "${file("${path.module}/examples/root-example/user-data-consul.sh")}"

  vars {
    consul_cluster_tag_key   = "${var.consul_cluster_tag_key}"
    consul_cluster_tag_value = "${var.consul_cluster_name}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CLUSTERS IN THE DEFAULT VPC AND AVAILABILITY ZONES
# Using the default VPC and subnets makes this example easy to run and test, but it means Consul and Vault are
# accessible from the public Internet. In a production deployment, we strongly recommend deploying into a custom VPC
# and private subnets. Only the ELB should run in the public subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "vault_consul" {
  default = "${var.use_default_vpc}"
  #tags    = "${var.vpc_tags}"
  # changed, to not to use default VPC, but use the VPC ID from the created VPC
  tags     = "${module.vpc.vpc_tags}"
}

