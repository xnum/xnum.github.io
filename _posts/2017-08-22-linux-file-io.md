---
layout: post
title: Linux上的檔案IO效能優化
categories: ['C/C++', 'Linux']
---

對於一個要求數據讀寫同步的程式，通常可能加上`O_DIRECT`和`O_SYNC`來改變kernel的IO操作

呼叫流程的圖可以在[這邊](https://www.thomas-krenn.com/en/wiki/Linux_Storage_Stack_Diagram)找到

![](https://www.thomas-krenn.com/de/wikiDE/images/e/e0/Linux-storage-stack-diagram_v4.10.png)

也可以參考這篇文章的圖

[這邊](https://www.usenix.org/legacy/event/usenix01/full_papers/kroeger/kroeger_html/node8.html)

在預設情況下使用檔案相關API即是與VFS互動

VFS內部會利用Page Cache進行IO快取加速，因此mmap實際上也是與Page Cache互動

而Buffer Cache主要是針對device讀寫的加速

`O_SYNC`和`O_DSYNC`是對於Page Cache在寫時附帶進行flush

`O_DIRECT`則是不使用Page Cache，直接讀寫 (DMA as possible)，且必須自己進行對齊與固定大小

參考
[linux系统数据落盘之细节](http://www.cnblogs.com/wuhuiyuan/p/4648725.html)
