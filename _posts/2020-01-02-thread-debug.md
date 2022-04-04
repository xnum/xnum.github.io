---
layout: post
title: std thread 造成異常退出
date: 2020-01-02 20:24 +0800
categories:
- "C/C++"
---

程式退出時無法正常return 0，而是跑出了如下錯誤

```
terminate called without an active exception
Aborted (core dumped)
```

丟進gdb發現在std::thread的dtor裡面呼叫了terminate，往上爬callstack到關鍵的frame

```
(gdb) info frame
Stack level 5, frame at 0x7ffc2b28cf30:
 rip = 0x555c598ccf29 in std::thread::~thread (/usr/lib/gcc/x86_64-pc-linux-gnu/9.2.0/include/g++-v9/thread:139); saved rip = 0x555c598dbbc0
 called by frame at 0x7ffc2b28cf50, caller of frame at 0x7ffc2b28cf10
 source language c++.
 Arglist at 0x7ffc2b28cf20, args: this=0x7ffc2b28cff0, __in_chrg=<optimized out>
 Locals at 0x7ffc2b28cf20, Previous frame's sp is 0x7ffc2b28cf30
 Saved registers:
  rbp at 0x7ffc2b28cf20, rip at 0x7ffc2b28cf28
```

直接把thread id找出來

```
(gdb) print *this
$8 = {_M_id = {_M_thread = 140139420739328}}
```

轉成hex format是`7F74C0646700`，對照thread list發現是thread4還沒離開，所以在thread1殺不掉這個物件

```
(gdb) info thread
  Id   Target Id                                          Frame
* 1    Thread 0x7f74c064a800 (LWP 9151) "main" 0x0000555c598ccf29 in std::thread::~thread (this=0x7ffc2b28cff0, __in_chrg=<optimized out>) at /usr/lib/gcc/x86_64-pc-linux-gnu/9.2.0/include/g++-v9/thread:139
  4    Thread 0x7f74c0646700 (LWP 9157) "main" 0x00007f74c1405eb2 in epoll_wait () from /lib64/libc.so.6
  5    Thread 0x7f74bfd11700 (LWP 9158) "main" 0x00007f74c14de6d7 in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
  27   Thread 0x7f748d7fa700 (LWP 9180) "grpc_shutdown"   0x00007f74c1388977 in unlink_chunk.isra () from /lib64/libc.so.6
```

去看看thread4在執行什麼(跳過)，找到當初建立thread的object，呼叫detach()，收工
