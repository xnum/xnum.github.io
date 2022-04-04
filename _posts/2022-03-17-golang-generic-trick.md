---
layout: post
title: go generic 版本實作的 migrate 方式
date: 2022-03-17 00:00 +0800
categories: golang
---

go1.18推出了generic功能，但是std庫的generic版本要在1.19才會推出

目前還不確定會用甚麼方式來處理migrate的問題，這邊有一些[討論](https://github.com/golang/go/discussions/48287)

看過一輪以後我比較喜歡這個使用type alias的方法，

```
package main

import "fmt"

type QueueOf[T any] struct{}

func (q *QueueOf[T]) Len() int { return 0 }

type Queue = QueueOf[any]

func main() {
        var q1 QueueOf[any]
        var q2 QueueOf[string]
        var q3 Queue

        fmt.Println(q1.Len())
        fmt.Println(q2.Len())
        fmt.Println(q3.Len())
}
```

另外在1.18裡面新增了一個builtin `type any = interface{}` 這樣寫起來就更簡潔了
