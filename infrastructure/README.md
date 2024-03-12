# Setup  UDM Pro for On Boot Scripts
unfortunetly as of 2023 the UDM Pro still does not support BGP nor does it have a
great MDNS repeater, however we can add these things by utilizing the unifios-utils script, multicast-relay, and FRR.

## install unifios-utilities
The first thing we'll need to do is install something called [UDMPro Boot Script](https://github.com/unifi-utilities/unifios-utilities/tree/main/on-boot-script-2.x). This utility was created by someone who wanted to make some tweaks or changes to their UDMP that would persist through reboots and firmware updates. The utility allows you to place shell scripts under /data/on_boot.d and have them executed at boot time.

Assuming that you have connected via SSH already, you'll need to then drop in to the UniFi OS shell by typing:
```
unifi-os shell
```

The command line prompt should change to root@ubnt:/# at this point. The best approach is to then follow the instructions in the GitHub repository linked above. At the time of writing all that was required was to enter the following:

```
curl -fsL "https://raw.githubusercontent.com/unifi-utilities/unifios-utilities/HEAD/on-boot-script-2.x/remote_install.sh" | /bin/sh
```

* as of 3.x.x the UDM pro does not use podman anymore, there for I will be running both frr and multicast-relay as native services, an alternative is to use nspwan-containers, more information can be found at [https://github.com/unifi-utilities/unifios-utilities/tree/main/nspawn-container](https://github.com/unifi-utilities/unifios-utilities/tree/main/nspawn-container)

# Setup MDNS Relay (Unifi OS 3.x)
```
cd /data
mkdir -p custom/multicast-relay
cd custom/multicast-relay
curl -LJO https://raw.githubusercontent.com/alsmith/multicast-relay/master/multicast-relay.py
```

make a start up script called `/data/on_boot.d/15-multicast-relay.sh`

```15-multicast-relay.sh
#!/bin/sh

# add a br for each vlan you want to repeat mdns messages to
/usr/bin/python3 /data/custom/multicast-relay/multicast-relay.py --interfaces br50 br60 br70 br90
```

```
chmod +x /data/on_boot.d/15-multicast-relay.sh
./15-multicast-relay.sh
```

# Setup BGP (Unifi OS 3.x)
FRR can be directly installed by following the instructions at https://deb.frrouting.org/, however this will not persist when Unifi OS is updated. To work around this, the approach I use is to check whether FRR is installed at every boot. If it is, move on, but if not set it up again.

The configuration for FRR in /etc will persist upgrades, so only needs to be done once.

## Install FRR
create an on boot script called /data/on_boot.d/10-bgp-frr.sh
```10-setup-frr.sh
#!/bin/bash

# If FRR is not installed then install and configure it
if ! command -v /usr/lib/frr/frrinit.sh &> /dev/null; then
    echo "FRR could not be found"
    # Handle release changes
    rm /etc/apt/sources.list.d/frr.list
    curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
    echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable | tee -a /etc/apt/sources.list.d/frr.list

    # Install FRRouting
    apt-get update && apt-get -y install --reinstall frr frr-pythontools
    if [ $? -eq 0 ]; then
        echo "Installation successful, updating configuration"
        # Minimal config, existing will remain in /etc
        echo > /etc/frr/vtysh.conf
        rm /etc/frr/frr.conf
        chown frr:frr /etc/frr/vtysh.conf
    fi
    service frr restart
fi
```

Make it executable and run it to install FRR. Running it a second time should do absolutely nothing.
```
chmod +x /data/on_boot.d/10-bgp-frr.sh
/data/on_boot.d/10-bgp-frr.sh
```

## Configure FRR

Edit the /etc/frr/daemons configuration file, enabling BGP by setting bgpd=yes.

```
sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
```

Make a /etc/frr/bgpd.conf detailing your peer groups and neighbors:
```
! -*- bgp -*-
!
hostname $UDMP_HOSTNAME
password zebra
frr defaults traditional
log file stdout
!
router bgp 65510
 bgp ebgp-requires-policy
 bgp router-id <UDM IP ADDRESS>
 maximum-paths 1
 !
 ! Peer group for K8S
 neighbor K8S peer-group
 neighbor K8S remote-as 65511
 neighbor K8S activate
 neighbor K8S soft-reconfiguration inbound
 neighbor K8S timers 15 45
 neighbor K8S timers connect 15
 !
 ! Neighbors for K8S
 neighbor <K8S NODE 1> peer-group K8S
 neighbor <K8S NODE 2> peer-group K8S
 neighbor <K8S NODE 3> peer-group K8S
 !

 address-family ipv4 unicast
  redistribute connected
  !
  neighbor K8S activate
  neighbor K8S route-map ALLOW-ALL in
  neighbor K8S route-map ALLOW-ALL out
  neighbor K8S next-hop-self
  !
 exit-address-family
 !
route-map ALLOW-ALL permit 10
!
line vty
!
```

replace the `<UDM IP ADDRESS>` and `< K8s NODE * >` with your info

Set ownership of bgpd.conf, and restart FRR.
```
chown frr:frr /etc/frr/bgpd.conf
service frr restart
```

Verify that the BGP neighbors are up using `vtysh -c 'show ip bgp'`.
