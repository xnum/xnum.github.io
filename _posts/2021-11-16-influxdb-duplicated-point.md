---
layout: post
title: influxdb 資料數值重複踩坑
date: 2021-11-16 00:00 +0800
categories: DB
---

在用influxdb紀錄時序資料時發現會有缺漏的現象，看了一下client lib確認沒有漏送

後來發現influxdb有個特性是(timestamp, tag)一模一樣的資料會被覆寫

所以寫入的資料如果timestamp相同就只會留下最後一筆

由於資料的時間精確度只到ms，所以這邊就用了一個取巧的方法：幫timestamp + 1ns

直到找到unique的timestamp為止，使用偷懶的`map[int64]`實作搭配每分鐘清空一次map

如果對效能有要求也可以換成bitset，不過這邊只有每秒200個point內的寫入需求而已就不做太多了

要小心的是如果measurement的時間精度設定必須是us或ns等級，如果設定成ms或s依然會被蓋掉

這時也可以改成多一個tag來讓他變成unique，但是估計對效能會有影響

最後一種方法就是在client端先對資料進行壓縮處理，把相同timestamp的數值merge起來

不過這就要依據數值的特性去做處理了
