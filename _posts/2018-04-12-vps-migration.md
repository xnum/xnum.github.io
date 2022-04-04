---
layout: post
title: VPS [GCP -> linode] 搬家記
categories:
- 雜記
---

從大學開始就一直有做一台開發機在網路上的習慣

出外的時候臨時需要可以很方便的連上去做使用

平時要寫些小程式測試也方便

最開始是借用了實驗室裡的PC，藉由vm安裝了ubuntu，把特定port打開來使用

後來機器越來越多，總共大概有四到五台可以連線

在學校也架了一個自己域名的wordpress blog

同時期也嘗試了hexo，不過GitHub pages還不夠成熟，需要CI來編譯網站，總之很麻煩

畢業後基於不要竊佔學校資源的想法，開始進行搬家工程

首先是買了一個rpi2擺在家裡路由器旁邊，雖然速度不快還堪用

不過遠距離畢竟難管理，出問題就需要人親自修復

加上sd卡的壽命不堪摧殘，過了半年後就放棄了

剛好碩班時申請的GitHub的student developer package，拿到Digital Ocean的免費額度50美

就在離台灣最近的新加坡開一個每個月10美的droplet，把東西都搬上去

新加坡機房的ping大概是100ms，使用vim實在有點難受

主要還是一些web和mail service，blog記得也還是自己hosting的

過了半年把免費額度用完時，剛好Google推廣GCP也提供了300美的額度使用

加上有台灣區可以選，ping值不到10ms用起來令人異常舒爽

開了兩個instance，一個當跳板繞過公司網路，一個繼續當原本的開發機使用，寫一些簡單的程式

就這樣又過了好幾個月..額度終於燒到剩下一個月的量了 (是不是他們收費比較貴阿..)

加上Google會對instance做一些干涉，讓我不是很舒服，決定再搬家一次

台灣區找來找去沒有一個國際級的VPS Provider，次佳的選擇還是日本機房，ping值大約30ms

本來在linode和vultr之間做選擇，不過vultr竟然不支援第三方登入，我也懶得打一堆資料

就使用註冊很久但是都沒用過的linode了..這次就省錢點開5美的機器

一次裝好python3 jekyll go1.10 nodejs8等各路語言..

再把DNS指過來，原本的憑證revoke掉，就搞定了，大約耗了半天

大部分都是打打指令，把ssh key丟上GitHub而已

比較繁雜的設定大概是nginx，由於我把xnum.tw轉址到github.io (雖然應該沒人會用，都是我自己在用而已)

加上測試時會用到80 port (blog預覽 json-resume預覽)，在nginx加了reverse proxy

不然chrome會擋非https的網站，真是煩死人

設定大概長這樣

轉址部分

```
server {
    listen 80;
    listen 443 ssl http2;

    root /var/www/html;

    index index.html;

    server_name xnum.tw www.xnum.tw;

    location / {
        return 301 https://xnum.github.io$request_uri;
    }
}
```

測試用的proxy

```
server {

    listen 80;

    root /var/www/html;

    server_name test.xnum.tw;

    location / {
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;

        proxy_pass          http://localhost:8000;
        proxy_read_timeout  5;

        proxy_redirect      http://localhost:8000 https://test.xnum.tw;
    }
```
