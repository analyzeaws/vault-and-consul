# Vault Cluster with S3 backend example 

This folder shows an example of Terraform code to deploy a [Vault](https://www.vaultproject.io/) cluster in 
[AWS](https://aws.amazon.com/) using the [vault-cluster module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster).
The Vault cluster uses [Consul](https://www.consul.io/) as a high-availability storage backend and [S3](https://aws.amazon.com/s3/)
for durable storage, so this example also deploys a separate Consul server cluster using the
[consul-cluster module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster) from the Consul AWS Module.

This example creates a Vault cluster spread across the subnets in the default VPC of the AWS account. Each of the
servers in this example has [Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) installed (via the 
[install-dnsmasq module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-dnsmasq)) 
which allows it to use the Consul server cluster for service discovery and thereby access Vault via DNS using the 
domain name `vault.service.consul`. For an example of a Vault cluster
that is publicly accessible, see [vault-cluster-public](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-cluster-public).

![Vault architecture](https://github.com/hashicorp/terraform-aws-vault/blob/master/_docs/architecture-with-s3.png?raw=true)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Vault and Consul installed, which you can do using the [vault-consul-ami example](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-consul-ami)).  

For more info on how the Vault cluster works, check out the [vault-cluster](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster) documentation.

**Note**: To keep this example as simple to deploy and test as possible, it deploys the Vault cluster into your default 
VPC and default subnets, some of which might be publicly accessible. This is OK for learning and experimenting, but for 
production usage, we strongly recommend deploying the Vault cluster into the private subnets of a custom VPC.




## Quick start

To deploy a Vault Cluster:

1. `git clone` this repo to your computer.
1. Build a Vault and Consul AMI. See the [vault-consul-ami example](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-consul-ami) documentation for 
   instructions. Make sure to note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI ID into the `ami_id` variable.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
1. Run the [vault-examples-helper.sh script](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-examples-helper/vault-examples-helper.sh) to 
   print out the IP addresses of the Vault servers and some example commands you can run to interact with the cluster:
   `../vault-examples-helper/vault-examples-helper.sh`.

To see how to connect to the Vault cluster, initialize it, and start reading and writing secrets, head over to the 
[How do you use the Vault cluster?](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster#how-do-you-use-the-vault-cluster) docs.
