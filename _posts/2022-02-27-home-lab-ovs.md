---
layout: post
title: 窮人版x86 L2 switch
date: 2022-02-27 00:02 +0800
categories:
- home_lab
- sys_admin
- networking
---

## 預期配置規劃

利用4port 1G網口的J1900做交換器負責處理vlan tagging

eth0: vlan access mode tag 301 cht modem
eth1: vlan access mode tag 302 LAN 後面接無網管功能L2 switch
eth2: vlan trunk mode allowd vlan 301,302
eth3: vlan access mode tag 301 cht MOD

eth1用的是之前買的1G BaseT / 10G SFP+無網管功能switch
這樣子網內交換也可以直接交換不需要送到J1900上

eth2預期拿來做單臂路由孔

## 實作方式

安裝pve，並使用ovs當成虛擬交換機

`apt install openvswitch-switch`

把4個port都塞進同一個ovs bridge

/etc/network/interfaces

```
auto enp2s0
iface enp2s0 inet manual
        ovs_type OVSPort
        ovs_bridge vmbr1
        ovs_options tag=302
#LAN,a302

auto enp1s0
iface enp1s0 inet manual
        ovs_type OVSPort
        ovs_bridge vmbr1
        ovs_options tag=301
#WAN,a301

auto enp3s0
iface enp3s0 inet manual
        ovs_type OVSPort
        ovs_bridge vmbr1

auto enp4s0
iface enp4s0 inet manual
        ovs_type OVSPort
        ovs_bridge vmbr1
        ovs_options tag=301
#MOD,a301


auto vlan0
iface vlan0 inet static
        address 192.168.4.87/24
        ovs_type OVSIntPort
        ovs_bridge vmbr1

auto vlan301
iface vlan301 inet static
        address 192.168.1.2/24
        ovs_type OVSIntPort
        ovs_bridge vmbr1
        ovs_options tag=301
#WAN

auto vlan302
iface vlan302 inet static
        address 192.168.2.1/24
        gateway 192.168.2.254
        ovs_type OVSIntPort
        ovs_bridge vmbr1
        ovs_options tag=302
#LAN

auto vmbr1
iface vmbr1 inet manual
        ovs_type OVSBridge
        ovs_ports enp1s0 enp2s0 enp3s0 enp4s0 vlan0 vlan301 vlan302
```

![](/images/posts/homelab/2022_02_27_0004.png)

偷懶的話也可以直接在pve開一台vm當路由器

