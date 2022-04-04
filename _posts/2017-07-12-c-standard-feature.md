---
layout: post
title: C Standard & Feature
categories: ['C/C++']
---

工作上需要Porting系統從Solaris到Linux上

在網路上查到比較有系統性的文章是2002年IBM的文

裡面有一條如果使用到pthread時建議在編譯參數上新增`-DPOSIX_C_SOURCE=199506L`

於是便開始了研究參數之旅...


一開始把Standard和上面提到的XX_SOURCE搞混

Standard是制定的公開語言標準，以C來說最知名的大概是ANSI C

也就是C90或C89，使用這個Standard在編譯時要加`-ansi`或`-std=c90`

再來便是C99，在使用C(不是C++喔)的for迴圈就會偶而看到

`for (int i = 0; ...) `將變數宣告在for迴圈裡面會跳出錯誤

編譯器會叫你改用C99

而最新的是C11，比C++11還要少聽到...我也不知道C11多了哪些東西

不過寫C的場合也只剩維護legacy code了，就先不管它吧


而這次提到的Features，則是有別於Standard，制定的是系統相關的API

如POSIX、XOPEN、SVID等等...，當define不同Feature後，就能使用該Feature制定的functions

同一個標準的名稱還有不同年份制定的不同版本，其實看全名就非常清楚這東西到底是甚麼

POSIX: Portable Operating System Interface

這對現代的code好像比較沒有關係了，但要向前支援或在不同平台上編譯執行的話

就需要判斷支援的Feature了，有點類似判斷平台為linux、UNIX、macOS...


另外還有define `__REENTERANT`，也是Solaris上才需要去額外增加的

[IBM Porting Guide](https://www.ibm.com/developerworks/systems/articles/porting_linux/)
[Oracle文章參考](http://docs.oracle.com/cd/E19253-01/819-7051/compile-4/index.html)
