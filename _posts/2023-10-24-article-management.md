---
layout: post
title: 打造知識庫 - 自架RSS Feed和書籤管理系統
categories: [home_lab, 知識]
---

早期我就有訂閱RSS的習慣，並使用Feedly當成彙整平台。使用RSS來訂閱各種技術Blog和新聞，就不需要跟個喪屍一樣整天刷網站。

最近重新整理了RSS Feed訂閱和書籤管理系統，本來只是想更方便地管理文字資源，做著做著就變成了一個知識庫的生產流水線。平常也會在網路上閱讀到一些不錯的文章，卻沒有保存下來。有時候要回過頭去尋找某篇文章就相當花功夫了。剛好在逛自架服務的時候發現了有相關的軟體可以進行管理，而不用存在瀏覽器。接著就產生了自架web archive service的念頭，來保存高品質的文章。最後乾脆把RSS Reader也給自架了，變成一條龍作業。

- [RSSHub](https://docs.rsshub.app/zh/)是一個RSS生成器，將沒有支援RSS功能的網站實作RSS訂閱源，例如：Docker Hub、Facebook
- [Tiny Tiny RSS](https://tt-rss.org/)是一個開源的RSS Reader。
- [Shaarli](https://shaarli.readthedocs.io/en/master/)是一個書籤管理系統。他還有一個很方便的功能是可以公開分享，因此你也可以看到[我收藏的書籤](https://coll.xnum.in/)。
- [wallabag](https://github.com/wallabag/wallabag)是一個開源的archive服務，因此你可以將網頁存檔並儲存在自己的硬碟空間。另外他還可以和shaarli整合，來進一步儲存蒐集到的書籤。

此外RSS也可以匯出清單為opml格式，我將其匯出後轉換成html，變成了一份[我的Feed清單](https://xnum.in/feed_list.html)。
