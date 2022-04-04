---
layout: post
title: mysql dead lock排除記
date: 2019-12-25 00:53 +0800
categories:
- DB
---

一開發中程式進行測試時跳出 `dead lock detected` 字眼，發生在 `INSERT INTO ...`。

直接殺進MySQL下指令 `SHOW ENGINE INNODB STATUS`。

發現衝突的另外一個transaction已經grant gap lock。使用了`SELECT ... FOR UPDATE`。

因為SELECT語句的WHERE條件，gap lock range使row level lock退化成table level lock。

似乎在WHERE裡用到non-indexed column就會造成table lock (need reference)。

解決方法：經思考phantom read不影響程式邏輯後，降級isolation level為READ COMMITTED。
