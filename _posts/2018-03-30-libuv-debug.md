---
layout: post
title: 記一次libuv採坑除錯記
categories:
- dev
---

自行開發的程式在進行壓力測試的時候

經過一段時間會噴出too many open files的錯誤，開啟的fd已經達到系統上限

從/proc/[pid]/fd查看，大部分是開啟的檔案未關閉

連線關閉時的錯誤處理，在關鍵function上有多條選項，不易從log分析

```
switch(status)
{
  case A:
    uv_close(c->A);
    break;
  case B:
    uv_cancel(c->B);
    break;
  case C:
    uv_close(c->C);
    break;
  default:
    release(c);
}
```

因此在原始碼編譯加入coverage選項，來分析可能的問題執行路徑

結果發現已開啟fd約5xx個時，`case C`已執行11xx次，而其他選項皆未執行或個位數

往下追蹤該handle (fs_poll_t)的callback function

發現執行次數為0次：呼叫uv_close後並不會執行callback function

因此不會執行callback function裡後續的資源釋放動作


在libuv API文件中說明uv_close對於In-progress request會取消並返回UV_ECANCELED

但`fs_poll`不會發生這個行為，解決方法是呼叫`uv_fs_poll_stop`後主動釋放資源

修正後在200 concurrent connection下的fd數量約維持在250~280
