---
layout: post
title: ngrok personal plan  的 OAuth user 上限
categories: [sys_admin]
keywords: ngrok
---

最近需要開一個服務給外面的使用者連線，需求大概是：

- 不開防火牆和port forwarding
- 可以認證使用者

一開始嘗試的是cloudflare zero trust tunnel，但整組架好以後發現會繞到美國去，導致延遲有300ms，對遠端操作不太友善。

試了幾個鄉野偏方都無法解決問題以後，把目光放到了ngrok身上。

ngrok有內建的oauth機制可以辨識使用者，而personal plan在網頁上寫最多可以使用50 MAUs。

購買他的付費方案主要是為了user上限跟自訂domain，不過我覺得有點小貴就是了，幾乎鎖死只能用一個tunnel、提供一個domain的服務。

在ngrok config裡面設定了使用google oauth和email list就可以加上oauth認證，寫法大概是：

```
version: 2
authtoken: XXX
tunnels:
  my_tunnel_name:
    oauth:
      provider: google
      allow_emails:
        - xxx@gmail.com
        - yyy@gmail.com
        - zzz@gmail.com
        - ...
```

結果漂亮的得到錯誤如下：

```
Failed to start tunnel: You may not authorize more than 5 emails. Got 9.
ERR_NGROK_366
```

問客服以後確定是一個bug，目前可以暫時用ngrok edge設定最多20個email。如果從terminal啟動的話最多就只能5個email。

設定方式大概是從網站管理介面手動新增一個edge，並且設定好相關內容以後，在client端用以下方式啟動：

```
version: 2
authtoken: XXX
tunnels:
  my_tunnel_name:
    labels:
      - edge=YYY
    addr: https://localhost:8000
```


