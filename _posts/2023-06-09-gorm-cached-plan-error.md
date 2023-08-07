---
layout: post
title: gorm 使用 postgresql driver 遇到 cached plan must not change result type 錯誤
categories: [golang]
description: 
keywords: 
---

使用 gorm 連接 PostgreSQL 時，有時候會遇到 "cached plan must not change result type (SQLSTATE 0A000)" 的錯誤。

這個錯誤通常發生在執行相同的查詢但該表已經修改了Schema造成。

gorm 的 PostgreSQL driver 是來自 [jackc/pgx](https://github.com/jackc/pgx)。

他預設開啟了 prepared statement cache，由於我們找不到任何由 gorm 提供能主動控制 cache 的方法，因此在這邊選擇關掉這項功能：

```
-               return postgres.Open(dsn)
+               return postgres.New(postgres.Config{DSN: dsn, PreferSimpleProtocol: true})
```

更進一步的我們可以只在 migration process 將其設定為 true，並在 deploy 過程中重啟所有會連接資料庫的服務。
