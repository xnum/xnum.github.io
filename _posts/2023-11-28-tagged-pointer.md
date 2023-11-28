---
layout: post
title: Tagged Pointer原理及其應用
categories: [dev]
description: Tagged Pointer是一種把資料儲存在指標裡的技巧
---

在現代的 x86-64 CPU 架構中，指標的大小為 64 位元，但 CPU 支援的記憶體位址範圍並不完全達到 64 位元，實際上目前只支援到 48 位元的虛擬位址。這意味著我們可以利用剩餘的 16 位元（64 - 48）來存儲額外的資料，只需在實際存取記憶體前將這些額外資料移除。

此外，記憶體對齊（memory alignment）是另一個關鍵因素。為了獲得更高的存取效率，記憶體地址需要按照一定的邊界對齊。例如，在 64 位元 CPU 上，記憶體地址會對齊到 8 Bytes（即 64 位元）邊界。這導致記憶體分配器不會分配像 0x12341111 這樣的地址，而會分配像 0x12341110 這樣對齊的地址。因此，在 64 位元 CPU 上，地址的最低 3 位元（對應於 8 Bytes對齊）不會被使用。這樣的對齊策略進一步提升了記憶體存取的效率，並為指標上的資料標記提供了可能性。

這適用於某些特殊的場景，例如：

1. 垃圾收集和記憶體管理：在一些垃圾收集演算法中，tagged pointers 可以用來標記對象的狀態，如是否已被訪問或是否可回收，這有助於優化記憶體回收過程。
2. 鎖和同步機制：用於Lock-Free Data Structure。在指標中嵌入狀態或版本信息，可以避免使用昂貴的鎖機制，從而提高性能。
3. Cache Friendly Data Structure：在設計快取優化的數據結構時，減少每個元素的大小可以提高快取效率。使用 tagged pointers 可以在不影響整體結構大小的前提下，儲存額外的資料。

<https://muxup.com/2023q4/storing-data-in-pointers>
<https://github.com/golang/go/blob/master/src/runtime/tagptr_64bit.go>
