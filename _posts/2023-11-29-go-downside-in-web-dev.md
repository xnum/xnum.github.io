---
layout: post
title: Go在後端開發的不足之處
categories: [golang]
description: 談一些開發實際會遇到的狀況
---

Go的語法簡潔，卻又提供你很多創作上的可能性。他不像其他語言為了支援某種風格在語法層面上不斷增加新的用法。因此閱讀不會帶來太大的麻煩。隨之而來的是不同工程師寫出來的風格差異很大。你或許看過C-style的procedural風格、非同步callback方式的RxGo、物件導向式的Go。在這篇文章我會分享以Golang標準庫風格開發時，在後端應用遇到的狀況。

## Dynamic Data

Go對於太靈活的資料有某種先天適應不良，當然你也可以說是API設計者的問題。讓我們看這個例子：

```
{
    "src": "us-west-1",
    "TW": 1.5,
    "JP": 3,
    "HK": false,
    "US": null,
}
```

其中`src`會固定存在，但底下的country code和數值是動態的。顯然你沒有辦法用struct來當成unmarshal載體。當你選擇用map時，則會面臨各種type assertion的額外程式碼。可以說當你選擇了`map[string]any`時，相關的程式碼處理就註定了不會太簡潔。

## Framework

有如PHP之於Laravel、Python之於flask。Go還沒有一個主宰市場的框架存在。我也在持續的關注開發圈的動態，但似乎還沒有一款穩定成熟的框架，是在職缺描述上直接指定要熟悉它的。當然這並不是壞事，但也代表不同團隊可能有自己的風格和規範，在上手時需要花時間在這方面。

## Packaging

官方對於Package Naming希望你以功能為主軸出發，而不是無意義的common name。舉例來說如果你有一個models package，裡面有user和order兩個struct，分別被不同的controller使用。實際上這兩個struct並沒有一定要放在一起的必要，因此models的劃分方式只是單純的進行分類，而沒有考量程式碼間的聚合力。或許你會做出`models/user`，但這也代表你非常有可能再出現一個`controllers/user`，這時候下游如果要import時就會遇到renaming的困擾。那何不將其合併為`user`就好呢？

當你這樣做之後，在package上便有domain劃分的問題。舉例來說我想要新增個人資料管理和業務業績管理的功能，我想你顯然不會把這些功能都塞進`user`裡面，否則`user`最終會成為一個God-like package。如果你選擇新增兩個package叫`personal`和`sales`的話，這時候可能發生的狀況是：

前端同時想要在list user時知道他是不是業務 and 想要在list業務時帶出他的名字：由於你只能從`sales` import `user`或從`user` import `sales`，因此這變成無法兩全的狀況。所以你可能想要新增一個下游包`controller`去同時import `user`和`sales`，並透過某些方式處理資料：

1. 雙方都寫interface，由`controller`將對方的實作以interface的方式送進去
2. 在`controller`層呼叫兩方並自己組合資料
3. 拉了一個額外的包把需要的`user`和`sales` struct放在一起 （這回到了剛才提到的models問題）

這兩種方式都無可避免的，需要額外的程式碼來處理這個狀況。而第三種方式是最簡單也下意識會使用的，然而他很容易打破domain間的藩籬並為程式碼架構帶來混亂。

## Architecture

當我們想要遵守前面的Package規範來處理程式碼的聚合力(或者說邊界)時，架構的設計會更複雜。就以最流行的MVC來說，你可能下意識的定義了`models`、`controllers`、`views`。而當程式碼成長到某個規模才會發現邊界不明確帶來的困擾。如果你有意識的想進行切分，這就像是將每個package都假想為一個microservice進行DDD，沒有切在正確的維度會導致Package間有大量的交互，使得前面提到的`額外的程式碼`會非常多。

