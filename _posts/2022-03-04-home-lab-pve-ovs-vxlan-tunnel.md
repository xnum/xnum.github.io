---
layout: post
title: proxmox ve 使用 OVS 搭建異地 overlay network
date: 2022-03-04 00:00 +0800
categories:
- home_lab
- sys_admin
- networking
---

## 目標

- 讓pve上面的ovs可以透過VXLAN tunnel互相連通
- 讓ovs上面的vm可以自己指定不同vlan
- 利用wireguard跨Internet組成虛擬網路

由於ovs只支援stp/rstp，不支援per-vlan rstp或mstp，

因此我們需要拆成服務實體網路和虛擬網路的ovs bridge，避免產生loop，也讓彼此不會互相干擾

可以想像我們的目標就是把每台機器上的ovs bridge互相連在一起，至於要用什麼topology就看網路規劃和規模

在這邊我們先用最簡單的星狀網路來實作

## 配置

三台實體機串在同一台交換器上，彼此可以走192.168.2.0/24互通

- pve1
    - 192.168.2.1/24 vlan tag=302
    - enp3s0: vlan trunk
	- vm1: 192.168.6.101/24 vlan tag=33
- pve2
    - 192.168.2.11/24
    - enp1s0: vlan access 302
	- vm2: 192.168.6.102/24 vlan tag=33
- pve3
    - 192.168.2.12/24
    - enp1s0: vlan access 302
	- vm3: 192.168.6.103/24 vlan tag=33

一台遠端實體機藏在NAT底下

- pve4
	- vm4: 192.168.6.104/24 vlan tag=33

## 本地網路連接設定

以pve1為例，使用vlan302做為LAN流量交換，並把內部管理用的相關port都塞到vmbr1

vmbr9專門服務虛擬網路，他對外連線的port只有vxlan tunnel。為了防止loop我們開啟了RSTP。

```
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

auto vmbr9
iface vmbr9 inet manual
        ovs_type OVSBridge
        ovs_ports vx1 vx2
        up ovs-vsctl set Bridge ${IFACE} rstp_enable=true other_config:rstp-priority=8192 other_config:rstp-forward-delay=4 other_config:rstp-max-age=6
        post-up sleep 10

auto vx1
iface vx1 inet manual
    ovs_type OVSTunnel
    ovs_bridge vmbr9
    ovs_tunnel_type vxlan
    ovs_options trunks=11,22,33
    ovs_tunnel_options options:remote_ip=192.168.2.11 options:key=flow options:dst_port=4790

auto vx2
iface vx2 inet manual
    ovs_type OVSTunnel
    ovs_bridge vmbr9
    ovs_tunnel_type vxlan
    ovs_options trunks=11,22,33
    ovs_tunnel_options options:remote_ip=192.168.2.12 options:key=flow options:dst_port=4790
```

設定完之後使用`ifreload -a`並觀察RSTP有沒有如我們所想的動作

由於RSTP本身就會傳送BPDU封包，所以至少可以看到root switch選舉和port state結果

```
root@pve:/etc/network# ovs-appctl rstp/show
---- vmbr9 ----
Root ID:
  stp-priority    8192
  stp-system-id   9a:50:5e:4e:81:40
  stp-hello-time  2s
  stp-max-age     6s
  stp-fwd-delay   4s
  This bridge is the root

Bridge ID:
  stp-priority    8192
  stp-system-id   9a:50:5e:4e:81:40
  stp-hello-time  2s
  stp-max-age     6s
  stp-fwd-delay   4s

  Interface  Role       State      Cost     Pri.Nbr
  ---------- ---------- ---------- -------- -------
  vx1        Designated Forwarding 200000   128.1
  vx2        Designated Forwarding 200000   128.2
  veth105i0  Designated Forwarding 2000     128.3
```

## 異地ovs設定

這邊我給wireguard一個獨立subnet，但是和LAN擺在同一個zone，就不用再指定防火牆rule，也不需要過NAT

