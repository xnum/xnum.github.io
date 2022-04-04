---
layout: post
title: putty遠端列印Big5中文文字
categories:
- 筆記
---

古老的terminal支援將螢幕上顯示的文字直接傳送到印表機的功能

透過一對[控制碼](https://www.censoft.com/support/kb/?p=938)來開關

例如一些報表或系統資訊在遠端主機上產生後列印的場合，就會使用到這項功能

在putty(及大部分模擬終端軟體?)，都是以raw模式呼叫WritePrinter直接把bytes送出去

不經由driver時，列印中文字需要印表機內建中文字體才支援

如果raw模式不支援純文字的中文列印時，我們可以拐個彎送出PS或PCL格式的文件來達成這個功能

```
Text -> PS -> PCL -> 印表機
```

## BIG5 Text to PostScript

使用[bg5ps](https://www.rpmfind.net/linux/RPM/mandriva/2007.0/i586/media/main/release/bg5ps-1.3.0-9mdk.i586.html)進行轉換

由於rpm太多相依性了，但bg5ps本身是簡單的python scripts，我直接把他解壓縮出來

```
$ rpm2cpio xxx.rpm | cpio -idmv
```

接著進行設定

```
$ cp etc/chinese/bg5ps.conf ~/.bg5ps.conf (來源檔為剛剛解壓縮出來的檔案)
$ vim ~/.bg5ps.conf (設定轉換配置)
```

#### bg5ps.conf 範例配置

```
#chineseFontPath: 指定中文字型的路徑(預設值: 與 bg5ps 同)
chineseFontPath="/opt"

#modify the above line

#fontName: 指定中文字型的檔案名稱(預設值: ntu_kai)
#fontName="ntu_kai.ttf"
fontName_big5="NTU_KAI.TTF"

#oddPages: 0 不輸出奇數頁，1 輸出奇數頁(預設值: 1)
#true=1, false=0
oddPages=true

#evenPages: 0 不輸出偶數頁，1 輸出偶數頁(預設值: 1)
evenPages=true

#size: 指定輸出字型的大小(預設值: 12)
size=8.0

#     leftMargin: 指定左邊界(預設值: 72.0)
#     rightMargin: 指定右邊界(預設值: 72.0)
#     topMargin: 指定上邊界(預設值: 72.0)
#     bottomMargin: 指定下邊界(預設值: 72.0)
topMargin=72.0
bottomMargin=72.0
leftMargin=72.0
rightMargin=72.0

#lineSpace: 指定行距(預設值: 6.0)
lineSpace=9.0

#chrSpace: 指定字距(預設值: 2.0)
chrSpace=5.0

#Encoding: 指定編碼
#       big5,gb2312
Encoding="big5"
```

[預設的字體](http://ftp.kh.edu.tw/Linux/CLE/fonts/ttf/big5/ntu/NTU_KAI.TTF)

執行轉換

```
$ bg5ps -if test.txt -of test.ps
```

## PostScript to PCL6 

PCL6也稱PCL/XL，為HP公司發展的列印用標準，如果是PostScript的印表機就可以把ps檔直接送去列印了

PS -> PCL6需要安裝ghostscript進行轉換，如果要直接轉換，執行以下指令

```
$ gs -sDEVICE=laserjet -o test.pcl test.ps
```

或是先轉換成PDF格式檢查輸出再轉換

```
$ gs -sDEVICE=pdfwrite -o test.pdf test.ps
$ gs -sDEVICE=laserjet -o test.pcl -f test.pdf
```

## 最後把產生的pcl檔直接送給印表機

```
!#/usr/bin/env bash
echo -e "\033[5i"
cat test.pcl
echo -e "\033[4i"
```
