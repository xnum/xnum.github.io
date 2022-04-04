---
layout: post
title: Interactive shell和login shell的分別
categories:
- UNIX
---

## login shell

登入系統時，獲得的shell
比如ssh登入，或是su登入拿到的shell

login shell會載入`/etc/profile` `~/.bash_profile` `~/.bash_login` `~/.profile` 
且登出時執行`~/.bash_logout`

## interactive shell

就是會與使用者交互，等待命令後執行的shell

可以從`$-`確認，會開啟interactive shell (i)標誌

interactive shell會載入`/etc/bash.bashrc` `~/.bashrc` 

non-login + non-interactive shell只從BASH_ENV變數載入該檔

不同發行版測試結果可能不同

在ubuntu 17.10 (gcp)上測試時，不會載入`~/.bashrc`

但是SLES 12會載入`~/.bashrc`

可以執行ssh指令驗證 (開啟的是non-interactive shell)

```
num@instance-1:~$ ssh localhost 'env'
```


因此，最好不要在`~/.bashrc`寫一些會列印的指令，會影響到rsync、scp、git此類指令的執行
