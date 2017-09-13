###############################################################################
###  This generates the external interfaces - the stable IPs, domain names and
##   network interfaces.
#    This is to ensure that we never have to wait for DNS propagation if we replace
#    the servers or change the way a service is implemented.
#    We assume that a public zone pre-exists and exclude it from this file for safety.

###############################################################################
# VARIABLES
###############################################################################

variable "bastion_domain_name" {}
variable "service_domain_name" {}
variable "service_zone_name" {}
variable "private_service_ip" {}

data "aws_route53_zone" "service_zone" {
  name         = "${var.service_zone_name}"
  private_zone = false
}

###############################################################################
### IP address - this is a stable IP address that can be preserved when the
###              load balancer is replaced.
###############################################################################

resource "aws_eip" "lb" {
  vpc      = true
}

resource "aws_route53_record" "service_domain_name" {
  zone_id = "${data.aws_route53_zone.service_zone.zone_id}"
  name    = "${var.service_domain_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.lb.public_ip}"]
}


###############################################################################
### IP address - for the bastion
###############################################################################

resource "aws_eip" "bastion" {
  vpc      = true
}

resource "aws_route53_record" "bastion_domain_name" {
  zone_id = "${data.aws_route53_zone.service_zone.zone_id}"
  name    = "${var.bastion_domain_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.bastion.public_ip}"]
}
