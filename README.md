# home-gitops

## Setup Ubuntu Server

1. Install Ubuntu Server
  
  * `sudo apt update && sudo apt upgrade -y`

2. Set static IP

  * `sudo vi /etc/netplan/99_config.yaml`

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
      gateway4: 192.168.86.1
      nameservers:
          search: [192.168.86.1]
          addresses: [192.168.86.1]
  ```
  
  * `sudo netplan apply`
  
3. Verify network
  
  * `ip a`

4. Set Hostname

  * `sudo hostnamect dmf-rpi-00[1|2|3|4]`
  * `sudo hostnamect "Ubuntu Server RPI microk8s cluster 00[1|2|3|4]" --pretty`

5. Verify hostname
  
  * `sudo hostnamectl`

6. Reboot

### Update ssh config

1. Update ssh config

  ```
  # Ubuntu Server microk8s cluster 001 
  Host dmf-rpi-00[1|2|3|4]
    Preferredauthentications publickey
    HostName 192.168.86.1[6|7|8|9]
    Port 22
    User ubuntu
  ```

### Fix kitty terminal

* `kitty +kitten ssh [server]`

## Setup BackUPS Shutdown

1. Install i2c-tools

  * `sudo apt install i2c-tools python3-smbus`

2. Verify GPIO pins

  * `sudo i2cdetect -y 1`

3. Download and install the scripts

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

4. Verify Safe Software Shutdown

  * `x728off`

5. Setup Realtime Clock module

  * `sudo vi /boot/firmware/config.txt`
  * Add to the end of the file in the `[all]` block

  ```properties
  [all]
  dtoverlay=i2c-rtc,ds1307
  ```

6. Comment out lines 7-12 in `/lib/udev/hwclock-set`

7. Reboot

8. Set the clock

  ```bash
  date
  sudo hwclock -w
  sudo hwclock -r
  ```

## Setup microk8s

1. `sudo snap install microk8s --classic`

2. Setup user permissions

  ```bash
  mkdir ~/.kube
  sudo usermod -a -G microk8s ubuntu
  sudo chown -R ubuntu ~/.kube
  exit
  ```

3. Verify microk8s

  * ssh to server
  * `microk8s status`

4. Setup .kube config

  * `microk8s config >> ~/.kube/config`

5. Setup kubectl

  * `sudo snap install kubectl --classic`

6. Verify kubectl

  * `kubectl get po -A`

7. Setup kubectl bash completion

  * `echo 'source <(kubectl completion bash)' >>~/.bashrc`

8. Setup kubectl aliases

  ```bash
  echo 'alias k=kubectl' >>~/.bash_aliases
  echo 'complete -o default -F __start_kubectl k' >>~/.bash_aliases
  ```
9. Exit

## Install GCloud CLI

1. Install prerequisits

  * `sudo apt install apt-transport-https ca-certificates gnupg curl sudo`

2. Add GCloud Deb Repository

  * `echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list`

3. Add GCloud Deb Repository Public Key to the Keyring

  * `curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -`

4. Update APT

  * `sudo apt update`

5. Install `google-cloud-cli`

  * `sudo apt install google-cloud-cli`

6. Initialize GCloud CLI and set application default

  ```bash
  gcloud init
  gcloud auth application-default login
  ```

## Install Mozilla SOPS

1. Download the binary

  * `curl -LO https://github.com/getsops/sops/releases/download/v3.7.3/sops-v3.7.3.linux.arm64`

2. Move the binary to `/usr/local/bind`

  * `sudo mv sops-v3.7.3.linux.arm64 /usr/local/bin/sops`

3. Make the binary executable

  * `chmod +x /usr/local/bin/sops`

### Install `age`

1. Download the binary

  ```bash
  AGE_VERSION=$(curl -s "https://api.github.com/repos/FiloSottile/age/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
  curl -Lo age.tar.gz "https://github.com/FiloSottile/age/releases/latest/download/age-v${AGE_VERSION}-linux-arm64.tar.gz"
  ```

2. Extract the archive

  * `tar xf age.tar.gz`

3. Install the binaries

  ```bash
  sudo mv age/age /usr/local/bin
  sudo mv age/age-keygen /usr/local/bin
  ```

4. Verify age

  * `age -version`

5. Cleanup download

  ```bash
  rm -rf age.tar.gz
  rm -rf age
  ```

## Install Terraform

1. Install HashiCorp GPG Key

  ```bash
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
  ```

2. Verify the key's fingerprint

  ```bash
  gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
  ```

3. Add the HashiCorp Deb Repository

  ```bash
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  ```

4. Update APT

  * `sudo apt update`

5. Install terraform

  * `sudo apt install terraform`

6. Verify terraform

  * `terraform -help`

7. Enable tab completion

  * `terraform -install-autocomplete`

8. Exit ssh to enable

## Setup home-gitops

1. Clone the repo

  ```bash
  mkdir -p ~/development/dmfrey
  cd ~/development/dmfrey
  git clone git@github.com:dmfrey/home-gitops.git
  ```

2. Setup infrastructure

  ```bash
  cd development/git/dmfrey/home-gitops/infrastructure
  terraform -apply
  ```