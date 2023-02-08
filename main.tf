data "aws_secretsmanager_secret" "app_admin_secret" {
  name = var.app_admin_secret_name
}

data "aws_secretsmanager_secret_version" "app_admin_secret_version" {
  secret_id = data.aws_secretsmanager_secret.app_admin_secret.id
}

data "aws_secretsmanager_secret" "user_admin_secret" {
  name = var.user_admin_secret_name
}

data "aws_secretsmanager_secret_version" "user_admin_secret_version" {
  secret_id = data.aws_secretsmanager_secret.user_admin_secret.id
}

resource "random_password" "cicd_password" {
  length           = 16
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
  override_special = "!#$%&?"
}

data "aws_db_instances" "rds_instances" {
  filter {
    name   = "db-cluster-id"
    values = [var.cluster_identifier]
  }
}

locals {
  username = (length(data.aws_db_instances.rds_instances.instance_arns) > 0 ? "cicd_admin" : module.rds.cluster.master_username)
  password = (length(data.aws_db_instances.rds_instances.instance_arns) > 0 ? random_password.cicd_password.result : module.rds.cluster.master_password)
}

module "rds" {
  source  = "app.terraform.io/healthfirst/rds/aws"
  version = "1.0.0"

  cluster_identifier      = var.cluster_identifier
  engine                  = "aurora-mysql"
  engine_version          = var.engine_version
  availability_zones      = var.availability_zones
  database_name           = var.database_name
  db_subnet_group_name    = var.db_subnet_group_name
  vpc_security_group_ids  = var.vpc_security_group_ids
  instance_count          = var.instance_count
  instance_class          = var.instance_class
  skip_final_snapshot     = var.skip_final_snapshot
}

# Setup MySQL Provider After RDS Database is Provisioned
provider "mysql" {
    endpoint        = module.rds.cluster.endpoint
    username        = "${local.username}"
    password        = "${local.password}"
}

# Create CICD Admin
resource "mysql_user" "cicd_admin" {
    user               = "cicd_admin"
    host               = "%"
    plaintext_password = "${random_password.cicd_password.result}"
    depends_on         = [module.rds]
}

# Grant CICD Admin Rights
resource "mysql_grant" "cicd_admin_rights" {
    user              = "${mysql_user.cicd_admin.user}"
    host              = "${mysql_user.cicd_admin.host}"
    database          = var.database_name
    privileges        = ["ALL", "GRANT_OPTION"]
    depends_on        = [module.rds]
}

# Create App Admin
resource "mysql_user" "app_admin" {
    user               = "app_admin"
    host               = "%"
    plaintext_password = jsondecode(data.aws_secretsmanager_secret_version.app_admin_secret_version.secret_string)["password"]
    depends_on         = [module.rds]
}

# Grant App Admin Rights
resource "mysql_grant" "app_admin_rights" {
    user              = "${mysql_user.app_admin.user}"
    host              = "${mysql_user.app_admin.host}"
    database          = var.database_name
    privileges        = ["ALL", "GRANT_OPTION"]
    depends_on        = [module.rds]
}

# Create User Admin
resource "mysql_user" "user_admin" {
    user               = "user_admin"
    host               = "%"
    plaintext_password = jsondecode(data.aws_secretsmanager_secret_version.user_admin_secret_version.secret_string)["password"]
    depends_on         = [module.rds]
}

# Grant User Admin Rights
resource "mysql_grant" "user_admin_rights" {
    user              = "${mysql_user.user_admin.user}"
    host              = "${mysql_user.user_admin.host}"
    database          = var.database_name
    privileges        = ["CREATE_USER", "SELECT"]
    depends_on        = [module.rds]
}
