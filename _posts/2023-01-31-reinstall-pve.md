---
layout: post
title: 遠端重灌伺服器，安裝成PVE
categories: [pve]
---

之前的設定是vlan access mode，如果要改成vlan trunk mode又沒有紀錄伺服器是接到哪個port，可以看port channel狀態，因為之前有設定bonding，一旦離線的話port channel就會變成down。

ethernet、switchport應該也可以如法炮製，或是看arp紀錄，這邊因為switch在該vlan沒有IP，所以看不到arp紀錄。

```
# switch config
do show interface port-channel summary

interface po 42
description pve01
switchport mode trunk
switchport trunk allowed vlan 1,2,3,4,5
switchport access vlan 1234
```

接著進pve改網路設定，主要是把bonding設定上去，以及一個IP可以上網更新。

```
iface eno1np0 inet manual

iface eno2np1 inet manual

auto bond0
iface bond0 inet manual
    bond-slaves eno1np0 eno2np1
    bond-miimon 1500
    bond-mode 802.3ad
    bond-xmit-hash-policy layer2

auto bond0.1080
iface bond0.1080 inet manual

auto bond0.1098
iface bond0.1098 inet manual

auto vmbr1080
iface vmbr1080 inet static
        address 192.168.80.1/24
        gateway 192.168.80.254
        bridge-ports bond0.1080
        bridge-stp off
        bridge-fd 0

auto vmbr1098
iface vmbr1098 inet static
        address 198.168.98.1/24
        gateway 198.168.98.254
        bridge-ports bond0.1098
        bridge-stp off
        bridge-fd 0
```

順手把 /etc/apt/sources.list.d/pve-enterprise.list 修改成no-subscription

```
deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
```
