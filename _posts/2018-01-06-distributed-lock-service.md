---
layout: post
title: 從分散式鎖服務到master-slave架構
tags:
- 心得
---

在master-slave類型的分散式系統的，一項相當重要的是master選擇和定位

如BigTable的master使用chubby、Hadoop的NameNode使用zookeeper...

共有的特色是透過分散式鎖服務為基礎來建設出master-slave架構

對於這類架構主要關注其

1. 如何選舉
2. master fail detection (假死、腦裂)
3. 狀態同步到master故障前

Hadoop的NameNode採用Active-Standby模式
每個NameNode利用zookeeper選舉
且帶一個Failover Controller報告健康情況
數據同步利用共享儲存系統達成
預防假死採用fencing隔離方式

OS層的主備切換

Linux HA也是一個方式

http://wiki.weithenn.org/cgi-bin/wiki.pl?HA-DRBD_Heartbeat_%E5%BB%BA%E7%BD%AE_MySQL_%E9%AB%98%E5%8F%AF%E7%94%A8%E6%80%A7#Heading19

- 雙向heartbeat檢測健康
- 共享儲存 master 可寫 + slave 同步

似乎是普遍做法
