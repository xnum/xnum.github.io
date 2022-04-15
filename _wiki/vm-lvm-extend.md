---
layout: wiki
title: vm disk 的 lvm extend size
cate1:
cate2:
description: 
keywords: vm, lvm
type:
link:
---

首先在 host 上面把虛擬硬碟的大小先擴充完畢

```
 pvdisplay
 pvresize /dev/sda3
 lvextend -l +90%FREE /dev/ubuntu-vg/ubuntu-lv
 resize2fs /dev/ubuntu-vg/ubuntu-lv
 df -h
 lvdisplay
```

pv 要先 resize 抓到新的大小，再指派空間給 lv，最後把 fs 的大小修正過來
