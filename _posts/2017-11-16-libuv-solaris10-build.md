---
layout: post
title: libuv 1.16.0 Build on Solaris 10 (SunOS 5.10)
categories:
- UNIX
---

## 環境

Solaris 10 (SunOS dev-ts1 5.10 Generic_150400-26 sun4v sparc sun4v)

$ isainfo
sparcv9 sparc

gcc 3.3.2 

Reading specs from /usr/local/lib/gcc-lib/sparc-sun-solaris2.10/3.3.2/specs
Configured with: ../configure --with-as=/usr/ccs/bin/as --with-ld=/usr/ccs/bin/ld --disable-nls
Thread model: posix
gcc version 3.3.2

## 事前工具準備

- automake 1.15
- autoconf 2.69
- m4 1.4.17
- aclocal 1.15
- texinfo (2.4.6 build fail 2.4.0 pass)
- libtool 2.4

## 編譯

```
./autogen.sh

32bit:
CFLAGS="-DSUNOS_NO_IFADDRS -D__EXTENSIONS__ -D_XOPEN_SOURCE=500 -D__SUNPRO_C" ./configure

64bit:
CFLAGS="-DSUNOS_NO_IFADDRS -D__EXTENSIONS__ -D_XOPEN_SOURCE=500 -D__SUNPRO_C -m64" LDFLAGS=-m64./configure
```

解說：
`SUNOS_NO_IFADDRS` Solaris10的libsocket沒有ifaddrs.h
`-D__EXTENSIONS__ -D_XOPEN_SOURCE=500`似乎沒什麼用 下保險的
`__SUNPRO_C` to use [Solaris atomic.h](https://docs.oracle.com/cd/E23824_01/html/821-1465/atomic-cas-uint-3c.html#scrolltoc)
builtin atomic operation caused link failed `__sync_val_compare_and_swap undefined reference`

修改`src/unix/getaddrinfo.c` [實作strnlen](https://github.com/slowfranklin/tracker/commit/ca217d15b61c048bc54e321d354e7ffcb3764277)

修改Makefile LDFLAGS加上-lm

```
make -j 16
```

## 測試

```
make check
```

failed list:
- fs_event
- tcp_oob
- poll_duplex
- poll_unidirectional
- tcp_ipv6_link_local
- platform output

## 安裝

```
make install
```

/usr/local/lib/libuv.a
/usr/local/include/uv.h
