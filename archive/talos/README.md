# Bootstrapping Talos
## Prequisites

* You will need the following tools installed:
  - age
  - sops
  - talhelper
  - talosctl
  - kubectl
  - kustomize
  - helm

* You also need sops to be configured with your preferred encryption tool (age, pgp, etc).
### example install
```sh
     brew install age sops talhelper siderolabs/talos/talosctl kustomize kubectl helm
```

## Age
### Quick start
```sh
     mkdir -p ~/.config/sops/age
     age-keygen -o ~/.config/sops/age/keys.txt
```

### Encrypting using age
`age <https://age-encryption.org/>`_ is a simple, modern, and secure tool for
encrypting files. It's recommended to use age over PGP, if possible.

You can encrypt a file for one or more age recipients (comma separated) using
the ``--age`` option or the **SOPS_AGE_RECIPIENTS** environment variable:

```sh
sops --encrypt --age <my-age-public-key> test.yaml > test.enc.yaml
```
When decrypting a file with the corresponding identity, SOPS will look for a
text file name ``keys.txt`` located in a ``sops`` subdirectory of your user
configuration directory. On Linux, this would be ``XDG_CONFIG_HOME/sops/age/keys.txt``.
On macOS, this would be ``HOME/Library/Application Support/sops/age/keys.txt``. On
Windows, this would be ``%AppData%\sops\age\keys.txt``. You can specify the location
of this file manually by setting the environment variable **SOPS_AGE_KEY_FILE**.
Alternatively, you can provide the key(s) directly by setting the **SOPS_AGE_KEY**
environment variable.

The contents of this key file should be a list of age X25519 identities, one
per line. Lines beginning with ``#`` are considered comments and ignored. Each
identity will be tried in sequence until one is able to decrypt the data.

## GCP KMS

### Encrypting using GCP KMS

GCP KMS uses [Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials).
If you're already logged in using
```sh
     gcloud auth login
```
you can enable application default credentials using the sdk:
```sh
     gcloud auth application-default login
```
Encrypting/decrypting with GCP KMS requires a KMS ResourceID. You can use the
cloud console the get the ResourceID or you can create one using the gcloud
sdk:

```sh
gcloud kms keyrings create <mykeyring> --location global
gcloud kms keys create sops --location global --keyring <mykeyring> --purpose encryption
gcloud kms keys list --location global --keyring <mykeyring>
# you should see
NAME                                                                   PURPOSE          PRIMARY_STATE
projects/<my-project>/locations/global/keyRings/<mykeyring>/cryptoKeys/sops ENCRYPT_DECRYPT  ENABLED
```
Now you can encrypt a file using
```sh
sops --encrypt --gcp-kms projects/<my-project>/locations/global/keyRings/<mykeyring>/cryptoKeys/sops test.yaml > test.enc.yaml
```
And decrypt it using::
```sh
sops --decrypt test.enc.yaml
```

you can alos specify the gcp-kms key you would like to use by setting the variable `KMS_PATH`
```sh
export KMS_PATH=projects/my-project/locations/global/keyRings/sops/cryptoKeys/sops
```

# Talos

## Create Env File (optional)
an optional env file can be created to store variables that can be subsituted in
the talconfig.yaml on manifest generation

```
touch talenv.sops.yaml
sops -e -i talenv.sops.yaml
```
## Create Talos Secrets

```
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
```

## Create Talos Config
create a talconfig.yaml file following the documentation at https://budimanjojo.github.io/talhelper/latest/

then, generate your configurations
```sh
talhelper genconfig
export TALOSCONFIG=~/k8s-HomeOps/talos/clusterconfig/talosconfig
```

## Boostrap
* load the Talos image onto a usb and boot your device from it
* either statically set ip addresses in the KVM or use DHCP reservations to obtain
  an IP address
* run the bootstrap script
```
./bootstrap.sh
```


## Updates

if you need to make a change to your talos config run `generate.sh` to generate a
new config with your added changes then run `apply.sh` to apply them
