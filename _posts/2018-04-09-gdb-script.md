---
layout: post
title: gdb自動化 - 中斷點自動執行命令
categories:
- dev
---

為了reproduce一個低機率進入錯誤處理的程式流程，嘗試使用gdb來達成100%進入..

首先對某行原始碼進行中斷

```
(gdb) break tcp.c:999
```

回報有兩個一樣的地方..

```
Breakpoint 5 at 0x406adf: tcp.c:999. (2 locations)
(gdb) info break
Num     Type           Disp Enb Address            What
5       breakpoint     keep y   <MULTIPLE>
5.1                         y     0x0000000000406adf in send_hb_packet at tcp.c:999
5.2                         y     0x0000000000414c84 in uv_tcp_init_ex at src/unix/tcp.c:999
```

刪掉改用address中斷

```
(gdb) del break 5
(gdb) break *0x0000000000406adf
```

對既有的break下命令 (6為中斷點編號、-7為errno 隨意設定一個負值)

```
(gdb) commands 6
set var rc = -7
continue
end
```

執行到中斷點時gdb跳出錯誤

```
Left operand of assignment is not an lvalue.
```

看了一下結果是被優化掉了

```
(gdb) print rc
$1 = <optimized out>
```

沒關係依照calling convention，回傳值在rax

```
(gdb) commands 6
Type commands for breakpoint(s) 6, one per line.
End with a line saying just "end".
>set $rax = -7
>cont
>end
(gdb) continue
Continuing.
```

成功進入，收工。
