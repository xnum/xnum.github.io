---
layout: post
title: 應用Jump Table加速function跳轉
categories: [C/C++]
description: Jump Table是一種branchless技巧
---

## 簡介

Jump Table (或Branch Table)是一種程式撰寫技巧，它和Lookup Table類似，都是藉由Table儲存結果的方式來減少計算量或分支程式碼(if-else, switch-case)。不同之處在於Jump Table的結果儲存的是function pointer，而Lookup Table儲存的是值。

Table可以用array或是map的方式實作。array的實作通常會受限於其輸入的值域，當輸入的範圍是1-100時，可以簡單地宣告一個長度100的陣列來儲存。如果輸入的範圍可能是1-10000000時，使用同樣的方式會相當浪費空間。如果輸入的範圍很大，但實際會出現的值，其集合相當小(例如只會出現1, 10, 100, 1000, 10000)，這時我們可能需要仔細分析是否能找到一個function壓縮輸入範圍到可接受的程度。
但map的存取時間複雜度會更高，因此使用map時更需要仔細橫量是否真的有得到更好的結果。

大部分的情況下使用if-else或switch-case在可讀性上會比較友好，但Table相對來說有可能換來較好的效能。因為我們可以藉由它消除branch來避免pipeline hazard。而在無法使用branch的場合，例如：用SIMD指令集實作時，這也成為一個常用的技巧。

接下來我們看幾個套用Jump Table技巧的例子

## 範例

### 查表法

這是最簡單的用法，使用map來處理任意的key值。需要注意的是他的存取時間不是O(1)，再加上cache data locality問題，因此在效能最佳化上有可能會打折扣。

```cpp
inline CurrencyType toCurrency(const std::string &c)
{
  static std::map<std::string, CurrencyType> currencies = {
    {"NTD", CurrencyType::NTD},     {"TWD", CurrencyType::NTD},
    {"USD", CurrencyType::USD},     {"EUR", CurrencyType::EUR},
    {"JPY", CurrencyType::JPY},     {"GBP", CurrencyType::GBP},
    {"AUD", CurrencyType::AUD},     {"HKD", CurrencyType::HKD},
    {"RMB", CurrencyType::RMB},     {"ZAR", CurrencyType::ZAR},
    {"KRW", CurrencyType::KRW},     {"SGD", CurrencyType::SGD},
    {"CAD", CurrencyType::CAD},     {"SEK", CurrencyType::SEK},
    {"CHF", CurrencyType::CHF},     {"NZD", CurrencyType::NZD},
    {"THB", CurrencyType::THB},     {"PHP", CurrencyType::PHP},
    {"IDR", CurrencyType::IDR},     {"MYR", CurrencyType::MYR},
    {"VND", CurrencyType::VND},     {"CNY", CurrencyType::RMB},
  };

  if(auto it = currencies.find(c); it != currencies.end()) {
    return it->second;
  }

  return CurrencyType::MAX;
}
```

### Fixed Point Number

定點數相較於浮點數，它使用整數來模擬實數。我們需要定義一個整數中有哪些部分用來表示小數點，假設要使用一個32位整數，並且他有3位小數點，那可表示的範圍就是`2147483.647 ~ -2147483.648`。實際的使用場景出現在貨幣或價格的計算上，我們可以預期貨幣或價格的小數點是有限且固定的，而且不希望有浮點數的誤差問題，就會使用這種特殊的數字表示方式。

以下列的程式碼為例，在class內部約定儲存時固定有4位的小數點。value()需要根據輸入的參數給出固定有N位小數點時的定點數結果。因此decimalLocator為4時應該直接輸出，為0時應該除以10000來消除所有小數再輸出，以ChatGPT提供的實作大致如下：

```cpp
class FixedPointNumber {
private:
    int64_t value_;

public:
    FixedPointNumber(int64_t value) : value_(value) {}

    int64_t value(int8_t decimalLocator = 4) const {
        if (decimalLocator < 0 || decimalLocator > 4) {
            std::cerr << "Invalid decimalLocator value. It should be in the range of 0 to 4." << std::endl;
            return 0;
        }

        int64_t scale = 1;
        for (int i = 0; i < decimalLocator; ++i) {
            scale *= 10;
        }

        return value_ / scale;
    }
};
```

