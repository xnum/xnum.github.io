---
layout: post
title: golang.org/x/sync/singleflight 用法
categories: golang
---

簡單說當有多個請求同時發起時，它可以讓後面發起的同樣請求，等待第一個請求回來並共用回應。

以HTTP方式來說明的話會是這樣：

```
00:00:01.000 A001 Request GET /exchange_rate
00:00:02.000 A002 Request GET /exchange_rate
00:00:03.000 A003 Request GET /exchange_rate
00:00:04.000 B001 Request GET /exchange_rate
```


如果A001耗時2.1秒，則A002和A003會使用A001的結果，並等待A001回來

而B001則是一個全新的請求

實際使用時可能是這樣

```go
var fsg singleflight.Group

func extractRate(resp *http.Response) (*Rate, error) {}

func GetExchangeRate() (*Rate, error) {
    r, err, _ := fsg.Do("exchange_rate", func() (any, error) {
        resp, err := http.Get("https://....")
        if err != nil {
            return nil, err
        }

        return extractRate(resp)
    })

    if err != nil {
        return nil, err
    }
    return r.(*Rate), nil
}
```

如果可能會超時的話，就要另外呼叫group的Forget()。避免造成一堆request排隊。
