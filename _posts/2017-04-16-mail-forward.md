---
layout: post
title:  "postfix mail forward到gmail"
date:   2017-04-16 13:28:06 +0800
categories: [sys_admin]
comments: true
---

之前都是用`s000032001@gmail.com`和`xnumtw@gmail.com`，前幾天突然想到自己買的網域可以拿來收mail，以後就可以用`[任意ID]@xnum.tw`。

之前架設postfix時是指定userid來收信，例如在`/etc/postfix/virtual`裡設定`num001 nummail` `num002 nummail`然後用POP3收nummail的信件。

接下來參考了[這篇文章](http://www.binarytides.com/postfix-mail-forwarding-debian/)做設定

把`/etc/postfix/virtual`裡留一行`@xnum.tw s000032001@gmail.com`但是寄信看log `/var/log/mail.log`發現被denied掉了

要兩個domain設定都同時有寫才會處理，`main.cf`部分設定如下

```
mydestination = xnum.tw
virtual_alias_domains = xnum.tw
luser_relay = s000032001@gmail.com
local_recipient_maps = 
```

下面兩行是找不到local user時要把信轉給誰，然後就能從我的gmail帳號收到信了

然後重抓設定

```
$ postmap /etc/postfix/virtual
$ sudo service postfix reload
```

順便加了fail2ban的設定，不然有人一直要用我的host做relay，刷了一堆log...

把`/etc/fail2ban/jail.conf`的`[postfix]` `[dovecot]`兩個開true

用指令試一下效果

`fail2ban-regex /var/log/mail.log /etc/fail2ban/filter.d/postfix.conf`

結果regex沒寫好，全都missed，修改這個檔案`/etc/fail2ban/filter.d/postfix.conf `

failregex加一行 `^%(__prefix_line)sNOQUEUE: reject: RCPT from \S+\[<HOST>\]: 454 4\.7\.1 .*$`

```
Failregex: 30351 total
|-  #) [# of hits] regular expression
|   2) [30339] ^\s*(<[^.]+\.[^.]+>)?\s*(?:\S+ )?(?:kernel: \[ *\d+\.\d+\] )?(?:@vserver_\S+ )?(?:(?:\[\d+\])?:\s+[\[\(]?postfix/smtpd(?:\(\S+\))?[\]\)]?:?|[\[\(]?postfix/smtpd(?:\(\S+\))?[\]\)]?:?(?:\[\d+\])?:?)?\s(?:\[ID \d+ \S+\])?\s*NOQUEUE: reject: RCPT from \S+\[<HOST>\]: 454 4\.7\.1 .*$
|   5) [12] ^\s*(<[^.]+\.[^.]+>)?\s*(?:\S+ )?(?:kernel: \[ *\d+\.\d+\] )?(?:@vserver_\S+ )?(?:(?:\[\d+\])?:\s+[\[\(]?postfix/smtpd(?:\(\S+\))?[\]\)]?:?|[\[\(]?postfix/smtpd(?:\(\S+\))?[\]\)]?:?(?:\[\d+\])?:?)?\s(?:\[ID \d+ \S+\])?\s*improper command pipelining after \S+ from [^[]*\[<HOST>\]:?$
`-
```

撈到三萬條log，ok，重啟fail2ban

`$ sudo service fail2ban reload`

done
