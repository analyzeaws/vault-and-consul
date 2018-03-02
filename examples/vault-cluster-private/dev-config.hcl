/* plugin directory under vault home */
plugin_directory = "./plugin"
api_addr = "https://127.0.0.1:8300"

max_lease_ttl = "10h"
default_lease_ttl = "4h"
pid_file = "./pidfile"

/*
***************************************************************************
setup vault initial authentication (using userpass here)
========================================================
(1) vault auth enable userpass

(2) Create List of Users are deepakAdmin/deepak, deepakReader, deepakWriter
vault write auth/userpass/users/deepakAdmin \
    password=deepak \
    policies="oracleAdmin, oracleReadOnly, oracleReadWrite"

    vault write auth/userpass/users/deepakReader \
        password=deepak \
        policies=oracleReadOnly

    vault write auth/userpass/users/deepakWriter \
        password=deepak \
        policies=oracleReadWrite

(3) Create policy for each oracle database roles
vault write sys/policy/oracleAdmin policy=@oracleAdmin.hcl
vault write sys/policy/oracleReadOnly policy=@oracleReadOnly.hcl
vault write sys/policy/oracleReadWrite policy=@oracleReadWrite.hcl

(4) Check login works using userpass
vault login -method=userpass \
username=deepakReader \
password=deepak

(2) deepak


Setup Vault with oracle integration
==================================
enable database oracle secrets engine
-vault secrets enable database

-download the oracle plugin from github
calculate the sha256 sum for the plugin
sha256 vault-plugin-database-oracle
086c50770b4ed89e768f7864c310baa2871986fb2cef7f781a7ec826d9ff0a50

-register the oracle plugin
vault write sys/plugins/catalog/vault-plugin-database-oracle  sha_256=086c50770b4ed89e768f7864c310baa2871986fb2cef7f781a7ec826d9ff0a50  command="vault-plugin-database-oracle"

- configure the database plugin for oracle, to talk to oracle, with role for oracleAdmin
vault write database/config/HSHCRPDB \
plugin_name="vault-plugin-database-oracle" \
allowed_roles="[hshCreate, hshRead]" \
connection_url="hshcrp/hashicorp@//hshcrpdb.c0ukynotdvav.us-east-1.rds.amazonaws.com:1521/HSHCRPDB"

- Create the role for DB create statements
vault write database/roles/hshCreate \
db_name="HSHCRPDB" \
creation_statements="CREATE USER {{name}} IDENTIFIED BY {{password}} DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP; \
GRANT SELECT ANY TABLE TO {{name}} ; \
GRANT CREATE ROLE TO {{name}} ; \
GRANT CREATE LIBRARY TO {{name}} ; \
GRANT CREATE TRIGGER TO {{name}} ; \
GRANT DEBUG CONNECT SESSION TO {{name}} ; \
GRANT CREATE MATERIALIZED VIEW TO {{name}} ; \
GRANT CREATE INDEXTYPE TO {{name}} ; \
GRANT CREATE VIEW TO {{name}} ; \
GRANT CREATE SESSION TO {{name}} ; \
GRANT BECOME USER TO {{name}} ; \
GRANT CREATE TABLE TO {{name}} ; \
GRANT CREATE TYPE TO {{name}} ; \
GRANT QUERY REWRITE TO {{name}} ; \
GRANT CREATE PUBLIC SYNONYM TO {{name}} ; \
GRANT GLOBAL QUERY REWRITE TO {{name}} ; \
GRANT CREATE SYNONYM TO {{name}} ; \
GRANT CREATE SEQUENCE TO {{name}} ; \
GRANT CREATE USER TO {{name}} ; \
GRANT DROP PUBLIC SYNONYM TO {{name}} ; \
GRANT DROP USER TO {{name}} ; \
GRANT FORCE TRANSACTION TO {{name}} ; \
GRANT CREATE PROCEDURE TO {{name}} " \
default_ttl="1h" \
max_ttl="24h"

vault write database/roles/hshRead \
db_name=HSHCRPDB \
creation_statements="create user {{name}} identified by {{password}}; \
GRANT CONNECT TO {{name}}; GRANT CREATE SESSION TO {{name}};" \
default_ttl="1h" \
max_ttl="24h"

vault read database/creds/hshRead
vault read database/creds/hshCreate

*****************************************************************************
*/