在這裡他使用了一個迴圈和多次乘法來實作功能，如果改用Lookup Table的話結果如下：

```cpp
class FixedPointNumber {
public:
  inline int64_t value(uint8_t decimalLocator = 4) const
  {
    assert(0 <= decimalLocator && decimalLocator <= 4);

    return value_ / decimalShiftTable_[decimalLocator];
  }

private:
  static inline int64_t decimalShiftTable_[5] = {10000, 1000, 100, 10, 1};
  int64_t value_{};
```

我們可以藉此消除迴圈和乘法。

###  Jump Table

如果有一個判斷輸入並執行特定動作的功能，通常我們可以用if或switch來實作，如下：

```cpp
int main() {
    int choice;

    // 請使用者輸入 0、1、2、3 中的一個數字
    std::cout << "請輸入 0 表示向上，1 表示向下，2 表示向左，3 表示向右：";
    std::cin >> choice;

    // 使用跳躍表來呼叫對應的函數
    switch (choice) {
        case 0:
            up();
            break;
        case 1:
            down();
            break;
        case 2:
            left();
            break;
        case 3:
            right();
            break;
        default:
            std::cout << "無效的選擇" << std::endl;
            break;
    }

    return 0;
}
```

你可以使用一個array來實作Table，以簡化這段程式碼：

```cpp
int main() {
    int choice;

    // 請使用者輸入 0、1、2、3 中的一個數字
    std::cout << "請輸入 0 表示向上，1 表示向下，2 表示向左，3 表示向右：";
    std::cin >> choice;

    // 定義一個函數指針陣列，將輸入值映射到函數
    std::function<void()> functions[] = {up, down, left, right};

    if (choice >= 0 && choice < 4) {
        // 如果輸入值有效，則呼叫相應的函數
        functions[choice]();
    } else {
        std::cout << "無效的選擇" << std::endl;
    }

    return 0;
}
```

在這個case中很幸運的是輸入的值非常小，因此你的array長度只有4。當輸入為`(10, 20, 30, 70, 90)`的時候這樣做可能不會帶來比較好的結果，其一是浪費空間，其二是破壞了cache的data locality可能導致較差的效能。

要應對這樣的case，我們還可以透過bitwise的方式暴力尋找特徵。簡單的說就是尋找一個function讓`(10, 20, 30, 70, 90)`可以對應`(0-3)`或`(0-7)`或`(0-15)`。這三種範圍分別對應了從64bits中選擇2、3、4bits。然而實際範圍可能不會是64bits，以上面為例，90則代表有效範圍是7bits，更大的bit都是0。

透過如下的程式可以幫我們暴力找出所有可行的組合

