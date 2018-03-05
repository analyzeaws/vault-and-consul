/* plugin directory under vault home */
plugin_directory = "/opt/vault/plugin"
api_addr = "https://127.0.0.1:8300"
max_lease_ttl = "10h"
default_lease_ttl = "4h"

storage "inmem" {
  path = "/opt/vault/data"
}

listener "tcp" {
    address = "0.0.0.0:8210"
    tls_disable = "true"
    // decrypted certificate key 
    tls_cert_file = "tls/vault.server.pem"
    // decrypted private key
    tls_key_file  = "tls/localhost.decrypted.key.pem" 
    tls_require_and_verify_client_cert = "false"
    tls_client_ca_file = "tls/vault.server.pem"
}

disable_mlock = true /* for dev, mlock is not available on WSL */
