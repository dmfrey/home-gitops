# home-gitops

## Setup Ubuntu Server

1. Install Ubuntu Server
  
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

1. Set static IP

    ```bash
    sudo vi /etc/netplan/99_config.yaml
    ```

    ```yaml
    network:
      version: 2
      renderer: networkd
      ethernets:
        eth0:
          dhcp4: no
          dhcp6: no
          addresses:
            - 192.168.86.[16|17|18|19]/24
          routes:
            - to: default
              via: 192.168.86.1
          nameservers:
            search: [192.168.86.1]
            addresses: [192.168.86.1]
    ```
  
   * `sudo netplan apply`
  
1. Verify network
  
    ```bash
    ip a
    ```

1. Set Hostname

    ```bash
    sudo hostnamectl set-hostname dmf-rpi-00[1|2|3|4]
    sudo hostnamectl set-hostname "Ubuntu Server RPI microk8s cluster 00[1|2|3|4]" --pretty
    ```

1. Verify hostname

    ```bash
    sudo hostnamectl
    ```

1. Install `nfs-common`

    ```bash
    sudo apt install nfs-common
    ```

1. Install `linux-modules-extra` **(needed kernel modules for rook-ceph on rpi)**

    ```bash
    sudo apt install linux-modules-extra-$(uname -r)
    ```

1. Disable IPv6

    ```bash
    sudo vi /etc/sysctl.conf
    ```

    Add this property to the end of the file
    ```properties
    net.ipv6.conf.all.disable_ipv6 = 1
    ```
    Save the file and execute:
    ```bash
    sudo sysctl -p
    ```

1. Reboot

### Update `/etc/hosts`

1. Add entry for each node

    * `192.168.86.1[6|7|8|9] dmf-rpi-00[1|2|3|4]`

### Setup SWAP space

1. Create a `swapfile`

    ```bash
    sudo fallocate -l 6G /swapfile
    ```

1. Verify `swapfile`

    ```bash
    ls -lh /swapfile
    ```

1. Enable SWAP

    ```bash
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    ```

1. Verify SWAP enabled

    ```bash
    sudo swapon --show
    free -h
    ```

1. Add SWAP to `/etc/fstab`

    ```bash
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    ```

1. Adjust swappiness

    ```bash
    sudo vi /etc/sysctl.conf
    ```

    Add to the end of the file:
    ```properties
    vm.swappiness=10
    ```

1. Adjust Cache Pressure

    ```bash
    sudo vi /etc/sysctl.conf
    ```

    Add to the end of the file:
    ```properties
    vm.vfs_cache_pressure=50
    ```

## Update ssh config

1. Update ssh config

    ```config
    # Ubuntu Server microk8s cluster 001 
    Host dmf-rpi-00[1|2|3|4]
      Preferredauthentications publickey
      HostName 192.168.86.1[6|7|8|9]
      Port 22
      User ubuntu
    ```

## Fix kitty terminal

```bash
kitty +kitten ssh [server]
```

## Setup BackUPS Shutdown

1. Install i2c-tools

    ```bash
    sudo apt install i2c-tools python3-smbus
    ```

1. Verify GPIO pins

    ```bash
    sudo i2cdetect -y 1
    ```

1. Download and install the scripts

    ```bash
    mkdir -p development/git/geekworm-com
    cd development/git/geekworm-com
    git clone https://github.com/geekworm-com/x728-script
    cd x728-script
    chmod +x *.sh
    sudo cp -f ./x728-pwr.sh /usr/local/bin/
    sudo cp -f x728-pwr.service /lib/systemd/system
    sudo systemctl daemon-reload
    sudo systemctl enable x728-pwr
    sudo systemctl start x728-pwr
    sudo cp -f ./x728-v2.x-softsd.sh /usr/local/bin/x728-softsd.sh
    echo "alias x728off='sudo /usr/local/bin/x728-softsd.sh'" >>   ~/.bash_aliases
    ```

1. Verify Safe Software Shutdown

    ```bash
    x728off
    ```

1. Setup Realtime Clock module

    ```bash
    sudo vi /boot/firmware/config.txt
    ```

   Add to the end of the file in the `[all]` block

    ```properties
    [all]
    dtoverlay=i2c-rtc,ds1307
    ```

