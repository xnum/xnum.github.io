---
layout: post
title: Perforce共享原始碼設定方法
categories:
- 筆記
---

Perforce裡的depot類似一個repository

預設設定client mapping到depot的根目錄

修改view mappings可以靈活的調整目錄結構

假設有個depot `Project1` 底下有 `src` `doc` `test`

而我的client在家目錄名稱為`xnum_p1` 

client的view設定為

//Project1/... //xnum_p1/...

把整個Project拉下來後目錄結構會是

```
~/xnum_p1/src/ 
~/xnum_p1/doc/
~/xnum_p1/test/
```

如果今天把Project1分成兩個子專案，叫pa和pb

- Project1
  - pa
    - src
    - doc
    - test
  - pb
    - src
    - doc
    - test
    
且pa和pb共用一個include資料夾的話，就要開兩個client 

```
client: xnum_pa
view:
//Project1/pa/... //xnum_pa/...
```

```
client: xnum_pb
view:
//Project1/pb/... //xnum_pb/...
//Project1/pa/include/... //xnum_pb/include/...
```

當然也可以跨depot使用，如果include資料夾獨立成專案Project2下的include資料夾的話

```
client: xnum_pa
view:
//Project1/pa/... //xnum_pa/...
//Project2/include/... //xnum_pa/include/...
```

```
client: xnum_pb
view:
//Project1/pb/... //xnum_pb/...
//Project2/include/... //xnum_pa/include/...
```

這樣在pa或pb下修改的檔案都會對應到同一個地方

順帶一提，Perforce對檔案預設是444，利用指令修改屬性

`p4 edit -t text+w *`

就不用每次在修改前還要用`p4 edit`開啟了

修改後用`p4 reconcile` + `p4 submit`

用起來就方便多了
