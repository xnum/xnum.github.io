---
layout: post
title: docker-compose networking alias的坑
date: 2020-07-31 21:05 +0800
categories:
- Docker
---

現在docker-compose已經不鼓勵使用links的方式來作為container之間name resolving的管道

另外links也無法雙向link，會造成環狀引用

比較推薦的寫法是使用user-defined bridge，用container name或aliases向dns查詢

```
version: '3.7'

networks:
  internal:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16

services:
  be1:
    restart: always
    image: alpine:latest
    networks:
      internal:
        aliases:
          - be1
```

```
docker exec -it iptest_be1_1 nslookup be1.
```

有時候我們想要將某個session的資料，送往某個特定的container來達成affinity

但在container重開後internal network ip就有可能變動

這時候如果內部有dns cache就會發送到錯誤的container上

比較workaround的解法是為每個container手動指定static ip
