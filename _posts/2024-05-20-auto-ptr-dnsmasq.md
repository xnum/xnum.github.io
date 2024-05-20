---
layout: post
title: 在dnsmasq加上自動生成PTR紀錄
categories: [home_lab]
---

偶而想研究一下有哪些網路連線和流量進出，開啟IP解析以後，一部份的IP可以解析出擁有者是誰，例如HiNet, AWS, Facebook，但也有一些解不出來的IP是屬於雲端供應商所有，例如cloudflare，如果能夠在本地的DNS上回應PTR紀錄，就能減少排查可疑連線的時間。

通常來說，這些網段都非常大，從 `/24`到`/12`都有可能，因此無法用列舉的方式寫出所有IP，必須要DNS伺服器有實作自動生成轉換紀錄的功能才行。

以OpenWRT為例，上面預設的DNS伺服器是dnsmasq。在`/etc/dnsmasq.conf`增加設定就可以自動轉換：

```
synth-domain=cloudflare.net,10.0.0.0/24,public-
```

可以在套用前先執行`dnsmasq --test`來檢查設定。之後需要用`/etc/init.d/dnsmasq restart`套用設定。

用`dig -x 10.0.0.1`的話就可以看到PTR紀錄為`public-10-0-0-1.cloudflare.net`