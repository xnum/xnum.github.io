---
layout: post
title: Google Search Console 驗證網站擁有者 使用網域驗證 踩坑
categories: [sys_admin]
description: 想把網站提交到Google上讓他索引，卻發現驗證一直失敗
---

想要把自己的網站提交到Google上讓他能被搜尋到，就需要去Search Console把自己的網站加進去，而且要證明自己是網站擁有者。

通常的情況下都可以使用Google Analytics的ID作為驗證手段。但不巧我部署的服務，他的GA Plugin把js程式碼擺在body裡面，而Google只認放在head裡面的程式碼，所以這個方法失敗了。

當然還有其他辦法，例如：上傳一個特定的檔案，或是在網頁的head裡面埋一段特定的資料。因為我用Docker部署服務，如果要做這種改動，往後的維護會比較麻煩。所以我決定用網域驗證的方式：寫入一段特定的TXT記錄到DNS紀錄上，如果Google能看到該紀錄就代表你擁有該網域。

如果你使用cloudflare提供DNS伺服器的服務，在驗證網頁上Google可以幫你自動帶入設定值並導向到cloudflare的網站上，免除設定上的麻煩。但這個自動帶入的設定值是有問題的。假設我今天想驗證的網站是<https://coll.xnum.in>。在自動帶入的設定值裡面，是針對`@.xnum.in`的TXT紀錄，而不是針對`coll.xnum.in`的TXT紀錄，所以驗證時永遠會失敗。

解決方法就是在驗證時，選擇其他Provider，並手動設定TXT紀錄，就不會遇到問題。