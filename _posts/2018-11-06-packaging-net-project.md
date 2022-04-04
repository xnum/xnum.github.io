---
layout: post
title: .net應用程式的CI/CD心得
date: 2018-11-06 22:56 +0800
categories:
- .Net
---

最近嘗試把project加上CI及CD的設定，主要目標是能把source code自動build出執行檔，並deploy到GitHub releases，省去人工的麻煩也減少執行檔被加料的可能性。

我使用的是AppVeyor，對Windows Project的支援性我覺得不錯。

中間解決了幾點問題：

### Build Target

我使用MSBuild，但他可能會發現project拉下來有好幾個csproj檔，所以無法自動編譯。

我在Visual Studio裡面先設定好project的dependency，然後測試一下 __重建專案__ 發現可行，就把project的solution  file設定成該sln檔，ci build下去果然成功。

### Missing reference

大部分第三方套件如果用NuGet套件管理來引用的話會方便許多，在build之前執行`nuget restore`，就可以輕鬆搞定dependency，但在我的project裡用到一些COM dll檔，在CI時其實不需要把整個dll丟進去。

build專案時可以在bin/Debug/底下發現這些dll都有一個Interop.XXX.dll，這個概念有點類似函式庫只提供介面而沒有提供實作，Interop.XXX.dll就是程式和XXX.dll間溝通的橋樑，他們在build專案時會被產生出來並被複製到build的目錄底下，所以丟給CI build的時候，project裡用到office的COM dll，就算build環境中沒有安裝office，只要設定正確讓project引用到的是Interop版本就可以編譯成功了。

具體的修改可以參考這個[commit](https://github.com/xnum/BeanfunLogin/commit/fefb71532e0968ca4a35eb1f66a5de47070aa23d?diff=split#diff-e27161f96fb33c3295fbcfce27eb0f8b)

### DLLs

build出來的執行檔還會帶有幾個引用到的套件編譯出來的dll檔，在發行時需要壓成一個zip檔提供給使用者，其實NuGet的套件中就有一個ILMerge.Task能在編譯中自動加入把dll檔合併到exe檔的步驟，就不需要自己在CI的setting中額外編寫script來達成。

### MSI Installer

單純的執行檔沒有偵測作業系統和.net framework版本的功能，也不能添加一些桌面捷徑，透過封裝成安裝檔可以幫忙做到這些事情。比較流行的工具是Wix Toolset，因為版本眾多，有時候Google到比較古老的解法可能無法套用。進階一點還可以針對不同語言編寫不同文字，不過我是有點懶，具體修改可以參考這個[commit](https://github.com/xnum/BeanfunLogin/commit/2c3c2f1ce1ec4a96c18b9e35f6eb420371705ece)



