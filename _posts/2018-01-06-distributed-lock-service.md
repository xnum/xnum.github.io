---
layout: post
title: 從分散式鎖服務到master-slave架構
categories:
- 心得
---

在master-slave類型的分散式系統的，一項相當重要的是master選擇和定位

如BigTable的master使用chubby、Hadoop的NameNode使用zookeeper...

共有的特色是透過分散式鎖服務為基礎來建設出master-slave架構

對於這類架構主要關注其

1. 如何選舉
2. master fail detection (假死、腦裂)
3. 狀態同步到master故障前

# lock service

比如chubby，當多個伺服器要競爭master時，實際上是去搶佔一個文件的擁有權，解決了選舉問題

為甚麼不直接使用chubby內部的一致性演算法而要使用lock service，實際上為了便於開發人員的理解性

每個開發人員不一定接觸或了解一致性演算法，卻大多使用過鎖

而zookeeper：

```
Namenode(包括 YARN ResourceManager) 的主备选举是通过 ActiveStandbyElector 来完成的，ActiveStandbyElector 主要是利用了 Zookeeper 的写一致性和临时节点机制
```

raft consensus algorithm裡面也包含一個選舉的部分，大多數卻不直接拿來作為指派master用，大概也是同理

這樣就更能理解raft之於LogCabin的用處了

(為甚麼LogCabin以文件系統的方式體現? etcd作為key-value store是如何作為共享配置、服務發現使用)

https://github.com/logcabin/logcabin

https://logcabin.github.io/talk/#/

# Hadoop

https://www.ibm.com/developerworks/cn/opensource/os-cn-hadoop-name-node/index.html

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
