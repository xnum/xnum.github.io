---
layout: post
title: golang pprof
date: 2020-06-09 10:48 +0800
categories: golang
---

in target program

```
import _ "net/http/pprof"

log.Println(http.ListenAndServe(":6060", nil))
```

web ui
```
$ go tool pprof -http=0.0.0.0:6544 http://localhost:6060/debug/pprof/profile\?seconds\=15
```
