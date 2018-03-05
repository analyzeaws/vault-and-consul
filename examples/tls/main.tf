# ---------------------------------------------------------------------------------------------------------------------
# Generate a private self signed certificate, private and public key
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.9.3, != 0.9.5"
}

module "tls" {
  source = "../../modules/private-tls-cert"
 ca_public_key_file_path = "./certs/ca.crt"
 public_key_file_path="./certs/vault.crt.pem"
 private_key_file_path="./certs/vault.key.pem"
 client_public_key_file_path="./certs/client.crt.pem"
 client_private_key_file_path="./certs/client.key.pem"
 owner="ubuntu"
 organization_name="Analyze AWS"
 ca_common_name="Analyze AWS Cert"
 common_name="Analyze AWS Certificate"
 dns_names=["vault.analyzeaws.com","vault.service.consul"]
 ip_addresses = ["127.0.0.1" ]
 client_common_name="Vault Client"
 client_dns_names=["localhost","client.analyzeaws.com","client.service.consul"]
 client_ip_addresses = ["127.0.0.1" ]
 client_organization_name="TheClient"
validity_period_hours=8760
}
