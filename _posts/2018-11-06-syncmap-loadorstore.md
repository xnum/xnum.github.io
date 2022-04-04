---
layout: post
title: sync.Map的LoadOrStore用途
date: 2018-11-06 22:13 +0800
categories:
- golang
---

在使用sync.Map時，最常用的兩個操作是Load()和Store()，有時候需要先判斷某個key是否存在，

如果不存在的話就初始化並寫入，但多個goroutine都要進行同一個操作時就可能發生races。

{% highlight golang linenos %}
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	var table sync.Map

	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			if _, ok := table.Load("KEY"); !ok {
				table.Store("KEY", n)
			}
		}(i)
	}
	wg.Wait()
	val, ok := table.Load("KEY")
	fmt.Println(val, ok)
}
{% endhighlight %}

這段程式的執行結果可能print出0~99間任意的val值，而非固定是0。

---

使用LoadOrStore(key, value)時，函式庫內部會先判斷是否存在key，如果存在就返回value，

否則就執行Store(key, value)，並且不會跟其他操作同時執行，下面的程式執行的結果，

成功設進去的值，一定會等於goroutine全部執行完後Load出來的值。

並且只會有一個goroutine列印出`Set to XX`。

{% highlight golang linenos %}
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	var table sync.Map

	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			_, loaded := table.LoadOrStore("KEY", n)
			if !loaded {
				fmt.Println("Set to", n)
			}
		}(i)
	}
	wg.Wait()
	val, ok := table.Load("KEY")
	fmt.Println(val, ok)
}
{% endhighlight %}

輸出如下：

```
Set to 99
99 true
```

---

有時候我們想要在Store時存入一個需要先Init或Create的Struct，

但LoadOrStore一定要帶入一個value作為參數，如果每個goroutine都在執行LoadOrStore前，

都先準備好一個Struct肯定是一件很沒有效率的事情，這時候我們可以寫入一個lambda function取值，

並讓要Store的goroutine在寫入成功後才初始化物件。範例如下：

{% highlight golang linenos %}
package main

import (
	"net/http"
	"sync"
)

var table sync.Map

type Getter func() *http.Request

func GetRequest(url string) *http.Request {
	getter := getReqFromMap(url)
	// 從getter裡取出真正的Request
	return getter()
}

func getReqFromMap(url string) Getter {
	if f, ok := table.Load(url); ok {
		return f.(Getter)
	}

	// 每個Load找不到的goroutine可能同時執行以下這段程式
	var req *http.Request
	var wg sync.WaitGroup

	wg.Add(1)
	waitGetter := func() *http.Request {
		wg.Wait()
		return req
	}

	f, loaded := table.LoadOrStore(url, Getter(waitGetter))
	if loaded {
		return f.(Getter)
	}

	// Store成功，初始化這個Request
	req, _ = http.NewRequest(http.MethodGet, url, nil)

	// 通知其他goroutine這個req已經建立完成
	wg.Done()

	// 把Getter換成沒有Wait()的版本，利於GC和加快速度
	wrapGetter := func() *http.Request {
		return req
	}
	table.Store(url, Getter(wrapGetter))
	return Getter(wrapGetter)
}

func main() {
	var wg sync.WaitGroup
	var req *http.Request

	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			req = GetRequest("http://example.com/user/")
		}(i)
	}
	wg.Wait()
}
{% endhighlight %}

一個效果相同，但用once實作的版本，可讀性較好，效能差距小於1%：

{% highlight golang linenos %}
package main

import (
	"net/http"
	"sync"
)

var table sync.Map

type Getter func() *http.Request

func GetRequest(url string) *http.Request {
	getter := getReqFromMap(url)
	return getter()
}

func getReqFromMap(url string) Getter {
	if f, ok := table.Load(url); ok {
		return f.(Getter)
	}

	var req *http.Request
	var once sync.Once
	wrapGetter := Getter(func() *http.Request {
		once.Do(func() {
			req, _ = http.NewRequest(http.MethodGet, url, nil)
		})

		return req
	})

	f, loaded := table.LoadOrStore(url, wrapGetter)
	if loaded {
		return f.(Getter)
	}

	return wrapGetter
}

func main() {
	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			GetRequest("http://example.com/user/")
		}(i)
	}
	wg.Wait()
}
{% endhighlight %}