```cpp
#include <algorithm>
#include <bitset>
#include <cstdio>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

// uint8_t inputs[] = {10, 30, 41, 50, 102, 103, 104, 105, 112, 114};
// uint8_t inputs[] = {10, 30, 41, 50};
// uint8_t inputs[] = {102, 103, 104, 105, 112, 114};
uint8_t inputs[] = {'3', '4', 'A', 'B', 'C', 'D', 'E'};
size_t length = sizeof(inputs);
constexpr size_t bits_size = sizeof(inputs[0]) * 8;

vector<size_t> find_indexes()
{
  vector<size_t> result;

  for(size_t i = 0; i < bits_size; i++) {
    bool allSame = true;
    bitset<bits_size> bs1(inputs[0]);
    for(int j = 1; j < length; j++) {
      bitset<bits_size> bs2(inputs[j]);

      if(bs1[i] != bs2[i])
        allSame = false;
    }

    if(allSame == false) {
      result.push_back(i);
    }
  }

  return result;
}

void show_bitmask(string bitmask)
{
  bitset<bits_size> bs;
  cout << "============" << endl;
  cout << "bitmask: ";
  for(size_t i = 0; i < bitmask.size(); i++) {
    if(bitmask[i]) {
      cout << i << " ";
      bs[i] = true;
    }
  }
  cout << endl;
  cout << "binary form: " << bs << endl;

  for(int i = 0; i < length; i++) {
    stringstream ss;
    bitset<bits_size> bs(inputs[i]);
    bitset<bits_size> nbs;

    int k = 0;
    for(int j = 0; j < bitmask.size(); j++) {
      ss << "[" << j << ":" << bs[j] << "]: ";
      if(bitmask[j]) {
        nbs[k] = bs[j];
        ss << bs[j];
        k++;
      }
      else {
        ss << "X";
      }

      ss << "  ";
    }

    cout << i << ": " << inputs[i] << "\t";
    cout << ss.str() << "\t" << nbs << "\t" << nbs.to_ulong();
    cout << endl;
  }
}

int main()
{
  printf("lookup lut for bit_size: %ld in the following set\n", bits_size);
  for(size_t i = 0; i < length; i++) {
    bitset<bits_size> bs(inputs[i]);
    cout << i << ": " << int(inputs[i]) << "\t" << bs << endl;
  }

  auto indexes = find_indexes();
  cout << "index candidates: [";
  for(const auto &idx : indexes) {
    cout << idx << ",";
  }
  cout << "]" << endl;

  auto maxElement = *max_element(indexes.begin(), indexes.end());
  cout << "max element: " << maxElement << endl;

  for(int i = 1; i < indexes.size(); i++) {
    auto max = 1ULL << i;
    // cout << "use " << i << "bits has range 0~" << max - 1 << endl;

    if(max < length) {
      cout << i << " bits can't presents set size " << length << endl;
      continue;
    }

    cout << "try use " << i << " bits" << endl;

    const auto K = i;
    const auto N = maxElement;
    std::string bitmask(K, 1); // K leading 1's
    bitmask.resize(N, 0); // N-K trailing 0's

    do {
      set<size_t> exists;
      // check every input transform to picked bits not conflicts.
      for(int i = 0; i < length; i++) {
        size_t v = 0;

        // pick bits.
        for(int j = 0; j < N; ++j) // [0..N-1] integers
        {
          // if (bitmask[i]) std::cout << " " << i;
          if(bitmask[j])
            v |= inputs[i] & (1 << j);
        }

        exists.insert(v);
      }

      if(exists.size() == length) {
        show_bitmask(bitmask);
        return 0;
      }
    } while(std::prev_permutation(bitmask.begin(), bitmask.end()));
  }

  cout << "no result found" << endl;

  return 0;
}
```

實際案例如下，我們想將`(10, 30, 41, 50)`放到Table，經過bitwise操作提取其中的3個bits以後，就可以把array長度壓縮到8了。

```cpp
static HandleFnPtr table[8] = {
/* 0 */ &ClientConnection::noop,
/* 1 */ &ClientConnection::handle50,
/* 2 */ &ClientConnection::noop,
/* 3 */ &ClientConnection::noop,
/* 4 */ &ClientConnection::handle41,
/* 5 */ &ClientConnection::handle10,
/* 6 */ &ClientConnection::noop,
/* 7 */ &ClientConnection::handle30,
};

inline size_t CodeToIndex(uint32_t code)
{
  // use 3 bits.
#define toIndex(x) ((((x)&0x0E) >> 1) & 0x07)

  static_assert(toIndex(10) == 5);
  static_assert(toIndex(30) == 7);
  static_assert(toIndex(41) == 4);
  static_assert(toIndex(50) == 1);

  return toIndex(code);
#undef toIndex
}
```

## 結論

文中提及了三個使用Table加速技巧的案例，這是在利用SIMD撰寫加速演算法時常用的技巧，像是[base64編碼解碼](http://0x80.pl/notesen/2016-01-12-sse-base64-encoding.html#pshufb-based-lookup-method)就可以用LUT方法加速。除此之外他也可以應用來簡化程式碼或預先建表加速計算。

