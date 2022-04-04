---
layout: post
title: prometheus mysqld exporter 配置實驗記錄
date: 2020-03-27 13:57 +0800
categories:
- DB
---

based on percona:5.7 docker image

使用場景：

- client connections ~= 10
- deadlock is critical
- rows in a table ~= 100K
- low query latency
- minimum slave lag
- localhost: no network issue
- total DB size ~= 100MB

mysqld_exporter有很多選項可以開開關關

```
  mysqld-exporter:
    image: prom/mysqld-exporter
    restart: always
    environment:
      DATA_SOURCE_NAME: "exporter:1qaz@(127.0.0.1:33306)/"
    command:
      - '--web.listen-address=:39104'
      - '--collect.info_schema.innodb_metrics'
      - '--collect.info_schema.processlist'
      - '--no-collect.info_schema.innodb_cmp'
      - '--no-collect.info_schema.innodb_cmpmem'
      - '--no-collect.info_schema.query_response_time'
```

踩坑之一

`mysql_global_status_innodb_deadlocks` 在某些鄉野rules中出現，但是死活找不到

解法： 打開collect.info_schema.innodb_metrics

改拿 `mysql_info_schema_innodb_metrics_lock_lock_deadlocks_total`

踩坑之二

監控slave的metric

`mysql_slave_status_seconds_behind_master` `mysql_slave_status_sql_delay`

要從slave蒐集才拿的到，master不會有

據說某些case，behind_master不會發現異常，加個log position比對。

`mysql_slave_status_exec_master_log_pos-mysql_slave_status_read_master_log_pos`
