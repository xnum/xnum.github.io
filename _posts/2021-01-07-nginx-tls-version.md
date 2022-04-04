---
layout: post
title: nginx reverse proxy 的 TLS 版本限制問題
date: 2021-01-07 18:15 +0800
categories: sys_admin
---

平常公司的大多數服務都由一個nginx負責reverse proxy，用server hostname決定upstream


今天新增一個網域後開始陸續發現 GitLab CI Bot 離線、docker 無法 pull

docker pull

```
colo-stage /home/jun # docker pull cirple.tw/abcd
Using default tag: latest
Error response from daemon: Get https://cirple.tw/v2/: remote error: tls: protocol version not supported
```

gitlab runner
```
status=couldn't execute POST against https://git.skymirror.com.tw/api/v4/jobs/request: Post https://git.skymirror.com.tw/api/v4/jobs/request: remote error: tls: protocol version not supported
```

curl

```
curl -I -v --tlsv1.2 --tls-max 1.2 https://git.skymirror.com.tw
curl: (35) error:14077102:SSL routines:SSL23_GET_SERVER_HELLO:unsupported protocol
```

直接打內部IP進行測試

```
openssl s_client -tls1_2 --connect 10.168.100.1:443
140473486595392:error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:../ssl/record/rec_layer_s3.c:1543:SSL alert number 70
```

如果使用TLSv1.3則可以正常執行，推測是nginx拒絕了TLSv1.2以下的交握

首先針對了 git.skymirror.com.tw 進行 debug，在nginx的conf裡面

加上v1.2

```
server {
  ...
  ssl_protocols TLSv1.2 TLSv1.3;
}
```

但是nginx依然沒有反應，估計沒有作用

靈機一動移除掉今天加入的domain conf，就可以順利運作了

原因出在 nginx 的 conf parsing 只會對第一個出現的 ssl_protocols 選項生效

所以後面再出現的話都沒有作用，然而今天加入的domain剛好排在alphanumeric order第一位

所以蓋掉了後面的設定，讓 nginx TLS module被限制在v1.3

解法：找到第一個在 server {} 內的 ssl_protocols 加入允許的 protocol

如果設在 http {} 同樣沒有作用
