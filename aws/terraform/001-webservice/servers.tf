###############################################################################
###  This generates the core network but none of the servers that run in it.
##
#

###############################################################################
# VARIABLES
###############################################################################

variable "ssh_key_name" {}
variable "backend_domain_name" {}

###############################################################################
### AMI
###############################################################################

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}


###############################################################################
### BASTION
###############################################################################

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.id}"
  key_name      = "${var.ssh_key_name}"
  vpc_security_group_ids = [
    "${aws_default_security_group.default.id}",
    "${aws_security_group.bastion.id}",
  ]
  tags {
    Name = "bastion"
  }
}

resource "aws_eip_association" "bastion" {
  allocation_id  = "${aws_eip.bastion.id}"
  instance_id    = "${aws_instance.bastion.id}"
}


###############################################################################
### LOAD BALANCER
###############################################################################


resource "aws_instance" "service_load_balancer" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.id}"
  key_name      = "${var.ssh_key_name}"
  vpc_security_group_ids = [
    "${aws_default_security_group.default.id}",
    "${aws_security_group.public_webserver.id}",
    "${aws_security_group.software_downloader.id}",
  ]
  tags {
    Name = "service_load_balancer"
  }
  user_data = "${file("./user_data/load_balancer")}"
}

resource "aws_eip_association" "lb" {
  allocation_id  = "${aws_eip.lb.id}"
  instance_id    = "${aws_instance.service_load_balancer.id}"
}


###############################################################################
### BACK END SERVER
###############################################################################

resource "aws_instance" "backend_1" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.private.id}"
  key_name      = "${var.ssh_key_name}"
  vpc_security_group_ids = [
    "${aws_default_security_group.default.id}",
    "${aws_security_group.software_downloader.id}",
  ]
  associate_public_ip_address = false
  tags { 
    Name = "backend"
  }
  user_data = "${file("./user_data/backend")}"
}

resource "aws_instance" "backend_2" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.private.id}"
  key_name      = "${var.ssh_key_name}"
  vpc_security_group_ids = [
    "${aws_default_security_group.default.id}",
    "${aws_security_group.software_downloader.id}",
  ]
  associate_public_ip_address = false
  tags { 
    Name = "backend"
  }
  user_data = "${file("./user_data/backend")}"
}

###############################################################################
### BACK END SERVER IP ADDRESSES
###############################################################################

resource "aws_route53_record" "backend_domain_name" {
  zone_id = "${data.aws_route53_zone.service_zone.zone_id}"
  name    = "${var.backend_domain_name}"
  type    = "A"
  ttl     = "300"
  records = [ "${aws_instance.backend_1.private_ip}"
            , "${aws_instance.backend_2.private_ip}"
            ]
}
