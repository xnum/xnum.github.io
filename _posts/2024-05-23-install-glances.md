---
layout: post
title: 在Linux上面安裝glances並設定為系統服務
categories: [sys_admin]
---

以下是潤飾後的文章：

---

layout: post  
title: 在 Linux 上安裝 Glances 並設定為系統服務  
categories: [sys_admin]  

---

由於在 Docker 中無法查看某些系統資訊，加上需要指定版本，因此需要進行一個繁瑣的 Python 程式安裝流程。

首先，我們需要建立一個虛擬環境來隔離即將安裝的依賴，以免影響系統的穩定性。

```bash
apt install python3 python3-venv
```

接下來，建立一個虛擬環境：

```bash
python3 -m venv /root/_glances
source /root/_glances/bin/activate
```

接著，安裝 Glances。如果需要使用 Web UI，則需要額外安裝 FastAPI。

```bash
pip3 install Glances
pip3 install FastAPI
```

以下是 systemd 的服務配置檔案，將其放置於 `/etc/systemd/system/glances.service`：

```ini
[Unit]
Description=Glances
Documentation=man:glances(1)
Documentation=https://github.com/nicolargo/glances
After=network.target

[Service]
ExecStart=/root/_glances/bin/python3 -m glances -w
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

完成上述步驟後，啟用並啟動 Glances 服務：

```bash
systemctl daemon-reload
systemctl enable glances
systemctl start glances
```

這樣就完成了在 Linux 上安裝並設定 Glances 為系統服務的步驟。現在，你可以透過 Web UI 來監控你的系統狀態了。