1. Comment out lines 7-12 in `/lib/udev/hwclock-set`

    ```bash
    sudo vi /lib/udev/hwclock-set
    ```

1. Reboot

1. Set the clock

    ```bash
    date
    sudo hwclock -w
    sudo hwclock -r
    ```

## Setup microk8s

1. Install microk8s with snap

    ```bash
    sudo snap install microk8s --classic
    ```

1. Setup user permissions

    ```bash
    mkdir ~/.kube
    sudo usermod -a -G microk8s ubuntu
    sudo chown -R ubuntu ~/.kube
    exit
    ```

1. Verify microk8s

    ```bash
    microk8s status
    ```

1. Enable host-storage

    ```bash
    microk8s enable host-storage
    ```

1. Setup .kube config

    ```bash
    microk8s config >> ~/.kube/config
    ```

1. Setup kubectl

    ```bash
    sudo snap install kubectl --classic
    ```

1. Verify kubectl

    ```bash
    kubectl get po -A
    ```

1. Setup kubectl bash completion

    ```bash
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    ```

1. Setup kubectl aliases

    ```bash
    echo 'alias k=kubectl' >>~/.bash_aliases
    echo 'complete -o default -F __start_kubectl k' >>~/.bash_aliases
    ```

1. Exit

### Add a node to cluster

1. On the main node get the join command

    ```bash
    microk8s add-node
    ```

1. Copy the `join` command

1. On the new node, paste the command and execute it

## Install GCloud CLI

1. Install prerequisits

    ```bash
    sudo apt install apt-transport-https ca-certificates gnupg curl sudo
    ```

1. Add GCloud Deb Repository

    ```bash
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    ```

1. Add GCloud Deb Repository Public Key to the Keyring

    ```bash
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    ```

1. Update APT

    ```bash
    sudo apt update
    ```

1. Install `google-cloud-cli`

    ```bash
    sudo apt install google-cloud-cli
    ```

1. Initialize GCloud CLI and set application default

    ```bash
    gcloud init
    gcloud auth application-default login
    ```

## Install Mozilla SOPS

1. Download the binary

    ```bash
    curl -LO https://github.com/getsops/sops/releases/download/v3.7.3/sops-v3.7.3.linux.arm64
    ```

1. Move the binary to `/usr/local/bin`

    ```bash
    sudo mv sops-v3.7.3.linux.arm64 /usr/local/bin/sops
    ```

1. Make the binary executable

    ```bash
    chmod +x /usr/local/bin/sops
    ```

### Install `age`

1. Download the binary

    ```bash
    AGE_VERSION=$(curl -s "https://api.github.com/repos/FiloSottile/age/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    curl -Lo age.tar.gz "https://github.com/FiloSottile/age/releases/latest/download/age-v${AGE_VERSION}-linux-arm64.tar.gz"
    ```

1. Extract the archive

    ```bash
    tar xf age.tar.gz
    ```

1. Install the binaries

    ```bash
    sudo mv age/age /usr/local/bin
    sudo mv age/age-keygen /usr/local/bin
    ```

1. Verify age

    ```bash
    age -version
    ```

1. Cleanup download

    ```bash
    rm -rf age.tar.gz
    rm -rf age
    ```

## Install Terraform

1. Install HashiCorp GPG Key

    ```bash
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    ```

1. Verify the key's fingerprint

    ```bash
    gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
    ```

1. Add the HashiCorp Deb Repository

    ```bash
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    ```

1. Update APT

    ```bash
    sudo apt update
    ```

1. Install terraform

    ```bash
    sudo apt install terraform
    ```

1. Verify terraform

    ```bash
    terraform -help
    ```

1. Enable tab completion

    ```bash
    terraform -install-autocomplete
    ```

1. Exit ssh to enable

## Setup home-gitops

1. Clone the repo

    ```bash
    mkdir -p ~/development/git/dmfrey
    cd ~/development/git/dmfrey
    git clone git@github.com:dmfrey/home-gitops.git
    ```

1. Setup infrastructure

    ```bash
    terraform init
    cd home-gitops/infrastructure
    terraform apply
    ```
