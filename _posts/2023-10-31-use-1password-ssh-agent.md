---
layout: post
title: 使用1Password管理我的SSH金鑰
categories: [security]
description: 發現1Password可以儲存SSH Key了，來進行一次大掃除
---

最近才發現1Password多了可以儲存[SSH Key](https://developer.1password.com/docs/ssh/)的功能。以前都是到處用複製金鑰的，一把Key到處通，趁這次機會做一次整理。

在[這邊](https://xuanwo.io/reports/2023-21/)也提到了應用方式。我的作法是針對每個要連線的伺服器產生一組金鑰，所以GitHub、工作站、vm、VPS...就會個別產生一個屬於他的key。

雖然[ssh agent explained](https://smallstep.com/blog/ssh-agent-explained/)提到使用ssh agent forwarding有點風險，但我只在自己的LAN裡面啟用，別人不太可能取得我的LAN機器權限，應該是還好..