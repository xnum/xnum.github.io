---
layout: wiki
title: systemd 新增 service
cate1: linux
cate2:
description: some word here
keywords: linux, systemd
type:
link:
---

在 `/etc/systemd/system/` 底下新增 `xxx.service`

```
[Unit]
Description=ipmi exporter service
After=network.target syslog.target

[Service]
Type=simple
WorkingDirectory=/tmp
Restart=always
RestartSec=1
User=root
SyslogIdentifier=ipmi-exporter
ExecStart=/usr/bin/ipmi_exporter

[Install]
WantedBy=multi-user.target
```

`# systemctl daemon-reload`
`# systemctl start xxx.service`
