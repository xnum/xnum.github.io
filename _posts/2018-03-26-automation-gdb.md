---
layout: post
title: script控制gdb自動執行指令
categories:
- dev
---

原本在做網路斷線測試

為了模擬異常狀況，要從外部把fd關掉

查了一下，沒辦法從`/proc`下手

於是用gdb來做。但手動打指令速度太慢，無法進入我想要的程式流程

所幸gdb可以吃script自動執行

先寫個文字檔..

```
p close(11)
detach
quit

```

然後執行指令

```
gdb attach 24803 --command=test.gdb
```

順利出現

```
13:48:33   ERR|tcp.c   :  50 handle_hb_pack # error = bad file descriptor  
```
