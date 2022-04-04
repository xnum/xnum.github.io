---
layout: post
title: boost fiber library 特性筆記
date: 2019-08-12 15:39 +0800
categories:
- C/C++
---

fiber是boost內的coroutine library，眾所皆知的coroutine比thread更輕量快速，但也有一些特性和thread相異。

### 不可搶占

coroutine執行中沒有讓出執行權的話，其他coroutine都會被暫停，這個沒有讓出執行權包含用了std或posix裡的mutex,cv機制導致thread陷入等待。

解法是用fiber實作的mutex,cv版本，但是對付legacy code要四處改有點麻煩..所以也可以開個thread給他自己慢慢卡，雖然這樣的解法有點蠢。

### 排程

coroutine的scheduling有些限制，並不是所有coroutine都會被scheduling到其他thread執行。

這和該coroutine的context type有關係。簡單說只有呼叫了detach()的coroutine才能被切到其他thread執行。

儘管用了work stealing演算法還是無法避免這個限制，所以coroutine太少的情況下會看到thread pool使用率不佳。

### latency (還不太確定)

在強調處理速度的情況下，使用buffered_channel的latency反而比較高而且顯得不穩定。

估計是排程時不會馬上從producer切換給consumer..肉眼觀察數據，沒有特別跑實驗。

## 跟golang做個比較

goroutine是runtime原生支援，不會發生進入syscall或posix mutex就卡住的問題。

在c++裡沒有辦法觀察每條coroutine的狀態和callstack。
