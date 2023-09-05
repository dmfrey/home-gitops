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
  
  *Verify network*
  * `ip a`

3. Set Hostname

  * `sudo hostnamect dmf-rpi-00[1|2|3|4]`
  * `sudo hostnamect "Ubuntu Server RPI microk8s cluster 00[1|2|3|4]" --pretty`

  *Verify hostname*
  * `sudo hostnamectl`

4. Reboot

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

## Setup microk8s

1. `sudo snap install microk8s --classic`

2. Setup user permissions

  ```bash
  mkdir ~/.kube
  sudo usermod -a -G microk8s ubuntu
  sudo chown -R ubuntu ~/.kube
  exit
  ```

  *Verify microk8s*

  * ssh to server
  * `microk8s status`

3. Setup .kube config

  * `microk8s config >> ~/.kube/config`

4. Setup kubectl

  * `sudo snap install kubectl --classic`

  *Verify kubectl*

  * `kubectl get po -A`

5. Setup kubectl bash completion

  * `echo 'source <(kubectl completion bash)' >>~/.bashrc`

6. Setup kubectl aliases

  ```bash
  echo 'alias k=kubectl' >>~/.bash_aliases
  echo 'complete -o default -F __start_kubectl k' >>~/.bash_aliases
  ```
7. Exit

