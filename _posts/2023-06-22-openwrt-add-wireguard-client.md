---
layout: post
title: OpenWRT 新增 WireGuard 用戶端操作方式
categories: Home_lab
---

## Install WireGuard client

1. 安裝用戶端軟體
2. 啟動後點擊 + > Add Empty Tunnel...
3. 他會自動產生一組key 名稱可以寫 My sweet house
4. 先儲存，等等回來編輯後續設定

## Setup WireGuard server

1. 登入OpenWRT管理介面
2. 假設已經安裝好WireGuard service
3. Network > Interfaces > 找到 wg0 interface 並點編輯
4. 選擇 Peers 分頁 > Add Peer
5. 填寫欄位
  - Description: 描述用戶端是誰，例如：laptop
  - Public key: 剛剛在用戶端自動產生了一個Private Key，上面有寫對應的Public Key，複製過來這邊貼上
  - Preshared Key: 可填可不填，要填的話就用online tools產生或執行`wg genpsk`
  - Allowed IPs: 你希望這個用戶端使用的IP，例如：192.168.187.95/32
  - Route Allowed IPs: 基本上就打勾
  - Endpoint Host: 留空白
  - Endpoint Port: 留空白
  - PersistentKeepalive: 我都填20，也可以不填
6. Restart wg0 Interface

## Setup WireGuard client

回到用戶端把剛剛的設定補進去

```
[Interface]
PrivateKey = (不需要動)
Address = 192.168.187.95/24
DNS = 1.1.1.1

[Peer]
PublicKey = (從server的這邊複製 OpenWRT > Status > WireGuard > Configuration > Public Key)
PresharedKey = (剛剛有產生Preshared key的話就是填這邊)
AllowedIPs = 192.168.187.0/24 (希望哪些流量走VPN，全部就寫0.0.0.0/0, ::/0)
Endpoint = (你的IP或host):(listen port)
PersistentKeepalive = 20
```

接著就可以嘗試連線了

正常情況可以看到RX和TX都有流量，ping gateway (server在wg0的IP)也會有回應。
