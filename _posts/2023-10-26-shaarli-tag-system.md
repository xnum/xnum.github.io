---
layout: post
title: 我的shaarli 文章管理邏輯
categories: [筆記, 知識]
description: shaarli收錄的內容十分多樣化，為此我使用了一個特定的邏輯來整理和分類
---

由於在shaarli上的tag使用空白來分類，因此我們盡量讓tag名字不含空白，所以用底線來代換空白。

而搜尋tag的時候我們可以用wildcard的方式來包含多個tag，因此一個tag可以複含多個關鍵字，例如`lang.go`。

規則：

1. 採用樹狀分類，可以新增節點，但盡量不要移動或重組
2. 偏好最深的節點，例如os.linux.admin
3. 文章數量少時可以先不分類，例如只用saas或3c

- lang
  - cpp
  - go
  - js
- db
  - postgres
  - mysql
- saas
  - heroku
- 3c
  - nas
- os
  - linux
    - admin
- github
  - project
- learning
- news
  - crypto
  - fintech
- self_hosting
- apple
- youtube
- taiwan
- knowledge (代表從該文章中學習到新知識)
  - architect
  - backend
    - grpc
    - principle
  - low_latency
  - optimization
  - software_engineering
  - start_up
  - lead
    - tech
    - thinking

連結的description則用GPT-4進行瀏覽後幫忙生成