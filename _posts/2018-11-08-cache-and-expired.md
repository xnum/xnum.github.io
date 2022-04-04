---
layout: post
title: web架構下cache和expire機制的思路整理
date: 2018-11-08 23:58 +0800
categories:
- 筆記
---

在web架構中常會用到cache，例如redis、memcached來存放經常存取的資料，減輕對db的讀寫壓力。

在使用cache時要考慮到資料的特性適不適合放進去：

- 如果cache和db的資料不一致是否會產生衝突
- 放進cache的資料是否可忍受非預期的遺失
- 在沒有cache的情況下會不會對業務邏輯造成影響或崩潰

適合放進cache的資料中，一個經常使用的架構是caching lookaside pattern：存取資料時先看cache中有沒有資料，沒有的時候就往db查詢，並在查詢結果回傳前(或後)寫回到cache中。當cache壞掉時系統fallback到由db提供服務的狀態。

一個簡單的虛擬碼如下：

```go
func Load(key int) int {
    val, success := LoadFromCache(key)
    if success {
        return val
    }

    val := LoadFromDB(key)
    StoreToCache(key, val)
    return val
}
```

在實際的使用場景中，我們有時候需要提供一個服務，性質類似一個CDN：為了要減輕後台的運算壓力，要將後台的資料進行caching。cache miss或每隔一段時間都往後台重新抓取一份新資料並蓋過舊值。使用者可以接受讀取到舊值，但要避免大量查詢衝向cache或db讓後台的服務癱瘓。

只考慮定時更新資料，假設服務都正常運作的情況下，將每次更新的時間都同樣寫入cache，並用此判斷是否應該更新。

```go
func EnsureUpToDate(key int) {
    const period = 10 * time.Second
    timestamp := LoadTimestampFromCache(key)
    if time.Now() > timestamp + period {
        val := LoadFromDB(key)
        StoreToCache(key, val)
        StoreTimestampToCache(key, time.Now())
    }
}

func LoadWithUpdate(key int) int {
    EnsureUpToDate(key)
    return Load(key)
}
```

而實際上更新時還要搭配distributed lock來防止有大量request同時去更新這份資料，詳細的實作方式可以參考[redis topic](https://redis.io/topics/distlock)。加上lock之後由於我們的服務是使用者可以接受舊值的，所以在搶lock失敗後，不需要等待，直接回傳舊值即可。


```go
func EnsureUpToDateWithLock(key int) int {
    grant := TryLock(key)
    if grant {
        EnsureUpToDate(key)
        Unlock(key)
    }
}
```

接下來則是考量到後台服務暫時不可用的狀況：我們可以修改將寫入的timestamp來增加cache的更新頻率，避免流量持續湧向後台，或是更新間隔過長，導致服務恢復後無法即時更新資料。

```go
func EnsureUpToDate(key int) {
    const period = 10 * time.Second
    timestamp := LoadTimestampFromCache(key)
    if time.Now() > timestamp + period {
        val, ok := LoadFromDB(key)
        if ok {
            StoreToCache(key, val)
        } else {
            StoreTimestampToCache(key, time.Now() - period / 2)
        }
    }
}
```

最後則是在本地也建立一份cache，避免每次都向redis詢問，這個更新頻率可以設定得更短，一個粗淺的示範版本：

```go
type LocalCache struct {
    val int
    mtx sync.RWMutex
}

func New() *LocalCache {
    lc := &LocalCache{}
    go func() {
        for {
            time.Sleep(3 * time.Second)
            val, ok := ReadFromRedis()
            if ok {
                lc.mtx.Lock()
                lc.val = val
                lc.mtx.Unlock()
            }
        }
    } ()
    return lc
}

func (lc *LocalCache) Get() int {
    lc.mtx.RLock()
    defer lc.mtx.RUnlock()
    return lc.val
}
```
