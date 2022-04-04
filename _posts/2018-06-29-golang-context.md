---
layout: post
title: golang context
date: 2018-06-29 21:27 +0800
categories:
- golang
---

今天突然搞懂了golang中context的設計和用途，來做個筆記

context其實就是parent goroutine (master)對child goroutine (slave)的控制手段

一般來說master把資料傳輸給slave的方式就是透過channel

或是當作parameter傳入，像是這樣：

```golang
func sum(arr []int) {
    n := 0
    for _, v := range arr {
        n += v
    }
}

func sumChan(ch chan int) {
    n := 0
    for v := range ch {
        n += v
    }
}

func main() {
    go sum([]int{1, 2, 3})

    ch := make(chan int)
    go sumChan(ch)
    ch <- 1
    ch <- 2
    ch <- 3
}

```

當我們想要進一步控制goroutine關閉時，可能就會使用另一個channel或waitGroup

```golang
func sum(ch chan int, done chan struct{}) {
    n := 0
    select {
    case v := <-ch:
        n += v
    case <-done:
        return // close
    }
}

func main() {
    ch := make(chan int)
    done := make(chan struct{})
    go sum(ch, done)
    ch <- 1
    close(done)
}
```

這樣其實很麻煩，當我們在生出來的goroutine中又想要再做其他事情，產生新的goroutine

就變得不好控制

比如我有一個爬蟲程式，main會開幾個goroutine去fetch網頁內容，

抓下來的網頁內容經過過濾後會把特定網頁再往後端服務送

```
main() -> fetcher() -> analyzer()
```

由於fetcher和analyzer都屬於送出HTTP Request的IO Burst task

所以我們用goroutine處理

現在fetcher關閉後，analyzer就變成孤兒了，為了管理goroutine間的關係

可以使用context取代done channel或waitGroup

```golang
func fetcher(ctx context.Context, url string) {
    req, err := http.NewRequest(http.Get, url, nil)
    req = req.WithContext(ctx)
    client := &http.Client{}
    client.Do(req)
}

func main() {
    ctx, cancel := context.WithCancel(context.Background())
    // Now I have a derived context to control my goroutines.
    go fetcher(ctx, "http://www.google.com")
    go fetcher(ctx, "http://www.google.com/1")
    go fetcher(ctx, "http://www.google.com/2")
    go fetcher(ctx, "http://www.google.com/3")

    doSomething()

    // I don't want to wait anymore...
    cancel()
}
```

現在我們可以透過呼叫cancel來把相關聯的goroutine都關掉

更神奇的是context還可以設定一個Timeout

假如每個網頁等10秒沒抓完我就要放棄，可以再改寫成

```golang
func fetcher(pctx context.Context, url string) {
    ctx, cancel := context.WithTimeout(pctx, 10*time.Second)
    defer cancel()

    req, err := http.NewRequest(http.Get, url, nil)
    req = req.WithContext(ctx)
    client := &http.Client{}
    client.Do(req)
}
```

這樣我們就多了一層context來控制底下的slave最多只能跑10秒

所以http.Client呼叫Do()做事情時，受到我們新的context的控管

return時只有兩種可能，做完了或已經過10秒了。

我覺得最有趣的地方是：context被設計成不是呼叫`ctx.Cancel()`

而是在`ctx.With???()`的時候給予cancel function

因為只有parent才會去關閉child，child事實上不應該去呼叫的

不然就會把兄弟姊妹也關了


結束時一定要呼叫cancel function，老實說我也不是完全理解為甚麼

可能是為了revoke一些內部資源吧。不過重複呼叫cancel是沒關係的。


