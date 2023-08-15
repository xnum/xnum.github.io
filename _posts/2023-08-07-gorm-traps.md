---
layout: post
title: gorm的FirstOrCreate陷阱
categories: [golang]
---

gorm的用法最近越來越多元，針對進階的語法更容易搞錯，對於這段code

```
var info Info
err := tx.Where("user_id = ?", req.UserID).FirstOrCreate(&info).Error
```

乍看之下會自動建立一個填好UserID的info物件。

但結果是當其不存在時會建立一條空紀錄。

因為info內容是全空的，而where條件不是使用map或struct造成這個差異。

比較容易閱讀的處理方式應該是先填好info：

---

另外`Find()`好像也增加了用法，可以傳struct進去，而且找不到的時候不會回傳error

太信任對gorm的理解程度而沒有寫測試好像是個大雷區

---

2023/08/15

```
var b3 *Animal
err = conn.Where("age = '33'").First(b3).Error
assert.NoError(err)
assert.Equal("Bear", b3.Name)
```

傳入一個有型別的nil pointer會導致爆炸 要改成`b3 := &Animal{}`

`invalid value, should be pointer to struct or slice`
