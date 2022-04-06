---
layout: post
title: home lab - calico bgp mode on kubernetes
date: 2022-03-02 00:00 +0800
categories:
- home_lab
- sys_admin
- networking
- k8s
---

## 目標

利用BGP打通kubernetes內外網路流量交換，在cluster外也可以存取到cluster內的服務

ECMP使得流量分散到多台機器上，而不會都經由同一個節點

ingress-nginx的佈建也可以基於metalLB打通而不需要haproxy

## 配置

openwrt-gw => core-sw => kubernetes cluster CIDR

| hostname  | ip             | BGP asn |
|-----------|----------------|---------|
| k8s-node1 | 192.168.5.1    | 65005   |
| k8s-node2 | 192.168.5.2    | 65005   |
| k8s-node3 | 192.168.5.3    | 65005   |
| core-sw   | 192.168.5.254  | 65005   |
|           | 192.168.2.253  |         |
| openwrt-gw| 192.168.2.254  | 65002   |

## L3 router BGP setting

OpenWRT安裝FRR並開啟bgpd，用vtysh配置設定會比較方便

/etc/frr/frr.conf

(core-sw)

```
frr version 7.5
frr defaults traditional
hostname core-sw
log syslog
!
password zebra
!
router bgp 65005
 bgp router-id 192.168.2.253
 no bgp ebgp-requires-policy
 neighbor k8s peer-group
 neighbor k8s remote-as 65005
 neighbor 192.168.5.1 peer-group k8s
 neighbor 192.168.5.2 peer-group k8s
 neighbor 192.168.5.3 peer-group k8s
 neighbor 192.168.5.4 peer-group k8s
 neighbor 192.168.2.254 remote-as external
 !
 address-family ipv4 unicast
  network 192.168.5.0/24
 exit-address-family
!
access-list vty seq 5 permit 127.0.0.0/8
access-list vty seq 10 deny any
!
line vty
 access-class vty
!
```

(gw)

```
frr version 7.5
frr defaults traditional
hostname gw
log syslog
!
password zebra
!
router bgp 65002
 bgp router-id 192.168.2.254
 no bgp ebgp-requires-policy
 neighbor 192.168.2.253 remote-as external
!
access-list vty seq 5 permit 127.0.0.0/8
access-list vty seq 10 deny any
!
line vty
 access-class vty
!
```

## calico setting

需安裝calicoctl進行設定

```
# Global BGP configuration. Disable node-to-node mesh

apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  nodeToNodeMeshEnabled: false
  # node local-as
  asNumber: 65005
  serviceExternalIPs:
    - cidr: 10.222.111.0/24

---
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: my-global-peer
spec:
  peerIP: 192.168.5.254
  # peer remote-as
  asNumber: 65005
```

在Service上面手動新增`externalIPs`，修改為`NodePort`就可以使用該IP連線
如果不想經過SNAT的話就要把externalTrafficPolicy設為Local

```
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  type: NodePort
  externalIPs:
  - 10.222.111.187
  externalTrafficPolicy: Local
  ports:
  - port: 80
  selector:
    app: guestbook
    tier: frontend
```

## metalLB

如果想讓externalIP自動發放，可以安裝metalLB的controller，但不安裝speaker

在apply metalLB的安裝yaml前先移除speaker相關資源設定

並且指定網段，其中的protocol不重要，因為沒有speaker負責

```
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 10.222.111.1-10.222.111.250
```

使用metalLB後需要額外在BGPConfiguration增加對應的設定

```
  serviceLoadBalancerIPs:
    - cidr: 10.222.111.0/24
```

如果只有expose LoadBalancer IP的需要，可以直接安裝metalLB設定成BGP mode
效果是一樣的，config如下

```
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    peers:
    - peer-address: 192.168.5.254
      peer-asn: 65005
      my-asn: 65005
    address-pools:
    - name: default
      protocol: bgp
      addresses:
      - 10.222.111.1-10.222.111.250
```
