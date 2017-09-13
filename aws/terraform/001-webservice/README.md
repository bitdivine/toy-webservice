Bootstrap AWS infrastructure
============================

This code brings up a toy web service in AWS.

# Installation

#### Install tools

If needed, a local copy of terraform can be installed in `~/.ve/bin` with:

    make tools

The path can be added to the environment with:

    . ./source_me

A copy of docker can be installed on Linux with apt or on Mac from:

    https://www.docker.com/docker-mac

#### Installation

Three things are required before we start:
* Keys for an AWS account configured on your computer
* A public ssh key in AWS
* A domain name - I assume that you have a zone registered in AWS.

Fill in the above values in the variables file (all.tfvars) and adapt that file to taste. 
Launch the stack with terraform as usual.  For convenience you can use `make`.

#### SSH

Direct ssh access is blocked.  There is a bastion host, through wich you can ssh to
any instance.  There is an ssh configuration file for convenience:

    ssh -F ssh.config

On request, I can set up a VPN server on the bastion host so that no proxy is required.

# TODO
* More on security, both AWS and docker.
* Document why

#### TODO - DOCKER SECURITY
* Build images locally and push to a repo we control.

#### TODO - AWS SECURITY
* Sign ssh host keys
* IPtables - not really needed but there is defence in depth.
* Send syslog to an external location such as S3.
* Enable cloudwatch and cloudtrail
* Code source - check whether local sources are required:
** caching apt proxy
** local docker registry
* Code source - check whether secret sources are required.
* Set NTP rules - the current setup uses the default Ubuntu nameservers

#### TODO - RELIABILITY
* Put the server groups in autoscaling groups:
** Bastion - with ENI attachment
** Load balancer - with ENI
** Back ends
