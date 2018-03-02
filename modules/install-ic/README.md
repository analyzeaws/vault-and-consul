# Vault Install Script

This folder contains a script for installing Instant Client and its dependencies. You can use this script, along with the

This script has been tested on the following operating systems:

* Ubuntu 16.04
* Amazon Linux

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.



## Quick start

To install Oracle Instant Client,  run the `install-ic` script:
**** Needs Linux rpm files available at home directory ***


The `install-ic` script will install Instant Client, its dependencies.

Recommend running the `install-ic` script as part of a [Packer](https://www.packer.io/) template to create a
Vault [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (see the
[vault-consul-ami example](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-consul-ami) for sample code). You can then deploy the AMI across an Auto
Scaling Group using the [vault-cluster module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster) (see the
[vault-cluster-public](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-cluster-public) and [vault-cluster-private](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-cluster-private)
examples for fully-working sample code).




## Command line Arguments

The `install-vault` script accepts the following arguments:

* `path DIR`: Install IC into folder DIR. Optional.
* `user USER`: The install dirs will be owned by user USER. Optional.
* `url URL`: Alternative url URL to download IC from. Optional.

Example:

```
install-ic --path oracle --user oracle
```



## How it works

The `install-ic` script does the following:

1. [Create a user and folders for IC](#create-a-user-and-folders-for-ic)
1. [Install IC binaries and scripts](#install-ic-binaries-and-scripts)


### Create a user and folders for IC

Create an OS user named `oracle`. Create the following folders, all owned by user `oracle`:

* `/opt/oracle`: base directory for IC data (configurable via the `--path` argument).


### Install IC binaries and scripts

Install the Oracle Instant Client

### Follow-up tasks

After the `install-ic` script finishes running, you may wish to do the following:
Use the alien package to convert and install the RPMs.

 ```
 sudo alien -i oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
 sudo alien -i oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
 sudo alien -i oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm
 ```
Create a network/admin folder inside the installation folder and copy your tnsnames.ora and sqlnet.ora to this directory. For example installation folder is /opt/vault/oracle/11.2/client64 .

Set the Oracle environment variables by editing your PATH and adding ORACLE_HOME, OCI_LIB and TNS_ADMIN to your /etc/environment file as follows:

 ```
 PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/opt/oracle/11.2/client64/bin"
 ORACLE_HOME="/usr/opt/oracle/11.2/client64"
 OCI_LIB="/usr/opt/oracle/11.2/client64/lib"
 TNS_ADMIN="/usr/opt/oracle/11.2/client64/network/admin"
 ```
The LD_LIBRARY_PATH variable needs special treatment as per the Ubuntu help page:

 ```echo "/usr/opt/oracle/11.2/client64/lib" | sudo tee /etc/ld.so.conf.d/oracle.conf  sudo ldconfig -v```


Install libaio1

 ```sudo apt-get install libaio1```
