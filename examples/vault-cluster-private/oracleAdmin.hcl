// database/creds
path "secret/database" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/userpass/users" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
