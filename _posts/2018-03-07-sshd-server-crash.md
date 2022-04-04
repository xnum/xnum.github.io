---
layout: post
title: 記一次ssh server連線異常
categories:
- 閒聊
---

一日開發發現使用pietty 0.4.00無法連上某台開發機(SUSE Linux Enterprise 12)，改用putty 0.70可正常連線

初步檢查client log發現在key exchange階段被server斷線

putty預設使用ECDH key exchange演算法

pietty使用Diffie-Hellman group exchange演算法，而pietty中沒有提供ECDH選項

持續使用了putty一段時間後...決定來解決這個問題

觀察系統dmesg發現sshd程式crash

```
[1288847.216184] type=1326 audit(1520387105.670:1595): auid=4294967295 uid=498 gid=498 ses=4294967295 pid=2322 comm="sshd" sig=31 syscall=4 compat=0 ip=0x7fbda0c9bdf5 code=0x0
[1288882.058782] type=1006 audit(1520387140.530:1596): pid=2323 uid=0 old auid=4294967295 new auid=2020 old ses=4294967295 new ses=1556 res=1
[1289237.351002] type=1006 audit(1520387496.018:1597): pid=2438 uid=0 old auid=4294967295 new auid=2020 old ses=4294967295 new ses=1557 res=1
[1289620.053059] type=1326 audit(1520387878.938:1598): auid=4294967295 uid=498 gid=498 ses=4294967295 pid=2570 comm="sshd" sig=31 syscall=4 compat=0 ip=0x7feca1389df5 code=0x0
```

猜測在server進行key exchange計算的時候崩潰

檢查`/etc/ssh/sshd_config`

`KexAlgorithms`欄位有列出相關演算法

撈取sshd相關lib備用

```
$ ldd sshd
        linux-vdso.so.1 (0x00007fffd6700000)
        libwrap.so.0 => /lib64/libwrap.so.0 (0x00007f067d848000)
        libaudit.so.1 => /usr/lib64/libaudit.so.1 (0x00007f067d625000)
        libpam.so.0 => /lib64/libpam.so.0 (0x00007f067d415000)
        libselinux.so.1 => /lib64/libselinux.so.1 (0x00007f067d1f1000)
        libcrypto.so.1.0.0 => /lib64/libcrypto.so.1.0.0 (0x00007f067cdff000)
        libutil.so.1 => /lib64/libutil.so.1 (0x00007f067cbfb000)
        libz.so.1 => /lib64/libz.so.1 (0x00007f067c9e5000)
        libcrypt.so.1 => /lib64/libcrypt.so.1 (0x00007f067c7aa000)
        libgssapi_krb5.so.2 => /usr/lib64/libgssapi_krb5.so.2 (0x00007f067c562000)
        libkrb5.so.3 => /usr/lib64/libkrb5.so.3 (0x00007f067c291000)
        libcom_err.so.2 => /lib64/libcom_err.so.2 (0x00007f067c08d000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f067bce4000)
        libdl.so.2 => /lib64/libdl.so.2 (0x00007f067bae0000)
        libpcre.so.1 => /usr/lib64/libpcre.so.1 (0x00007f067b87a000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f067dd41000)
        libk5crypto.so.3 => /usr/lib64/libk5crypto.so.3 (0x00007f067b649000)
        libkrb5support.so.0 => /usr/lib64/libkrb5support.so.0 (0x00007f067b43c000)
        libkeyutils.so.1 => /lib64/libkeyutils.so.1 (0x00007f067b238000)
        libresolv.so.2 => /lib64/libresolv.so.2 (0x00007f067b020000)
        libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f067ae03000)
```

先排除系統程式問題，檢查系統完整性

```
# rpm -V --all
```

檢查列出檔案無上述相關程式檔或函式庫檔

改由另一台相同環境之開發機進行版本比對

```
# rpm -qa
```

比對發現三項可疑packages

```
libopenssl1_0_0-1.0.1i-18.1.x86_64                            | libopenssl1_0_0-1.0.1i-2.12.x86
libz1-1.2.8-5.1.x86_64                                        | libz1-1.2.8-13.15.x86_64  
openssl-1.0.1i-9.1.x86_64                                     | openssl-1.0.1i-2.12.x86_64
```

查詢詳細資訊如下(部分省略)

```
# rpm -qi libopenssl1_0_0
Name        : libopenssl1_0_0
Version     : 1.0.1i
Release     : 18.1
Architecture: x86_64
Install Date: Tue Dec 19 10:29:11 2017
Size        : 2581136
Build Date  : Tue Sep 27 23:53:04 2016
Build Host  : build81
Distribution: openSUSE Leap 42.1

# rpm -qi openssl
Name        : openssl
Version     : 1.0.1i
Release     : 9.1
Architecture: x86_64
Install Date: Tue Dec 19 10:29:12 2017
Size        : 1374628
Build Date  : Wed Dec  9 00:26:26 2015
Build Host  : cloud124
Distribution: openSUSE Leap 42.1
```

downgrade release

```
# rpm -Uvh --oldpackage libopenssl1_0_0-1.0.1i-2.12.x86_64.rpm openssl-1.0.1i-2.12.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:libopenssl1_0_0-1.0.1i-2.12      ################################# [ 25%]
   2:openssl-1.0.1i-2.12              ################################# [ 50%]
Cleaning up / removing...
   3:openssl-1.0.1i-9.1               ################################# [ 75%]
   4:libopenssl1_0_0-1.0.1i-18.1      ################################# [100%]
```

```
# rpm -qi  libopenssl1_0_0
Name        : libopenssl1_0_0
Version     : 1.0.1i
Release     : 2.12
Architecture: x86_64
Install Date: Wed Mar  7 10:20:30 2018
Size        : 2568576
Build Date  : Sat Sep 27 03:32:44 2014
Build Host  : sheep15
Distribution: SUSE Linux Enterprise 12

# rpm -qi openssl
Name        : openssl
Version     : 1.0.1i
Release     : 2.12
Architecture: x86_64
Install Date: Wed Mar  7 10:20:30 2018
Size        : 1374054
Build Date  : Sat Sep 27 03:32:44 2014
Build Host  : sheep15
Distribution: SUSE Linux Enterprise 12
```

pietty即可順利連線

世界又恢復了和平

