---
layout: post
title: 執行Golang的官方原始碼benchmark
date: 2021-07-23 00:00 +0800
categories: golang
---

測試機器性能時可以使用(當然要自己建出對照組數據庫)。

安裝Golang以後切到他的src資料夾執行命令

```
go test -run=none -bench=. -count=10 ./... 2>&1 | tee ~/go-bench.txt
```

有的benchmark會timeout，自行斟酌放寬。

跑完後使用`benchstat`或`benchcmp`做比較。

W-2275上約耗時六小時左右 (單核不平行執行)
