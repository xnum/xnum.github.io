---
layout: post
title: Solaris Useful Commands
categories:
- UNIX
---

紀錄一些solaris下會用到的指令

### pfiles

查詢該pid開啟的所有fd和詳細資訊

`pfiles [pid]`

```
# pfiles 12284
12284:  ./main
  Current rlimit: 4096 file descriptors
   0: S_IFSOCK mode:0666 dev:374,0 ino:34893 uid:0 gid:0 size:0
      O_RDWR
        SOCK_STREAM
        SO_SNDBUF(16384),SO_RCVBUF(5120)
        sockname: AF_UNIX
   1: S_IFREG mode:0644 dev:85,7 ino:985900 uid:310 gid:300 size:603
      O_WRONLY|O_CREAT|O_TRUNC|O_LARGEFILE
      /var/log/01.log
   2: S_IFREG mode:0644 dev:85,7 ino:985900 uid:310 gid:300 size:603
      O_WRONLY|O_CREAT|O_TRUNC|O_LARGEFILE
      /var/log/01.log
   3: S_IFSOCK mode:0666 dev:374,0 ino:55360 uid:0 gid:0 size:0
      O_RDWR
        SOCK_STREAM
        SO_REUSEADDR,SO_KEEPALIVE,SO_SNDBUF(49152),SO_RCVBUF(49152)
        sockname: AF_INET 0.0.0.0  port: 1980
   4: S_IFREG mode:0666 dev:85,7 ino:841434 uid:310 gid:300 size:1405
      O_WRONLY|O_APPEND|O_CREAT
      /var/log/out
```

### ps
 
ps -jf -u user

在Linux下習慣`ps -aux | grep user`，但是solaris下不支援

改用-jf 可以列出USER PID PPID PGID SID CMD等資訊

### psig

列出該process的訊號處理方式

`psig [pid]`

```
# psig 12284
12284:  ./main
HUP     default
INT     caught  resetfcn        0
QUIT    caught  quitfcn         0
ILL     default
TRAP    default
ABRT    default
EMT     default
FPE     default
KILL    default
BUS     default
SEGV    default
SYS     default
PIPE    caught  quitfcn         0
ALRM    default
TERM    caught  quitfcn         0
USR1    default
USR2    default
CLD     ignored                 NOCLDWAIT,NOCLDSTOP
PWR     default
WINCH   default
URG     default
POLL    default
STOP    default
TSTP    default
CONT    default
TTIN    default
TTOU    default
VTALRM  default
PROF    default
XCPU    default
XFSZ    default
WAITING default
LWP     default
FREEZE  default
THAW    default
CANCEL  default
LOST    default
XRES    default
JVM1    default
JVM2    default
RTMIN   default
RTMIN+1 default
RTMIN+2 default
RTMIN+3 default
RTMAX-3 default
RTMAX-2 default
RTMAX-1 default
RTMAX   default
```
