disable_cache = false /* true will degrade performance */
disable_mlock = true /* for dev, mlock is not needed, for production should be enabled */

/* plugin directory under vault home */
plugin_directory = "./plugin"
api_addr = "https://127.0.0.1:8300"

ui = true

/* Enable for aws deploy with consul

storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}

ha_backend "consul" {
    advertise_addr = "snafu"
    disable_clustering = "true"
}

backend "consul" {
    foo = "bar"
    advertise_addr = "foo"
}
*/

/* remove below when deploying to production */
storage "inmem" {
  path = "/mnt/c/utils/vault/data"
}

listener "tcp" {
    address = "127.0.0.1:8200"
    tls_disable = "true"
    /*
    tls_cert_file = "/mnt/c/Users/deepa/source/repos/vault-and-consul/examples/vault-consul-ami/tls/vault.crt.pem"
    tls_key_file  = "/mnt/c/Users/deepa/source/repos/vault-and-consul/examples/vault-consul-ami/tls/vault.key.pem"
    */
}

max_lease_ttl = "10h"
default_lease_ttl = "4h"
cluster_name = "deepak"
pid_file = "./pidfile"
raw_storage_endpoint = true
