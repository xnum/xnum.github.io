---
layout: post
title: proxmox ve change node ip in an existing cluster
date: 2022-02-27 00:00 +0800
categories: pve
---

proxmox pve cluster加入node後發現使用的IP interface錯誤

把該node移除重新加入後大部分地方更新為新IP 但`/etc/pve/.members`仍維持舊的

需要修改該node的`/etc/hosts`後於該node執行下面操作

```
systemctl restart corosync.service
systemctl restart pve-cluster.service
systemctl restart pvedaemon.service
systemctl restart pveproxy.service
```
