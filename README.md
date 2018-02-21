# Vault AWS Module

This repo contains an example which illustrates how to deploy a [Vault](https://www.vaultproject.io/) cluster on
[AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/). Vault is an open source tool for managing
secrets. By default, this Module uses [Consul](https://www.consul.io) as a [storage
backend](https://www.vaultproject.io/docs/configuration/storage/index.html). You can optionally add an [S3](https://aws.amazon.com/s3/) backend for durability.

![Vault architecture](https://github.com/hashicorp/terraform-aws-vault/blob/master/_docs/architecture.png?raw=true)

# Pre-requisites
## Create a local CA Cert & Keys
* [private-tls-cert](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/private-tls-cert): Generate a private TLS certificate for use with a private Vault cluster. This is done to ensure that we need to accept the ca cert only once, and subsequent integration with the Vault does not warn for https.

  Store the generated certs and keys on _**local**_ file system.
 **TBD**: Avoid this, and automate generation of ca auth and signed certs after image creation. That would avoid having to create the certs offline first. Perhaps store the certs in Vault.

all the builds and development is done ubuntu bash shell running on windows 10 natively using Atom Editor - ** yay! **

## _**Packer Image**_  (with Vault/Consul and Oracle Instant Client) _, How it is built ?_

Steps executed are as below for building the packer image


```
  update packer.ignore file with keys et. al.
  $ cd examples
  $ vault-consul-ami\scripts\build.sh vault-consul-ami base packer.ignore
  ```
  Build script above takes three parameters


  (1) Directory to compare the SHA signature from, this directory should contain all the configuration files for the packer build.
  In above example it is vault-consul-ami


  (2) Name of the image as json file. IN above example it is `base[.json]`


  (3) `packer.ignore` file *(yup, you need your own credentials ;)* contains all secrets such aws keys et. al. packer.ignore contents look like below

  ```
  {
  "aws_access_key_id" : "XXXXXXXXXXXXXXXX",
  "aws_secret_access_key" : "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "github_oauth_token" : "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "region" : "us-east-1",
  "vault_version": "0.9.3",
  "vault_module_version": "master",
  "consul_module_version": "master",
  "consul_version": "1.0.6",
  "ca_public_key_path": "vault-and-consul/examples/vault-consul-ami/tls/ca.crt.pem",
  "tls_public_key_path": "vault-and-consul/examples/vault-consul-ami/tls/vault.crt.pem",
  "tls_private_key_path": "vault-and-consul/examples/vault-consul-ami/tls/vault.key.pem"
  }
  ```

 **Generated certs are subsumed into guest OS.**


 [update-certificate-store](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/update-certificate-store): Add a trusted, CA public key to an OS's certificate store. This allows you to establish TLS connections to services that use this TLS certs signed by this CA without getting x509 certificate errors.


** Image is built, Image is time-stamped, versioned and certs are transferred over. **

Uses a
 [Packer](https://www.packer.io/) template to create a Vault
 [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html), and
 [Ubuntu16 Machine Image (AMI)](https://aws.amazon.com/marketplace/pp/B01JBL2M0O).
 Both the images are provided same suffix based on the timestamp the image was created.
 Image has the tag containing SHA generated from `git` repository as an integrity marker.

 AMI Image integrity is determined by comparing the computed ``git SHA`` *-vis-a-vis-* ``SHA`` tag on AMI image.


**Image pulls & installs vault and consul from github ** (https://github.com/analyzeaws/vault-and-consul)


 [install-vault](https://github.com/analyzeaws/vault-and-consul/tree/master/modules/install-vault):
  Packer template itself rebuilds every time there is change to git repository containing the packing information for the AMI.

---
TBD
* [run-vault](https://github.com/analyzeaws/vault-and-consul/tree/master/modules/run-vault): This module can be used to configure and run Vault. It can be used in a
  [User Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts)
  script to fire up Vault while the server is booting.

* [vault-cluster](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster): Terraform code to deploy a cluster of Vault servers using an [Auto Scaling
  Group](https://aws.amazon.com/autoscaling/).

* [vault-elb](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-elb): Configures an [Elastic Load Balancer
  (ELB)](https://aws.amazon.com/elasticloadbalancing/classicloadbalancer/) in front of Vault if you need to access it
  from the public Internet.

Modules are borrowed heavily from [Gruntwork](http://www.gruntwork.io/).
Key modules are as below
```
├── mainRDS.tf // Main file to provision RDS
├── main.tf    // Main file to provision vault and consul cluster
├── manifest-base.json // Manifest file generator by packer
├── modules
│   ├── consul-cluster  // Module to provision consul cluster
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── consul-iam-policies // Module for consul policies, so it can talk to vault
│   │   ├── main.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── consul-security-group-rules // Module to configure consul, port ingress/egress rule, for VPC
│   │   ├── main.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── db_instance // Module to configure, DB instance parameters, used by mainRDS.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── policy
│   │   │   └── enhancedmonitoring.json
│   │   └── variables.tf
│   ├── db_parameter_group // Module to configure DB parameters, used by mainRDS.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── db_subnet_group // Module to assign RDS in given subnets, used by mainRDS.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── install-consul  // Module to install Consul
│   │   ├── install-consul
│   │   ├── README.md
│   │   ├── supervisord.conf
│   │   └── supervisor-initd-script.sh
│   ├── install-ic // Shell script to install Oracle Instant Client, used during AMI buid by packer
│   │   ├── install-ic
│   │   └── README.md
│   ├── install-vault // Shell script to install vault, used during AMI build by packer
│   │   ├── install-vault
│   │   ├── README.md
│   │   ├── supervisord.conf
│   │   └── supervisor-initd-script.sh
│   ├── private-tls-cert // Shell script to generate private TLS certificate
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.backup
│   │   └── variables.tf
│   ├── rds              // Module to provision RDS instance
│   │   ├── mainRDS.tf
│   │   ├── outputsRDS.tf
│   │   ├── README.md
│   │   └── variablesRDS.tf
│   ├── run-consul   // shell script to run consul
│   │   ├── README.md
│   │   └── run-consul
│   ├── run-vault    // Shell script to run Vault
│   │   ├── README.md
│   │   └── run-vault
│   ├── update-certificate-store // Shell script to update local OS cert store, used during AMI build by packer
│   │   ├── README.md
│   │   └── update-certificate-store
│   ├── vault-cluster  // Module to povision Vault Cluster
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── vault-elb // Module to provision ELB in fron of Vault < optional >
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   └── vault-security-group-rules // Module to provision security groups for Vault instance
│       ├── main.tf
│       ├── README.md
│       └── variables.tf
├── outputsRDS.tf // provides endpoint and url et. al. to connect to database
├── outputs.tf
├── README.md
├── variablesRDS.tf
└── variables.tf
```

To deploy Vault with this Module, you will need to deploy two separate clusters: one to run
[Consul](https://www.consul.io/) servers (which Vault uses as a [storage
backend](https://www.vaultproject.io/docs/configuration/storage/index.html)) and one to run Vault servers.

To deploy the Consul server cluster, use the [Consul AWS Module](https://github.com/hashicorp/terraform-aws-consul).

To deploy the Vault cluster:

1. Execute the [run-consul script](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/run-consul)
   with the `--client` flag during boot on each Instance to have the Consul agent connect to the Consul server cluster.

1. Execute the [run-vault](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/run-vault) script during boot on each Instance to create the Vault cluster.

1. If you only need to access Vault from inside your AWS account (recommended), run the [install-dnsmasq
   module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-dnsmasq) on each server, and
   that server will be able to reach Vault using the Consul Server cluster as the DNS resolver (e.g. using an address
   like `vault.service.consul`). See the [vault-cluster-private example](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-cluster-private) for working
   sample code.

1. If you need to access Vault from the public Internet, deploy the [vault-elb module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-elb) in a public
   subnet and have all requests to Vault go through the ELB. See the [vault-cluster-public
   example](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-cluster-public) for working sample code.

# Vault Use Case 1
This sections details, usage of vault using the oracle instant client to, provision dynamic credentials from oracle.
## Benefits
 * credentials are short-lived, and can be audited (using vault audit backend)
 * credentials are never exposed, and serve the key requirement of credentials to be cycled periodically
  #### Idea ?:
_ Perhaps write a java DataSource using Vault, so we can enhance vault adoption in enterprise ?  _

*** pre-requisite ***  : copy the vault oracle plugin into vault plugin directory and ensure instant client is configured with correct path and linker editor settings.
* Vault Configure using the HCL config file

* Vault operator init to Initialize the Vault

* Vault operator unseal to unseal the Vault

* Vault user(s) are provisioned, to be authenticated using `userpass`

* Each normal user (provisioned above) is then associated with either `read` or `readWrite` role on the database

* Vault secrets enable database, to enable database integration

* vault read database to generate the token

 Provision credentials dynamically using vault read from database
