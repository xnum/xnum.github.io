---
layout: post
title: node exporter的時間同步檢查機制
date: 2021-10-07 00:00 +0800
categories: UNIX
---

前兩天國內的NTP server群突然全體無法連線，導致k8s cluster集體報錯。

prometheus rule是

<!-- {% raw %} -->
```
name: HostClockNotSynchronising
expr: min_over_time(node_timex_sync_status[1m]) == 0 and node_timex_maxerror_seconds >= 16
for: 2m
labels:
  severity: warning
annotations:
  description: Clock not synchronising.
    VALUE = {{ $value }}
    LABELS = {{ $labels }}
  summary: Host clock not synchronising (instance {{ $labels.instance }})
```
<!-- {% endraw %} -->

由node exporter提供 [timex.go](https://github.com/prometheus/node_exporter/blob/master/collector/timex.go)

實作是call了linux上的adjtimex

[go package](https://pkg.go.dev/golang.org/x/sys/unix#Adjtimex)
[c function](https://man7.org/linux/man-pages/man2/adjtimex.2.html)

用來檢查ntp daemon是否和server保持同步

在systemd的系統上是systemd-timesyncd管理

解決方法：如果不緊急的話等待server復原，或是主動更換ntp server pool address
