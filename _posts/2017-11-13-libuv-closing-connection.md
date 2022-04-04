---
layout: post
title: libuv 1.16.0 連線關閉處理
categories:
- network programming
---

libuv常常有一些小改動

網路上找到的example通常沒辦法完全運作

開發過程中常常是直接爬原始碼解決問題..

在libuv開發TCP server時，程式會呼叫`uv_read_start`開始讀取資料，透過`read_cb`通知完成

當對端主動關閉連線或發送shutdown(WR)時，read事件就會得到EOF

在`read_cb`的parameter nread被設為`UV_EOF`，這時就要進行錯誤處理

假使我要進行的是將連線進行關閉的話，libuv的API文件提供了一個引子

```
The callee is responsible for stopping closing the stream when an error happens by calling uv_read_stop() or uv_close(). 

Trying to read from the stream again is undefined.
```

通常connection handle是在`connect_cb`透過`malloc`宣告來的，因此在結束時要將其`free`

而`uv_close`較為偷懶的寫法是將callback設為NULL進行同步處理，則程式碼會是

```
void on_read()
{
    ...

ON_ERR:
    uv_close( (uv_handle_t*) client, NULL);
    free(client);
}
```

然而魔鬼藏在細節裡，`uv_run`在callback完成後還會進行一次掃描`closing_handler`，從queue中移除沒有註冊任何事件的handle

但該handle已經被我們free掉了，形成一個漂亮的use-after-free

而解法也很簡單，設定`close_cb`將該變數free掉即可

libuv中整個close的流程大概是

read或write端發現對端關閉，需要進行關閉處理，會呼叫對應的callback

我們的程式要先判斷`!uv_is_closing()`接著呼叫`uv_close`，內部會呼叫對應的close方法，並將handle加入`closing_handle`後返回callback裡

這時還沒有完全處理完成，callback結束後回到uv的event loop中，如果還有掛在上面的其他事件，會執行該callback並收到`ECANCELED`

這時候由於handle狀態是closing，千萬不可再呼叫一次`uv_clsoe`，直接return，最後event loop會檢查`closing_handler`

並從queue中移除handler等清理動作，最後處理完才呼叫`close_cb`

繞了好大一圈才完全理解文件的說明..

感覺還是asio好寫很多阿
