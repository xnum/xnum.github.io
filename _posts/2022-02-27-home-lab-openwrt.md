---
layout: post
title: openwrt gateway設定
date: 2022-02-27 00:01 +0800
categories:
- home_lab
- sys_admin
- networking
---

重新整理了一次網路環境，順便做個紀錄

由於openwrt沒有iso或usb stick install的方式，為求方便改裝了pve後在上面跑openwrt

一般的500/250M寬頻用J1900還是能跑滿速，未來有速度需求再升級硬體解決

## 網段規劃

192.168.1.0/24 中華電信數據機網段，為了能夠access而保留該網段
192.168.1.1 中華電信數據機
192.168.1.2 軟路由WAN interface IP

192.168.2.0/24 家用設備上網網段
192.168.2.254 軟路由

## WAN

新增PPPoE interface之後還要在firewall settings上面歸類到WAN zone，不然封包不會被NAT送出去

WAN用的eth interface設定IP在上面，這樣就能家用設備網段連線到數據機上面改設定

![](/images/posts/homelab/2022_02_27_0001.png)

## OpenVPN

如果加入兩個以上的OpenVPN client會只能啟動其中一個，這是因為有些設定衝突了

如下修改dev名稱以及新增nobind設定可解

```
dev 'tun-bq'
nobind
persist-tun
persist-key
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:AES-256-CBC
data-ciphers-fallback AES-256-CBC
auth SHA256
tls-client
client
resolv-retry infinite
remote 1.1.1.1 1194 udp4
verify-x509-name "BqOVpnCert" name
remote-cert-tls server
explicit-exit-notify
```

然後需要把vpn tunnel interface也加入並且設定firewall zone

![](/images/posts/homelab/2022_02_27_0002.png)

在防火牆的地方把剛才的vpn所屬firewall zone也加進規則裡，並且設定出去前需要NAT

![](/images/posts/homelab/2022_02_27_0003.png)

vpn server會push route過來，所以只有特定內網流量會經過vpn

要小心自己的環境網段不要跟vpn上面push過來的網段重複

## misc

- 設定DHCP server，把NAS等設備新增static leases
- 開啟DNS forwarder功能，讓內網設備可以用hostname連線
- adblock or adguard home
- 檢查是否有service listen on WAN interface，有的話把他關掉
- port forwarding rules
