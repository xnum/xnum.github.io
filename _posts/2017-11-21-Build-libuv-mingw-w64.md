---
layout: post
title: Cross compile libuv 1.16.0 with mingw-w64 on Linux
categories:
- UNIX
---

在Windows上libuv推薦的方式是透過vcbuild編譯

也是offical的binary release編譯方式

但編譯後的dll會相依於Visual Studio的Runtime (vcruntime140.dll)

執行環境上沒有安裝相關Runtime時，就無法執行

為了解決這個問題，且又能跨平台，我選擇改用gcc toolchain自行編譯


gcc toolchain的幾種主流方法：

- cygwin x86_64
- TDM-GCC-64 
- mingw-w64

p.s. 偶然發現的一篇[文章](http://mingw.5.n7.nabble.com/importing-sys-queue-h-td9462.html)講到cygwin和mingw的不同

> porting unix software to windows is NOT the 
> purpose of MinGW -- that's what the Cygwin project is for.  MinGW is a 
> gcc compiler for creating win32 programs

編譯還需要幾個相關工具`libtool` `automake` `m4` `aclocal`

在Windows上編譯還需要另外安裝這些工具，而且被該死的OfficeScan擋住以致於編譯速度天殺的慢

只好選擇在Linux上安裝mingw-w64編譯Windows的binary

由於開發機上沒有外網，要自己拉rpm安裝，以下是離線安裝需要的rpms

- mingw64-gcc-4.9.2-el6.x86_64
- mingw64-headers-3.3.0-1.el6.noarch
- mingw64-winpthreads-3.3.0-1.el6.x86_64
- mingw64-filesystem-100-1.el6.noarch
- mingw64-crt-3.3.0-1.el6.noarch
- mingw64-cpp-4.9.2-1.el6.x86_64
- mingw64-binutils-2.25-2.el6_x86_64
- mingw-binutils-generic-2.25-2.el6.x86_64
- mingw-filesystem-base-100-1.el6.noarch
- libmpc-0.8-3.el6.x86_64
- gmp-4.3.1-12.el6.x86_64
- mpfr-2.4.1-6.el6.x86_64

接著照[這篇](https://github.com/joyent/libuv/wiki/Cross-compilation)下指令

但還會缺少`NDIS_IF_MAX_STRING_SIZE`的定義，在報錯處加上`#define NDIS_IF_MAX_STRING_SIZE IF_MAX_STRING_SIZE`

出現headers No Such File時，改成全小寫，在Linux上檔案名稱是大小寫相異的

預設標頭檔安裝在`/usr/x86_64-w64-mingw32/sys-root/mingw/include/` 這邊應該都能找到檔案

這樣就能順利編譯了

與程式進行連結時，LDFLAGS需要這些參數`-luv -lws2_32 -lmswsock -ladvapi32 -liphlpapi -lpsapi -luserenv`
