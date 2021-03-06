##################
# DB subnet group
##################
resource "aws_db_subnet_group" "this" {
  count = "${var.count ? 1 : 0}"

  name_prefix = "${var.name_prefix}"
  description = "Database subnet group for ${var.identifier}"
  subnet_ids  = ["${var.subnet_ids}"]

  tags = "${merge(var.tags, map("Name", format("%s", var.identifier)))}"
}
