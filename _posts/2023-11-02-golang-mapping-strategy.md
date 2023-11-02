---
layout: post
title: 在Golang實作架構層的映射策略(mapping strategy)
categories: [golang]
description: 映射策略是架構層邊界的資料對應策略，使不同層級間能保持清晰的邊界
---

本文內容參考《Clean Architecture實作篇：在整潔的架構上弄髒你的手》以及自身的開發經驗分享。

## TL;DR

如果你剛開始寫Golang。當你學習了gorm和gin，而他們都不約而同的要你定義一個struct，例如：

```go
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

而你開始思考[field tag](https://stackoverflow.com/questions/10858787/what-are-the-uses-for-struct-tags-in-go)應該要放在同一個struct裡面，還是放在不同的struct裡面，我的建議是：

### 1. 先定義一個給gorm用的struct

```go
type User struct {
    ID       uint   `gorm:"not null;primaryKey;autoIncrement"`
    Name     string `gorm:"not null"`
    Email    string `gorm:"not null;unique"`
    Password string `gorm:"not null"`
}
```

### 2. 針對給gin用的response使用同一個struct

簡單說就是你會拿去`ctx.JSON(200, user)`的那個

```go
type User struct {
    ID       uint   `gorm:"not null;primaryKey;autoIncrement" json:"id"`
    Name     string `gorm:"not null"                          json:"name"`
    Email    string `gorm:"not null;unique"                   json:"email"`
    Password string `gorm:"not null"                          json:"-"`
}
```

### 3. 針對給gin用的request使用一個專門的struct

```go
type UpdateUserEmailRequest struct {
    Email string `json:"email" binding:"required,email"`
}

func main() {
    router := gin.Default()

    router.POST("/update-email", func(c *gin.Context) {
        var request UpdateUserEmailRequest

        if err := c.ShouldBindJSON(&request); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        db := mustGetDB()
        user := mustExtractUser(c)

        if err := updateUserEmail(db, user, request.Email); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusOK, gin.H{"message": "ok"})
    })
}
```

這樣做的原因是：response的修改通常是DB和API一起的。而request不總是單純的CRUD，有可能無法對應到response上，所以獨立定義新的struct。這樣的邏輯通常已經能支持中小型專案規模的發展。


## Mapping Strategy

無論是最經典的MVC架構，還是流行的clean架構，一旦你的程式碼開始有架構的概念，就不免會遇到介面定義的問題。廣義的來說，定義介面就是定義了一組function，以及該function的輸入輸出。而所謂的輸入輸出就是資料模型，可以是一個struct、一個array甚至是一個int。

來思考一個簡單的例子，現在我定義了一個struct用來當作gorm的model：

```go
type User struct {
    ID       uint   `gorm:"not null;primaryKey;autoIncrement"`
    Name     string `gorm:"not null"`
    Email    string `gorm:"not null;unique"`
    Password string `gorm:"not null"`
}
```

現在多了一個需求是：顯示User列表時，不要顯示名字，所以你做了這個修改：

```go
    Name    string `gorm:"not null" json:"-"`
```

很好，現在看不到了。但你也得到了一個副作用：這個struct被賦予了一個不屬於他的任務。如果又剛好沒有單元測試，而且因為其他的需求而不小心被修改，那這個功能就有可能損壞。

所以說我們應該把每一層的struct都個別定義嗎？也不盡然，這取決於你的程式複雜度和架構。也就是說當程式足夠簡單時，你仍然可以考慮少寫點程式碼，在新的需求導致程式變動時再進行重構。

### No Mapping

剛才提到的第一個例子就是No Mapping策略，也就是所有層級都使用同一個struct來操作，也是最簡單的方式。

```go
type User struct {
    ID       uint   `gorm:"not null;primaryKey;autoIncrement" json:"id"`
    Name     string `gorm:"not null"                          json:"name"`
    Email    string `gorm:"not null;unique"                   json:"email"`
    Password string `gorm:"not null"                          json:"-"`
}
```

### Two-Way Mapping

這指的是在不同層級間，資料模型可以進行雙向轉換。以clean arch來說，領域層(或業務邏輯層)的地位會比較高，而DB層或api層會負責實作轉換程式。

```go
package entity

type User struct { ID uint ... /* no tag */ }
```

DB層就可以專心於自己的職責

```go
package db

type gormUser struct { ID uint `gorm:"primarykey"` ... }
func (u *gormUser) BeforeSave(*gorm.DB) error
func (u *gormUser) ToUser() *entity.User
func (*GormRepository) SaveUser(*entity.User) error
func (*GormRepository) GetUser(id uint) (*entity.User, error)
```

這樣的好處是概念非常的明確簡單，但也有隨之帶來的壞處，一是會產生大量重複的程式碼，二是內層資料模型還是容易受到外層的影響，因為資料模型被拿來當成一個輸入輸出的參數。

### Full Mapping

為了處理Two-Way Mapping帶來的問題，Full Mapping是將介面上的輸入輸出都定義一個專門的物件

```go
package entity

type User struct { ... }
type ChangePasswordRequest { ID uint, password string }
type ChangeUserNameRequest { ID uint, name string }
type SingleUserRequest { ID uint }
func (SingleUserRequest) Validate() error

func ChangePassword(req ChangePasswordRequest) error
func ChangeUserName(req ChangeUserNameRequest) error
func DeleteUser(req SingleUserRequest)
```

這樣做的話在介面上最為明確，完全沒有含糊的空間。如果在與API層的互動上這樣實作的話更為恰當，因為參數的欄位和檢驗都可以有專門負責的struct。也可以用來凸顯可用的命令，比如說ChangePassword和ChangeUserName，內部的邏輯很可能不一致，如果只用UpdateUser來實作的話這個function也未免太不清不楚了。

但在與DB層的互動上如果這樣做的話成本就會非常高，因為DB層通常是1:1或1:N的儲存資料，如果寫了一堆UpdatePasswordRequest、UpdateUserNameRequest，當欄位一多起來就會產生大量重複的程式碼，還是簡單的實作SaveUser更為方便。

### One-Way Mapping

這個方法是把資料模型也變成介面的方式來傳遞，但我覺得這個寫法用在Go裡面也太噁心了，應該沒有人會這樣寫，留待未來填坑。

```go=
package entity

type User interface {
    ID() uint
    Email() string
    Password() string
    Name() string
    SetID(uint)
    SetEmail(string)
    SetPassword(string)
    SetName(string)
}

type user struct {}
var _ User = &user{}
```

```go=
package orm

type gormUser struct {}
var _ entity.User = &gormUser{}
```

```go=
package adapter

type jsonUser struct {}
var _ entity.User = &jsonUser{}
```

## 結論

實務上還是會混用不同的mapping strategy，隨著複雜度和需求來進行調整。如果統一的要求使用某種方式實作，會花很多時間在寫重複的程式碼。因此是取決於開發效率和架構整潔度之間的平衡。