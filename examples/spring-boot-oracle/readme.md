Spring Cloud Vault Config Oracle Integration
===========================================

This example uses Spring Cloud Vault Config
usage with the Oracle integration.

**Application shall depict below use case**

(1) Use Vault `database secrets` backend to obtain dynamic ``Username/Password`` , with a preset lease expiry. 
{this illustrates the fact that credentials are created dynamically from Vault, lending to ease of 
 - Audit // who, did, what & when, since credentials are generated dynamically. 
 - Reduction of threat vector // in situation of credentials compromise, it can be expired from Vault, easily. 
 - Rotation of credentials per policy // credentials lease could be set, as per the security policy for credentials rotation in the enterprise. 
    
(2) Use obtained credentials with DDL role to create test tables. 

(3) Retire the lease on the obtained credentials, to ensure there is not threat to changing the database schema anymore by the application.

(4) Use Vault `transit secrets` backend, to provide encryption as a service. and this encrypted data will be persisted to the table. 

(4) Retire the lease and obtain new dynamic credentials with DML role from Vault. 

(5) Use Vault to dynamically encrypt the table data to be inserted.

(6) Use the new credentials with DML role, to upsert the table data.

(7) Retire the credentials with DML role and obtain new credentials with read only role. 

(8) Use the read only credentials to read encrypted data from oracle and use vault to decrypt, read data from the database. 


## Running the Example

A typical scenario is 
 - running Oracle database on `localhost:1521` with an user configured during vault setup, with authorization to create new users.

The example setup script `src/test/bash/setup_examples.sh`
will use the user `hshcrpdb` with the password `hashicorp`
as administrative Oracle user.
