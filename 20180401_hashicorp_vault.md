# Manage secrets with Hashicorp Vault

During development it is common to save local connection string in the code via setting files. But when it comes the time to deploy, hosted environments should not have their secrets persisted as plain text in the code.
Since those can't be saved in the git repository, they have to be stored in a secure place where they can be managed easily, _a vault_. Hashicorp Vault is one of this software which allows us to store and retrieve secrets while providing a granular level of control over the secret accesses.
Today we will see the basic configuration of Hashicorp Vault to store and retrieve secrets using the Vault CLI. This post will be composed by four parts:

1. Start Vault
2. Save secrets
3. Create a role with a policy
4. Retrieve secrets

## 1. Start Vault

### 1.1 Configure Vault

Head to https://www.vaultproject.io/downloads.html and download the latest binaries of Vault then place it in a folder and add the folder to PATH.

Before starting Vault we need to create a configuration, copy the following in `config.hcl`:

```txt
storage "file" {
  path = "data"
}

listener "tcp" {
 address     = "127.0.0.1:8200"
 tls_disable = 1
}
```

This configuration specifies that Vault will save it's data on the filesystem in the `/data` folder relative to where Vault executable is.
Next start Vault with `vault server -config config.hcl`.

### 1.2 Initiliaze Vault

Once Vault is running we can initialize it by opening another command prompt and running:

```txt
set VAULT_ADDR=http://localhost:8200
vault operator init -key-threshold=1 -key-shares=1
```

```txt
Unseal Key 1: jaRLkdU5TZ3Thq6Tdw4iAIGXGo7xHXrk9fSnQJPf7b8=
Initial Root Token: d5918c94-edc5-ffcc-1d9e-c11c92f350cf
```

The first time Vault is initilized, it generates secret keys, here a single one since we set the `key-shares` and `key-threshold` to one and a root token.
__The secret keys need to be kept securely.__ They are used to reconstruct the master key and execute operation like unsealing the vault or generating another root token.

The root token is a token provided for the first Vault user to bootstrap the configuration. The root token has all access therefore it is recommended to revoke it once the configuration is done. If need be another root token can be generated using the secret keys.

### 1.3 Unseal vault and login

When the vault starts it is sealed. To unseal it we need the key.

```txt
vault operator unseal
Unseal Key (will be hidden):
```

Next once we unsealed the vault, we can login:

```txt
vault login
Token (will be hidden):
```

We should now be logged in as root user.

## 2. Save secrets

Next we can start to add secret like so:

```txt
vault write secret/myapp some_secret=123
```

As you can see Vault works like a filesystem with paths. We are able to read/write secrets on a particular path.

```txt
vault read secret/myapp
Key                 Value
---                 -----
refresh_interval    768h
some_secret         123
```

We can also write in sub folders:

```txt
vault write secret/myapp/production some_secret=456
```

```txt
vault list secret/myapp
Keys
----
production
```

```txt
vault read secret/myapp/production
Key                 Value
---                 -----
refresh_interval    768h
some_secret         456
```

You also must have noticed that everything was prefixed with `secret`. `secret` is the default handler for secrets to be stored and retrieved from key value store. More information [here](https://www.vaultproject.io/intro/getting-started/secrets-engines.html).

## 3. Create a role with a policy

What we need next is to have a way to generate tokens with read access only to the secrets under myapp.

The authentication targeted to application needing to authenticate to Vault to request the secrets they need is called `approle`.

### 3.1 Enable approle

Approle allows us to create a role which is configured with policies dictating the accesses granted by the token.
We run the following command to enable approle.

```txt
vault auth enable approle
```

### 3.2 Create policy

Next we can create a policy which allows the read on `/myapp`. We start by creating a hcl file:

```txt
path "secret/myapp/*" {
  capabilities = ["read"]
}
```

Vault also provides a utility to verify that the policy is formatted properly using `fmt`.

```txt
vault policy fmt policies/myapp.hcl
```

And lastly we add the policy in vault.

```txt
vault policy write myapp policies/myapp.hcl
```

```txt
vault policy read myapp
path "secret/myapp/*" {
  capabilities = ["read"]
}
```

### 3.3  Create role

A role allows us to group together a set of policies and configurate settings on the secret and token like TTL.

We already created the policy so now we can create the role and associate the policy to it.

```txt
vault write auth/approle/role/myapp secret_id_ttl=10m secret_id_num_uses=10 policies=default,myapp
```

Whoever authenticates under the role myapp will be provided a token allowing read access to secrets under `/myapp`.

Now the authentication requires two pieces, role Id and secret Id.
The role id can be found using the following command.

....

And the secret id can be found using the following command.

...

Providing the information to the application......not handle the srecret only app handles

## 4. Retrieve secrets

## 4. Retrieve secrets