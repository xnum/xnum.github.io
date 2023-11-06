---
layout: post
title: Rob Pike的五條程式設計規則
categories: [dev, 文摘]
description: Rob Pike近代最為人所知的應該是Go語言的核心開發者，這邊是他歸納的五條程式設計規則
---

From: <https://users.ece.utexas.edu/~adnan/pike.html>

> Rob Pike's 5 Rules of Programming

> Rule 1. You can't tell where a program is going to spend its time. Bottlenecks occur in surprising places, so don't try to second guess and put in a speed hack until you've proven that's where the bottleneck is.

不要嘗試猜測效能瓶頸，過早進行效能最佳化，因為他們經常出現在意想不到的地方。

> Rule 2. Measure. Don't tune for speed until you've measured, and even then don't unless one part of the code overwhelms the rest.

先測量速度。再開始最佳化。 

> Rule 3. Fancy algorithms are slow when n is small, and n is usually small. Fancy algorithms have big constants. Until you know that n is frequently going to be big, don't get fancy. (Even if n does get big, use Rule 2 first.)

當發現n足夠大，才改用更精巧的演算法。

> Rule 4. Fancy algorithms are buggier than simple ones, and they're much harder to implement. Use simple algorithms as well as simple data structures.

盡可能地使用簡單的演算法和資料結構。

> Rule 5. Data dominates. If you've chosen the right data structures and organized things well, the algorithms will almost always be self-evident. Data structures, not algorithms, are central to programming.

選擇正確的資料結構才是重點。

---

我認為這邊的精神其實是「盡量推遲無法逆轉的決策」。進行效能最佳化以後會增加程式碼閱讀理解的難度，後面要再修改也就更加困難。使用更精巧的演算法也是相同的道理。因此在開發時盡量的保持簡單易懂是很重要的。

這也很好的體現在Go語言上。首先它內建的資料結構只有array (slice)和map (hash table)。然而這兩種資料結構就可以實作絕大部分的程式。只有非常少的部分需要引入如stack、heap、queue...等等。而且使用這些資料結構也僅是加快速度，在程式的正確性上是沒有差別的。另外也可以從Go語言的語法簡潔性看出，整體的設計哲學就是希望他保持簡單。