---
layout: post
title: cache penetration and bloom filter
date: 2018-06-06
tag:
- 筆記
---

緩存擊穿，原文應該是cache penetration

描述當系統遇到大量請求的時候，由於查詢不存在的key

導致cache沒有發生作用，請求直接pass到DB而造成對DB的龐大壓力

比較粗暴的解決方法是讓眾多連線搶一個互斥鎖

以獲得對DB發送請求的權力


一個優雅的解法是使用bloom filter

可以在O(k)時間內查詢一個element是否在一個set內，可以新增但不能刪除element

但可能有很低的誤報率，以為該element存在於set中，事實上並不存在(false positive)

> probably in set or definitely not in set

一般還可以應用在

- 網頁爬蟲：記錄已經爬過的URL
- Mail過濾：判斷某個mail是否屬於spam mail

bloom filter使用bit array來儲存資料

並使用多個hash function來計算

假設array長度為N，function使用2個，分別為MD5、SHA1

將element E加入

```
arr[MD5(E) % N] = 1
arr[SHA1(E) % N] = 1
```

查詢element E是否存在於此Set中

```
return arr[MD5(E) % N] && arr[SHA1(E) % N]
```

長的完全就是HashTable，但value只有0或1，可以極大的節省空間

避免碰撞則是用多個hash function，但N越小，誤判率仍然會隨之增加

