# -------- Commented for integrated use with vault-consul
/*
provider "aws" {
region = "${var.aws_region}"
}

data "aws_vpc" "default" {
default = "${var.use_default_vpc}"
tags     = "${module.vpc.vpc_tags}"
}


# -------- Commented for integrated use with vault-consul
*/
##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################


##############################################################
# need to ensure that default vpc group allows oracle tns listener port connection, default 1521
##############################################################
data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

#####
# DB
#####
module "db" {
  source = "modules/rds"

  identifier = "hshcrpdb"

  engine            = "oracle-se2"
  engine_version    = "12.1.0.2.v10"
  instance_class    = "db.t2.micro"
  allocated_storage = 10
  storage_encrypted = false
  license_model     = "bring-your-own-license"

  # Make sure that database name is capitalized, otherwise RDS will try to recreate RDS instance every time
  name                                = "HSHCRPDB"
  username                            = "hshcrp"
  password                            = "hashicorp"
  port                                = "1521"
  iam_database_authentication_enabled = false

  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]
  maintenance_window     = "Mon:00:00-Mon:03:00"
  backup_window          = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "Deepak for Hashicorp"
    Environment = "dev datbase"
  }

  # DB subnet group
  #subnet_ids = ["${data.aws_subnet_ids.all.ids}"]
  # TBD, move this into private subnet
  subnet_ids = "${module.vpc.public_subnets}"

  # DB parameter group
  family = "oracle-se2-12.1"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "HSHCRPDB"
}
