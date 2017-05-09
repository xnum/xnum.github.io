---
layout: post
title: beanfunapp 破解嘗試 writeup
tags: [security, android]
comments: true
---

下午被叫去試著破解beanfun app的活動，雖然失敗了還是紀錄一下思路。

桌面板網站一般登入流程已經被關閉，登入頁面沒有看到可嘗試的隱藏選項，因此我們嘗試使用QRCode登入途徑。

QRCode登入主要從手機端來認證，如果可以偽造request發出惡意請求，或許可以破解，先嘗試撈封包。

在手機上安裝tPacketCapture，把其他程式關閉，實際執行一次登入流程，獲得pcap檔案一份。

在wireshark上打開，過濾`ip.addr==202.80.107.0/24`，看到一堆TLSv1.2封包，此路不通。

嘗試拆apk檔，先用apk downloader從google play商店下載最新版beanfun app apk一份。

用apktool解開檔案，看Manifest找到程序進入點，用dex2jar解出class檔，再用jd-cli解出java source code。

得到加殼過的原始碼一份 G__G


晚上繼續奮戰，從lib名稱和package名稱來看是梆梆加固，開始搜尋脫殼作法

裝了Android Studio來跑Android Emulator，下載官方4.4 image

並替換成DexExtrator的system.img，安裝App後導出dex，並用Decode還原

```
-rw-rw-r-- 1 num num 3.1M  五   3 21:39 com.gamania.beanfun_classes_2407140.dex
-rw-rw-r-- 1 num num  23K  五   3 21:42 com.gamania.beanfun_classes_17656.dex
-rw-rw-r-- 1 num num 195K  五   3 21:43 Decode.jar
-rw-rw-r-- 1 num num 2.3M  五   3 21:45 com.gamania.beanfun_classes_2407140.read.dex
-rw-rw-r-- 1 num num  18K  五   3 21:45 com.gamania.beanfun_classes_17656.read.dex
```

接著用dex2jar轉換回jar檔，得到

```
-rw------- 1 num num 2.2M  五   3 21:46 com.gamania.beanfun_classes_2407140.read-dex2jar.jar
```

接著用一樣的做法轉出java source code。

結果是一堆看不懂的東西，放棄 QQ
