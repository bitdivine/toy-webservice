###############################################################################
###  This generates the core network but none of the servers that run in it.
##
#

###############################################################################
# VARIABLES
###############################################################################

variable "region" {}
variable "availability_zone" {}
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "public_subnet_cidr" {}
variable "private_subnet_cidr" {}

###############################################################################
### PROVIDER
###############################################################################

provider "aws" {
    region = "${var.region}"
}

###############################################################################
### VPC
###############################################################################

resource "aws_vpc" "main" {
    cidr_block = "${var.vpc_cidr}"

    tags {
        Name = "${var.vpc_name}"
    }
}


###############################################################################
### SUBNETS
###############################################################################

resource "aws_subnet" "public" {
    vpc_id                  = "${aws_vpc.main.id}"
    cidr_block              = "${var.public_subnet_cidr}"
    availability_zone       = "${var.region}${var.availability_zone}"
    map_public_ip_on_launch = true

    tags {
        Name = "public"
        Type = "public"
    }
}

resource "aws_subnet" "private" {
    vpc_id                  = "${aws_vpc.main.id}"
    cidr_block              = "${var.private_subnet_cidr}"
    availability_zone       = "${var.region}${var.availability_zone}"
    map_public_ip_on_launch = false

    tags {
        Name = "private"
        Type = "private"
    }
}

###############################################################################
### SECURITY GROUPS
###############################################################################

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
  }
  egress { # NTP
    cidr_blocks = ["91.189.89.198/32", "91.189.89.199/32", "91.189.91.157/32"]
    protocol    = "udp"
    from_port   = 123
    to_port     = 123
  }
  egress { # NTP
    cidr_blocks = ["91.189.89.198/32", "91.189.89.199/32", "91.189.91.157/32"]
    protocol    = "udp"
    from_port   = 123
    to_port     = 123
  }
}

resource "aws_security_group" "public_webserver" {
  name        = "public_webserver"
  description = "Allow all inbound traffic to ports 80 and 443"
  vpc_id      = "${aws_vpc.main.id}"

  # Web access:
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion" {
  # ssh access - as we have no vpn yet
  name        = "bastion"
  description = "Allow inbound ssh to port 22"
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_default_security_group.default.id}"]
  }
}

resource "aws_security_group" "software_downloader" {
  name        = "software_downloader"
  description = "Allow downloads from anywhere"
  vpc_id      = "${aws_vpc.main.id}"

  # Simple but loose setup: This allows outgoing connections so that packages can
  # be installed on the production box.
  # To make this stricter, there are options:
  # * Set up a deb proxy within the VPC that serves only validated packages and records
  #   which packages have been installed on read-only media so that there is an audit trail.
  # * Generate an image with all the code pre-installed so that nothing needs to be
  #   installed on the production machine and all outgoing connections can be sealed off.
  # * Push all the required packages to the machine after boot.  Again, this allows us
  #   to block all outgoing connections in the security group.
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

###############################################################################
### INTERNET GATEWAY
###############################################################################
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "main"
  }
}

###############################################################################
### NAT GATEWAY
###############################################################################

resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.id}"
  depends_on    = ["aws_internet_gateway.gw"]
}

###############################################################################
### ROUTE TABLES
###############################################################################

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "public"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "private"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }
}
resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}
