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

## Packer Image, How it is built ?

Steps executed are as below for building the packer image


```
  update packer.ignore file with keys et. al.
  $ cd examples
  $ vault-consul-ami\scripts\build.sh vault-consul-ami base packer.ignore
  ```
  Build script above takes three parameters


  (1) Directory to compare the SHA signature from, this directory should contain all the configuration files for the packer build.
  In above example it is vault-consul-ami


  (2) name of the image as json file. IN above example it is base[.json]


  (3) packer.ignore file contains all secrets such aws keys et. al. packer.ignore contents look like below

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

- **Image is built, Image is time-stamped, versioned and certs are transferred over. **

Uses a
 [Packer](https://www.packer.io/) template to create a Vault
 [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html), and
 [Ubuntu16 Machine Image (AMI)](https://aws.amazon.com/marketplace/pp/B01JBL2M0O).
 Both the images are provied same suffix based on the the timestamp image was created.
 Image have tag containing the SHA from git repository as an integrity marker.
 Image integrity is determined by comparing the SHA of git *-vis-a-vis-* SHA of image.


- **Image pulls & installs vault and consul from Hashicorp github **

 [install-vault](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/install-vault):
  Packer template itself rebuilds every time there is change to git repository containing the packing information for the AMI.

---
TBD
* [run-vault](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/run-vault): This module can be used to configure and run Vault. It can be used in a
  [User Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts)
  script to fire up Vault while the server is booting.

* [vault-cluster](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster): Terraform code to deploy a cluster of Vault servers using an [Auto Scaling
  Group](https://aws.amazon.com/autoscaling/).

* [vault-elb](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-elb): Configures an [Elastic Load Balancer
  (ELB)](https://aws.amazon.com/elasticloadbalancing/classicloadbalancer/) in front of Vault if you need to access it
  from the public Internet.


## What's a Module?

A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such
as a database or server cluster. Each Module is created primarily using [Terraform](https://www.terraform.io/),
includes automated tests, examples, and documentation, and is maintained both by the open source community and
companies that provide commercial support.

Instead of having to figure out the details of how to run a piece of infrastructure from scratch, you can reuse
existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself,
you can leverage the work of the Module community and maintainers, and pick up infrastructure improvements through
a version number bump.



## Who maintains this Module?

This Module is borrows heavily from [Gruntwork](http://www.gruntwork.io/).



## How do you use this Module?

Each Module has the following folder structure:

* [modules](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules): This folder contains the reusable code for this Module, broken down into one or more modules.
* [examples](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples): This folder contains examples of how to use the modules.
* [test](https://github.com/hashicorp/terraform-aws-vault/tree/master/test): Automated tests for the modules and examples.

Click on each of the modules above for more details.

To deploy Vault with this Module, you will need to deploy two separate clusters: one to run
[Consul](https://www.consul.io/) servers (which Vault uses as a [storage
backend](https://www.vaultproject.io/docs/configuration/storage/index.html)) and one to run Vault servers.

To deploy the Consul server cluster, use the [Consul AWS Module](https://github.com/hashicorp/terraform-aws-consul).

To deploy the Vault cluster:

1. Create an AMI that has Vault installed (using the [install-vault module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/install-vault)) and the Consul
   agent installed (using the [install-consul
   module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul)). Here is an
   [example Packer template](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-consul-ami).

   If you are just experimenting with this Module, you may find it more convenient to use one of our official public AMIs:
   - [Latest Ubuntu 16 AMIs](https://github.com/hashicorp/terraform-aws-vault/tree/master/_docs/ubuntu16-ami-list.md).
   - [Latest Amazon Linux AMIs](https://github.com/hashicorp/terraform-aws-vault/tree/master/_docs/amazon-linux-ami-list.md).

   **WARNING! Do NOT use these AMIs in your production setup. In production, you should build your own AMIs in your
     own AWS account.**

1. Deploy that AMI across an Auto Scaling Group in a private subnet using the Terraform [vault-cluster
   module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster).

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

1. Head over to the [How do you use the Vault cluster?](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster#how-do-you-use-the-vault-cluster) guide
   to learn how to initialize, unseal, and use Vault.
