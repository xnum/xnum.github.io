---
layout: post
title: win上的docker執行laravel專案
categories: [Docker]
---

紀錄一下docker在windows上開啟的作法

拉image

`docker pull laraedit/laraedit`

執行

`docker run -d --name laravel -p 8082:80 -p 3307:3306 -v D:\GitHub\race:/var/www/html/app laraedit/laraedit`

看他

`docker ps -a`

進去動手腳

`docker exec -it laravel /bin/bash`

Exited之後把他再叫起來

`docker start laravel`


ref: https://blog.wu-boy.com/2016/03/replace-laravel-homestead-with-docker/

mysql cli以utf-8輸出`set names utf8;`
