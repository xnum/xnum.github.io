---
layout: post
title: Solaris的Select Bug
categories: ['UNIX']
---

今天追蹤一個Select上的Bug，問題的起因是程式某個地方的Select卡住永遠不會Return，但監聽的Socket已經關閉了

單純聽病灶的話，感覺只要重新檢視Select在使用上是否有出錯即可

的確檢查後也發現程式沒有設定Timeout，再加上FD_SET在某些條件下沒有重新添加fd，因此呼叫後沒有Return

(小知識：Select在Return後會修改傳進去的FD_SET和timeval，再次呼叫前務必重新設好parameter)

但做好這個檢查後仍然繼續出現Bug...幸虧這是一個可以重現的問題

用gdb開啟程式，並在問題重現後用Ctrl+C，gdb就會直接幫我在目前執行到的地方中斷

結果發現死在syscall裡...callstack如下

```
(gdb) bt
#0  0xffffffff7e4dc788 in __pollsys () from /lib/64/libc.so.1
#1  0xffffffff7e4cb530 in _pollsys () from /lib/64/libc.so.1
#2  0xffffffff7e476134 in pselect () from /lib/64/libc.so.1
#3  0xffffffff7e4764d8 in select () from /lib/64/libc.so.1
#4  0x0000000100005cdc in WriteSocket ( ... ) at Client.c:449
```

中斷時會在syscall前後也是很正常的，於是`continue`讓他繼續執行，經過約10秒...已經超過我的1秒timeout很久

還是沒有任何反應，使用Ctrl+C嘗試再次中斷，沒有反應，看來訊號被遮蔽了

但在出現問題前曾有錯誤訊息，表示Connection Reset By Peer

於是改用在error handling function下斷點來看錯誤發生處

```
(gdb) bt
#0  Error (nReqId=0, nErrorCode=131,
    pszDescription=0xffffffff7e4de829 <_sys_errs+2737> "Connection reset by peer")
#1  0x00000001000060ec in ReadSocket ( ... )
```

結果是從另一個Thread跳出的錯誤訊息，開始懷疑是kernel這段出了差錯

改用`truss -f`追蹤syscall狀況

結果發現有兩個pollsys被連續呼叫，之後就觸發Bug了

由於Solaris沒有open source，因此只能追到這邊

我猜想有可能是race condition

當ReadSocket呼叫select時，WriteSocket也緊接著呼叫select

這時候第一個select已經回傳錯誤，第二個select卻被成功加進event queue

但之後socket不會處於writable狀態，且socket已經被關閉，於是發生死循環

或者是Solaris Threads的實作有bug，因此沒有Return


最後我在ReadSocket和WriteSocket偵測到socket發生錯誤時

都將其close，來嘗試引發kernel對於file descriptor的資源回收動作

便成功使WriteSocket的select也會return了
