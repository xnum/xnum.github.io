---
layout: post
title: gentoo install gitlab-runner
date: 2019-08-27 18:07 +0800
categories: gentoo
---

照著官網步驟作，跳出 `FATAL: Failed to install gitlab-runner: Not supported system`

安裝第三方版..但是問題一樣

```
sudo emerge --ask layman
sudo layman -a nest
sudo emerge -av dev-util/gitlab-runner
```

解法

```
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

sudo chmod +x /usr/local/bin/gitlab-runner

sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
```

會跳出錯誤，不理它

```
sudo chmod +x /etc/init.d/gitlab-runner
sudo vim /etc/init.d/gitlab-runner
```

寫入

```
#!/sbin/openrc-run

name="gitlab-runner"
command="/usr/local/bin/gitlab-runner"
command_args="run -u gitlab-runner -d /home/gitlab-runner"
command_background=true
pidfile="/var/run/gitlab-runner.pid"

depend() {
    need net localmount
}
```

把服務裝進去

```
sudo rc-update add gitlab-runner
sudo rc-service gitlab-runner start
```

設定docker權限

```
sudo usermod -aG docker gitlab-runner
```

status看狀態會顯示沒有在執行中，但是已經可以註冊給gitlab-ci使用了

```
gitlab-runner register
```

ref:

https://gitlab.com/gitlab-org/gitlab-ce/issues/61719
https://docs.gitlab.com/runner/install/linux-manually.html
https://docs.gitlab.com/runner/register/
