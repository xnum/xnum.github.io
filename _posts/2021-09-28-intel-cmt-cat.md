---
layout: post
title: Intel RDT支援試玩
date: 2021-09-28 00:00 +0800
categories: performance
---

Intel RDT是一組CPU上的last level cache(LLC)和memory bandwidth監控及管理技術

AMD也有支援同樣的技術但叫作Platform QoS

RDT包含了

- Cache Monitoring Technology (CMT)
- Memory Bandwidth Monitoring (MBM)
- Cache Allocation Technology (CAT)
- Code and Data Prioritization (CDP)
- Memory Bandwidth Allocation (MBA)

CMT可以監控cache misses和使用狀況
MBM可以監控使用的記憶體頻寬
CAT可以劃分特定區塊的LLC給core專用
CDP可以將LLC劃分為專門給code或data使用
MBA可以針對core指定可使用的記憶體頻寬上限

這系列技術主要可以用來在雲端上處理 noisy neighbor problem，提供使用者更精細的資源控制

intel也提供了[工具包](https://github.com/intel/intel-cmt-cat)來方便進行控制

我們以內附的工具pqos來實驗

---

`pqos -d`可顯示CPU支援的技術

```
Hardware capabilities
    Monitoring
        Cache Monitoring Technology (CMT) events:
            LLC Occupancy (LLC)
        Memory Bandwidth Monitoring (MBM) events:
            Total Memory Bandwidth (TMEM)
            Local Memory Bandwidth (LMEM)
            Remote Memory Bandwidth (RMEM) (calculated)
        PMU events:
            Instructions/Clock (IPC)
            LLC misses
    Allocation
        Cache Allocation Technology (CAT)
            L3 CAT
                CDP: disabled
                Num COS: 16
        Memory Bandwidth Allocation (MBA)
            Num COS: 8
```

`pqos -s -v`可顯示目前的參數和設定

裡面重要的資訊如下，如果沒有顯示則不支援

```
INFO: L3 CAT details: CDP support=1, CDP on=0, #COS=16, #ways=11, ways contention bit-mask 0x600
```

表示支援CDP，開啟後能設定LLC是給data還是code使用
COS則是classes of service，一共有最多16種可以設定
ways則是LLC有幾路能夠使用，最多11路

```
INFO: MBA details: #COS=8, linear, max=90, step=10
```

表示支援MBA，最多8個等級的COS，最多可以設定到90%

```
L3CA/MBA COS definitions for Socket 0:
    L3CA COS0 => MASK 0x7ff
    L3CA COS1 => MASK 0x7ff
    ...
    MBA COS0 => 100% available
    MBA COS1 => 100% available
    ...
```

這邊顯示每個COS等級對應的CAT和MBA設定
CAT 0x7ff是用bitmask的方式表示11路cache皆可使用
MBA 100%是記憶體頻寬最高允許使用到100%

```
Core information for socket 0:
    Core 0, L2ID 16, L3ID 0 => COS0, RMID0
    Core 2, L2ID 4, L3ID 0 => COS0, RMID0
    Core 4, L2ID 9, L3ID 0 => COS0, RMID0
    Core 6, L2ID 19, L3ID 0 => COS0, RMID0
    Core 8, L2ID 2, L3ID 0 => COS0, RMID0
    Core 10, L2ID 18, L3ID 0 => COS0, RMID0
    Core 12, L2ID 17, L3ID 0 => COS0, RMID0
    Core 14, L2ID 27, L3ID 0 => COS0, RMID0
```

每個核心的COS等級設定

---

如果想開啟CDP則執行

`pqos -R l3cdp-on` reset所有設定並開啟CDP

```
INFO: L3 CAT details: CDP support=1, CDP on=1, #COS=8, #ways=11, ways contention bit-mask 0x600
...
    L3CA COS0 => DATA 0x7ff, CODE 0x7ff
```

則COS會減半並在LLC能分別對DATA或CODE設定bitmask

---

使用`pqos -T`則會顯示類似top的畫面來監控使用情況

其中MISSES為LLC misses，MBL為本地頻寬，MBR為遠端頻寬 (numa架構下)

```
TIME 2021-09-28 13:15:59
    CORE         IPC      MISSES     LLC[KB]   MBL[MB/s]   MBR[MB/s]
      10        0.62          0k      3528.0         0.0         0.0
       9        0.37          1k      3384.0         0.1         0.0
       6        0.62          2k      3312.0         0.0         0.2
      14        0.41          2k      3312.0         0.0         0.1
       0        0.67          1k      3096.0         0.0         0.2
       2        0.81          6k      3096.0         0.0         0.8
       1        0.48          2k      2592.0         0.1         0.0
      12        0.47          1k      2592.0         0.0         0.1
       3        0.37          1k      2376.0         0.0         0.0
       4        0.65          1k      2304.0         0.0         0.0
      13        0.44          2k      2160.0         1.6         0.0
       8        0.69          1k      2088.0         0.0         0.0
      11        0.31          2k      2016.0         0.0         0.0
      15        0.37          2k      2016.0         0.0         0.2
       7        0.29          2k      1872.0         0.0         0.0
       5        0.41          2k      1368.0         0.0         0.0
```

---

下列範例設定為：

COS1可以使用8way、COS2使用3way
核心0,4,8,12設定為COS1
核心2,6,10,14設定為COS2

```
pqos -e 'llc:1=0x0ff;llc:2=0x700'

pqos -a 'llc:1=0,4,8,12;llc:2=2,6,10,14'
```

如需還原回預設值則使用`pqos -R`

---

設定完成後使用[STREAM benchmark](https://github.com/jeffhammond/STREAM)測試cache misses狀況

並執行`pqos -T`紀錄數據

以測試的CPU cache大小為參考：

L2 cache = 8 x 1MB
L3 cache = 24.75 MB

將array size設定為

Array size = 600000 (elements), Offset = 0 (elements)
Memory per array = 4.6 MiB (= 0.0 GiB).
Total memory required = 13.7 MiB (= 0.0 GiB).

重複執行次數為 140000

---

使用整顆CPU 8個thread執行：

`numactl --cpubind=0 --membind=0 ./stream_c.exe`

期間misses約為10k


使用一半 4個thread執行：

`numactl --cpubind=0 --membind=0 taskset -c 0,4,8,12 ./stream_c.exe`

期間misses約為1500k


同時執行兩個task 使用不同core執行：

`numactl --cpubind=0 --membind=0 taskset -c 0,4,8,12 ./stream_c.exe`
`numactl --cpubind=0 --membind=0 taskset -c 2,6,10,14 ./stream_c.exe`

期間misses約為30000~40000k


如設定COS後則為 13000k 和 80000k

記憶體頻寬部分在以上實驗則沒有顯著變化，CAT主要還是影響cache misses和latency

---

附錄

好奇11-way到底是怎麼來的，貌似是每個核心上面都有一塊L3，組成一大塊shared cache

在塞東西進LLC時就需要均勻分布上去，所以需要一個hash算法把資料擺上去又能避免衝突

經過一通神秘操作最後就不是通常看到的二的冪次了，但Intel沒有公布細節

所以也僅止於推測內部結構

ref:

[Cache Way Organization on Skylake ](https://community.intel.com/t5/Intel-Moderncode-for-Parallel/Cache-Way-Organization-on-Skylake/td-p/1135322?profile.language=zh-TW)
[Address Hashing in Intel Processors](https://www.ixpug.org/components/com_solutionlibrary/assets/documents/1538092216-IXPUG_Fall_Conf_2018_paper_20%20-%20John%20McCalpin.pdf)