gateway: 192.168.9.1
server: 192.168.2.12
client: 192.168.9.2

首先照著wireguard server的方式架設起來

接著設定client連線

```
[Interface]
#  Client's private key
PrivateKey = xxx
Address = 192.168.9.2/24

[Peer]
# Server's public key
PublicKey = xxx
PresharedKey = xxx
AllowedIPs = 192.168.9.0/24, 192.168.2.0/24
Endpoint = 1.1.1.1:87426
PersistentKeepalive = 20
```

建立連線後client端應該可以看到有流量received和sent (預設有keepalive封包)

```
root@xnum-pve:~# wg
interface: wg0
  public key: 3W+pCsRx0OXNN31sXxcpncITINBpMGrcODZRYdYeaTU=
  private key: (hidden)
  listening port: 43765

peer: DTGBE14w4MpzQhkCH/pxXdBzKiFuuuX2Y7axBTc3zn0=
  preshared key: (hidden)
  endpoint: 1.1.1.1:87426
  allowed ips: 192.168.9.0/24, 192.168.2.0/24
  latest handshake: 38 seconds ago
  transfer: 287.93 KiB received, 165.46 KiB sent
  persistent keepalive: every 20 seconds
```

由於這是一個wireguard tunnel封裝VXLAN tunnel，所以除了IP以外其他設定皆和本地無異

```
auto vx3
iface vx3 inet manual
    ovs_type OVSTunnel
    ovs_bridge vmbr9
    ovs_tunnel_type vxlan
    ovs_options trunks=11,22,33
    ovs_tunnel_options options:remote_ip=192.168.9.2 options:key=flow options:dst_port=4791
```

這樣就可以在ovs bridge上建立vm來測試連線了

從遠端ping回本地

```
vm4:~# ping 192.168.6.103
PING 192.168.6.103 (192.168.6.103): 56 data bytes
64 bytes from 192.168.6.103: seq=0 ttl=64 time=12.350 ms
64 bytes from 192.168.6.103: seq=1 ttl=64 time=3.511 ms
^C
--- 192.168.6.103 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 3.511/7.930/12.350 ms
vm4:~# ping 192.168.6.102
PING 192.168.6.102 (192.168.6.102): 56 data bytes
64 bytes from 192.168.6.102: seq=0 ttl=64 time=5.094 ms
64 bytes from 192.168.6.102: seq=1 ttl=64 time=4.115 ms
^C
--- 192.168.6.102 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 4.115/4.604/5.094 ms
vm4:~# ping 192.168.6.101
PING 192.168.6.101 (192.168.6.101): 56 data bytes
64 bytes from 192.168.6.101: seq=0 ttl=64 time=4.675 ms
64 bytes from 192.168.6.101: seq=1 ttl=64 time=3.906 ms
^C
--- 192.168.6.101 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 3.906/4.290/4.675 ms
```

本地vm互ping

```
vm2:~# ping 192.168.6.101
PING 192.168.6.101 (192.168.6.101): 56 data bytes
64 bytes from 192.168.6.101: seq=0 ttl=64 time=0.098 ms
64 bytes from 192.168.6.101: seq=1 ttl=64 time=0.108 ms
^C
--- 192.168.6.101 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.098/0.103/0.108 ms
vm2:~# ping 192.168.6.102
PING 192.168.6.102 (192.168.6.102): 56 data bytes
64 bytes from 192.168.6.102: seq=0 ttl=64 time=1.065 ms
64 bytes from 192.168.6.102: seq=1 ttl=64 time=0.311 ms
^C
--- 192.168.6.102 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.311/0.688/1.065 ms
vm2:~# ping 192.168.6.103
PING 192.168.6.103 (192.168.6.103): 56 data bytes
64 bytes from 192.168.6.103: seq=0 ttl=64 time=1.107 ms
64 bytes from 192.168.6.103: seq=1 ttl=64 time=0.304 ms
^C
--- 192.168.6.103 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.304/0.705/1.107 ms
```
