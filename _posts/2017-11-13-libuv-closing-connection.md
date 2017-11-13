---
layout: post
title: libuv 1.16.0 連線關閉處理
tags:
- network programming
---

libuv常常有一些小改動

網路上找到的example通常沒辦法完全運作

開發過程中常常是直接爬原始碼解決問題..

在libuv開發TCP server時，程式會呼叫uv_read_start開始讀取資料，透過read_cb通知完成

當對端主動關閉連線或發送shutdown(WR)時，read事件就會得到EOF

在read_cb的parameter nread被設為UV_EOF，這時就要進行錯誤處理

假使我要進行的是將連線進行關閉的話，libuv的API文件提供了一個引子

```
The callee is responsible for stopping closing the stream when an error happens by calling uv_read_stop() or uv_close(). 

Trying to read from the stream again is undefined.
```

通常connection handle是在connect_cb透過malloc宣告來的，因此在結束時要將其free

而uv_close較為偷懶的寫法是將callback設為NULL進行同步處理，則程式碼會是

```
void on_read()
{
    ...

ON_ERR:
    uv_close( (uv_handle_t*) client, NULL);
    free(client);
}
```

然而魔鬼藏在細節裡，uv_run在callback完成後還會進行一次掃描closing_handler，從queue中移除沒有註冊任何事件的handle

但該handle已經被我們free掉了，形成一個漂亮的use-after-free

而解法也很簡單，設定close_cb將該變數free掉即可


感覺還是asio好寫很多阿
