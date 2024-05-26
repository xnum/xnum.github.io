---
layout: post
title: 多媒體檔案管理和下載伺服器 - 軟體篇
categories: [sys_admin]
description: 最近研究的BT下載+做種+瀏覽檔案的軟體方案
---

在管理多媒體檔案時，常見的RAID方案能提供即時保護，將多個硬碟模擬成一個虛擬硬碟給作業系統使用。這些虛擬硬碟經過格式化後，就能進行檔案存取。

常見的RAID方案有RAID1、RAID5和RAID6。RAID1是將兩顆硬碟存放相同內容，因此會浪費一半的硬碟空間。若要擴充，必須以兩顆硬碟為單位加入。

RAID5則使用一顆硬碟作為校驗盤，換取更大的可用容量，所以五顆硬碟的組合只佔用20%的空間。不過，RAID5有一些缺點，例如讀取檔案時需要多顆硬碟同時啟動，硬碟壞掉後復原過程較長且有失敗風險。RAID6則適用於超過五顆硬碟的情況，能提供更高的安全性。

另一種方式是JBOD，將多顆硬碟合併成一個大硬碟，但缺點是若有一顆硬碟損毀，整個虛擬硬碟的資料都會損毀。

以前，我使用JBOD管理下載機，但認為還有改進空間：

1. 若只需存取特定檔案，應該只有一顆硬碟啟動提供服務，其他硬碟保持休眠，以省電並延長壽命。
2. 若某顆硬碟損毀，我只想損失該硬碟上的檔案，其他硬碟仍能正常使用。

最近我發現了一個完美方案：mergerfs加上snapraid。

不同於RAID，mergerfs是一種特殊檔案系統，能將多個檔案系統合併成一個虛擬檔案系統。

假設我有三顆硬碟，分別格式化成ext4，並掛載到/mnt/disk{1,2,3}，使用mergerfs可將這三個掛載點合併成/mnt/storage，並包含所有資料夾和檔案。我也能直接對/mnt/disk1進行讀寫，不影響/mnt/storage的運作。當/mnt/disk1損毀，/mnt/storage的內容會減少為/mnt/disk{2,3}的總和。

以下是我的/etc/fstab設定，由於後續要設定snapraid，其中一顆硬碟為parity_disk：

```
UUID="528592ce-dcc2-4aaa-9f92-d27166edfdfc" /mnt/disk1 ext4 noatime,nodiratime 0 0
UUID="414d7b98-d278-4397-80ff-9f5b103623ac" /mnt/disk2 ext4 noatime,nodiratime 0 0
UUID="c3017979-34eb-421a-bb94-c4291b15ffa4" /mnt/disk3 ext4 noatime,nodiratime 0 0
UUID="8878733e-eba1-4f5c-9dab-aa1f08835fd9" /mnt/parity_disk1 ext4 noatime,nodiratime 0 0

/mnt/disk* /mnt/storage fuse.mergerfs cache.files=partial,dropcacheonclose=true,moveonenospc=true,defaults,allow_other,minfreespace=100G,fsname=mergerfs,category.create=mspmfs,nonempty,noatime 0 0
```

我將category.create設為mspmfs，因為希望同一個torrent下載的檔案存放在同一硬碟，避免分散到多顆硬碟上。

mergerfs的另一個優點是硬碟容量不需一致。假設硬碟組合為4T、8T、12T，總可用空間即為24T。

mergerfs的小缺點是在移動檔案時，檔案不一定會落在同一硬碟上，跨硬碟操作會造成大量讀寫。處理此問題可以直接存取/mnt/disk*。使用qBittorrent時可能會遇到這個問題。

接下來是snapraid設定，與RAID的parity設計相似，但snapraid是非即時的，需手動觸發更新parity資料。適合寫入後不再改變的大型檔案。可設計小型暫存區，先複製檔案至RAID硬碟，更新parity後再刪除暫存檔案，避免遺失。

以下是我的/etc/snapraid.conf設定範例：

parity_disk須為RAID中最大硬碟。假設硬碟組合為4T、8T、12T，parity_disk須至少12T。

```
parity /mnt/parity_disk1/snapraid.parity
content /mnt/disk1/snapraid.content
content /mnt/disk2/snapraid.content
content /mnt/disk3/snapraid.content
data d1 /mnt/disk1/
data d2 /mnt/disk2/
data d3 /mnt/disk3/

exclude *.tmp
exclude *.temp
exclude *~
exclude Thumbs.db
exclude .DS_Store

exclude @Recycle/
exclude lost+found/
```

這樣就完成了一個適合多媒體檔案庫的自建NAS系統，硬碟可動態擴充，不需一次買齊，且能取得最佳性價比。