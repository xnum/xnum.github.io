---
layout: post
title: 解決在gerrit上的ssh rsa key不能使用的問題
categories: ['sys_admin']
description:
---

系統更新後發現jenkins failed了，錯誤訊息如下

```
Cloning into 'gobe'...
sign_and_send_pubkey: no mutual signature supported
jenkins@ci.stranity.com: Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

經查是ssh-rsa已經不支援，於是生了一隻新的key準備幫他安裝

`ssh-keygen -t ed25519`

結果問題來了，當初jenkins帳號是用email alias建立，用正常的google oauth肯定登入不進去

回憶了一陣子一開始架設應該也是用甚麼奇怪的指令把ssh key加進去

果不其然有這條可以用 https://gerrit-review.googlesource.com/Documentation/cmd-set-account.html

```
$ echo "ssh-ed25519 xxxxx jenkins@ubuntu" | ssh gerrit.stranity.com gerrit set-account --add-ssh-key - Jenkins-ci`
```


