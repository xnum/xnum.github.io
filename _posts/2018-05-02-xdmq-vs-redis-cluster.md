---
layout: post
title: xdmq和redis cluster的特性比較
tags:
- 心得
---

前陣子被問到為什麼不用redis來取代xdmq，在實作xdmq前我認為redis的角色屬於cache，較未詳細研究其底層理論。

我覺得這是一個蠻好的切入點來研究redis cluster的特性，究竟他和xdmq有什麼差異存在?

由於xdmq事實上利用了raft達到需要的功能，因此部分的比較會直接用raft當作對象。

由於單機佈署redis無法達成高可用性，因此這邊的比較會基於redis cluster。

## replication

redis cluster是async replica

raft是sync replica (log在commit後才是可用的)

## data sharding

在xdmq中直接基於raft實作message queue，所以其資料事實上是沒有sharding的，可以說是full replication

在redis中透過`CRC16(key) % 16384`作sharding

## availability

由於redis採用master-slave架構

當master和slave同時死亡時可能造成cluster不可用

當master資料未完全同步到slave就死亡時，可能造成資料遺失 (資料複製是async write)

不可用和任何資料遺失在xdmq中都是要極力避免發生的問題

## consistency

redis cluster並不保證強一致性，相對的xdmq的底層raft保證強一致性

## performance

redis cluster由於data sharding的緣故可以達到較高的彈性與可擴充性

相對的raft的效能瓶頸很可能發生在write，其架構中leader工作是最繁重的

## network topology

redis cluster和xdmq的連線架構是一樣的，每個node都會連線到其他所有node

但redis之間透過gossip協議了解其他node是否存活

raft則只關心和leader的連線狀態

## caching

redis cluster本質是in-memory key-value store

一旦需要儲存的資料超過記憶體限制，根據設定的policy不同

可能會回傳error或是刪除一些資料 (LRU)

而raft是不會殺舊資料的，全都在log裡

## persistence

redis分為RDB和AOF兩種

RDB是一段時間建立一次snapshot

AOF則是對每個write operation都做記錄，之後可以用來rebuild

在xdmq中是開啟一個mmap file作為寫log的方式

長到一個程度就會滿了，實際上應該要搭配log compaction
