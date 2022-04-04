---
layout: post
title: postfix 二度修改設定紀錄
categories: [sys_admin]
comments: true
---

一時興起寄了封信給自己，結果發現收不到，看log發現`Domain name not found`

[翻到這篇文章](https://snippetinfo.net/mobile/media/1406)

在`/var/spool/postfix/etc/resolv.conf`加上dns server，搞定

又寄了一次信，看到信件來源被標記為紅色鎖頭，代表未經加密

最高等級的綠色鎖頭要設定S/MIME，比較麻煩，還有一個是TLS加密

[又翻了一篇文章來解](http://blog.snapdragon.cc/2013/07/07/setting-postfix-to-encrypt-all-traffic-when-talking-to-other-mailservers/)

最後我的TLS相關設定長這樣(`/etc/postfix/main.cf`)

```
# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtpd_tls_security_level = may
smtp_tls_security_level = may
smtp_tls_loglevel = 1
smtpd_tls_loglevel = 1
```

還有個收到信以後，寄信回去的mail會是我的gmail而不是來自`xnum.tw`的問題...之後再想辦解決吧


