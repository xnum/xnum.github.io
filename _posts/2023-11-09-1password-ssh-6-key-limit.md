---
layout: post
title: SSH金鑰使用1Password管理超過6把會登入失敗的問題
categories: [sys_admin]
description: 由於ssh agent會每把key都試，而ssh server預設重試上限是6...
---

當你在1Password裡面放了6把SSH金鑰以後，登入SSH Server可能會發生這個錯誤

```
Too many authentication failures
```

這是因為預設啟用了對所有Host都使用ssh-agent

```
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

目前看起來解決方法只有config要辛苦一點列舉了

```
Host github.com
        HostName github.com
        User git
        IdentityFile "~/.ssh/github.pub"
        IdentitiesOnly yes
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

Host *
        IdentitiesOnly yes
```

<https://developer.1password.com/docs/ssh/agent/advanced/#ssh-server-six-key-limit>