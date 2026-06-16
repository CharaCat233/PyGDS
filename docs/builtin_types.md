# 内置类型

PyGDS 实现了与 Python 高度一致的内置类型系统

所有 DSL 类型均继承自 `DSLObject` 基类，通过 `magic_*` 系列方法模拟 Python 的魔术方法协议

---

## 类型总览

| DSL 类型 | Python 对应 | 可变性 | 哈希性 |
| :--- | :--- | :--- | :--- |
| `DSLInteger` | `int` | 不可变 | 是 |
| `DSLFloat` | `float` | 不可变 | 是 |
| `DSLBool` | `bool` | 不可变 | 是 |
| `DSLNone` | `NoneType` | 不可变 | 是 |
| `DSLString` | `str` | 不可变 | 是 |
| `DSLList` | `list` | 可变 | 否 |
| `DSLTuple` | `tuple` | 不可变 | 是 |
| `DSLDict` | `dict` | 可变 | 否 |

---

## DSLInteger — 整数类型

```gdscript
class DSLInteger extends DSLObject:
    # 整数值
    var value: int
```

拥有 **类型提升机制**

当 `DSLInteger` 与 `DSLFloat` 进行运算时，整型会自动提升为浮点型，详见 `PyGDS.DSLInteger._promote` 方法

## DSLFloat — 浮点数类型

```gdscript
class DSLFloat extends DSLObject:
    # 浮点数值
    var value: float
```

拥有 **类型提升机制**

当 `DSLInteger` 与 `DSLFloat` 进行运算时，整型会自动提升为浮点型，详见 `PyGDS.DSLFloat._promote` 方法

## DSLBool — 布尔类型

```gdscript
class DSLBool extends DSLObject:
    # 底层布尔值
    var value: bool
```

拥有 **单例缓存机制**

为了提高性能并确保一致性，`True` 和 `False` 的值在 `Interpreter` 中被缓存为单例

```gdscript
# Interpreter 静态变量
static var _cached_true: DSLBool   # DSLBool.new(true) 的单例
static var _cached_false: DSLBool  # DSLBool.new(false) 的单例
```

当解释器遇到字面量 `True` 或 `False` 时，不会创建新的 `DSLBool` 实例，而是返回缓存的单例

## DSLNone — 空值类型

```gdscript
class DSLNone extends DSLObject:
    pass
```

拥有 **单例缓存机制**

为了提高性能并确保一致性，`None` 的值在 `Interpreter` 中被缓存为单例

```gdscript
# Interpreter 静态变量
static var _cached_none: DSLNone   # DSLNone.new() 的单例
```

当解释器遇到字面量 `None` 时，不会创建新的 `DSLNone` 实例，而是返回缓存的单例

## DSLString — 字符串类型

```gdscript
class DSLString extends DSLObject:
    # GDScript 原生 String
    var value: String
```

## DSLList — 列表类型

```gdscript
class DSLList extends DSLObject:
    # 元素数组
    var items: Array[DSLObject]
```

拥有 **内部解包机制**

当 `DSLList` 通过 `DSLObject` 包装时（用户自定义类继承自 `list`），方法需要通过 `DSLObject._unwrap_dsl` 来获取底层的原始 `DSLList` 对象

```gdscript
static func _unwrap_dsl(obj: DSLObject) -> DSLObject:
    if obj._wrapped != null:
        return obj._wrapped
    return obj
```

## DSLTuple — 元组类型

```gdscript
class DSLTuple extends DSLObject:
    # 元素数组 (不可变)
    var items: Array[DSLObject]
```

## DSLDict — 字典类型

```gdscript
class DSLDict extends DSLObject:
    # 键为 GDScript Variant (String/int/float/bool)
    var dict: Dictionary[Variant, DSLObject]
```

拥有特殊的 **键类型限制机制**

`DSLDict` 的键被存储为 GDScript 原生 `Variant` 类型（而非 `DSLObject`），以提高查找效率

| DSL 类型 | 对应 Variant 类型 |
| :--- | :--- |
| `DSLString` | `String` |
| `DSLInteger` | `int` |
| `DSLFloat` | `float` |
| `DSLBool` | `bool` |

`PyGDS.DSLDict._key_to_variant` 方法负责此转换，若键类型不在上述列表中，会返回 `null` 并设置 `TypeError: unhashable type`

## 迭代器体系

PyGDS 为不同集合类型提供了专门的迭代器实现

### DSLListIterator

供 `DSLList` 和 `DSLTuple` 使用

```gdscript
class DSLListIterator extends DSLIterator:
    var items: Array
    var index: int = 0

    func has_next() -> bool:
        return index < items.size()

    func next() -> DSLObject:
        var res = items[index]
        index += 1
        return res
```

### DSLDictKeyIterator

迭代字典的键，并将内部存储的 `Variant` 键自动包装回 `DSLObject`

```gdscript
class DSLDictKeyIterator extends DSLIterator:
    var dict: Dictionary
    var keys: Array
    var index: int = 0
```

### DSLStringIterator

逐字符迭代字符串

## 内置类型方法

### str 方法

Python 对应签名在括号内给出，用于对照行为是否一致

#### `str.upper()` → `str`

```python
# Python: str.upper()
"hello".upper()           # "HELLO"
```

#### `str.lower()` → `str`

```python
# Python: str.lower()
"HELLO".lower()           # "hello"
```

#### `str.strip(chars=None)` → `str`

```python
# Python: str.strip(chars=None)
"  hello  ".strip()       # "hello"
"xxhelloxx".strip("x")    # "hello"
```

#### `str.split(sep=None, maxsplit=-1)` → `list[str]`

```python
# Python: str.split(sep=None, maxsplit=-1)
"a b c".split()           # ["a", "b", "c"]
"a,b,c".split(",")        # ["a", "b", "c"]
"a,b,c".split(",", 1)     # ["a", "b,c"]
```

#### `str.join(iterable)` → `str`

```python
# Python: str.join(iterable)
",".join(["a", "b", "c"]) # "a,b,c"
```

#### `str.replace(old, new)` → `str`

```python
# Python: str.replace(old, new, count=-1)
"hello".replace("l", "x") # "hexxo"
```

> **注意**：当前不支持 `count` 参数

#### `str.find(sub)` → `int`

```python
# Python: str.find(sub)
"hello".find("l")         # 2
"hello".find("z")         # -1
```

> **注意**：当前不支持 `start`/`end` 范围参数

#### `str.startswith(prefix)` → `bool`

```python
# Python: str.startswith(prefix)
"hello".startswith("he")  # True
"hello".startswith("xx")  # False
```

#### `str.endswith(suffix)` → `bool`

```python
# Python: str.endswith(suffix)
"hello".endswith("lo")    # True
```

#### `str.lstrip(chars=None)` → `str`

```python
# Python: str.lstrip(chars=None)
"  hello".lstrip()        # "hello"
"xxhello".lstrip("x")     # "hello"
```

#### `str.rstrip(chars=None)` → `str`

```python
# Python: str.rstrip(chars=None)
"hello  ".rstrip()        # "hello"
```

#### `str.capitalize()` → `str`

```python
# Python: str.capitalize()
"hello world".capitalize() # "Hello world"
```

#### `str.casefold()` → `str`

```python
# Python: str.casefold()
"HELLO".casefold()        # "hello"
```

> **注意**：当前等价于 `lower()`，未实现完整 Unicode case folding

#### `str.title()` → `str`

```python
# Python: str.title()
"hello world".title()     # "Hello World"
```

#### `str.swapcase()` → `str`

```python
# Python: str.swapcase()
"Hello".swapcase()        # "hELLO"
```

#### `str.count(sub, start=0, end=...)` → `int`

```python
# Python: str.count(sub, start=0, end=len(str))
"hello hello".count("he") # 2
"hello".count("l", 0, 3)  # 1
```

#### `str.isdigit()` → `bool`

```python
# Python: str.isdigit()
"123".isdigit()           # True
"abc".isdigit()           # False
```

#### `str.isalpha()` → `bool`

```python
# Python: str.isalpha()
"abc".isalpha()           # True
"abc123".isalpha()        # False
```

#### `str.isalnum()` → `bool`

```python
# Python: str.isalnum()
"abc123".isalnum()        # True
```

#### `str.isspace()` → `bool`

```python
# Python: str.isspace()
"   ".isspace()           # True
```

#### `str.islower()` → `bool`

```python
# Python: str.islower()
"hello".islower()         # True
```

#### `str.isupper()` → `bool`

```python
# Python: str.isupper()
"HELLO".isupper()         # True
```

#### `str.istitle()` → `bool`

```python
# Python: str.istitle()
"Hello World".istitle()   # True
```

#### `str.center(width, fillchar=' ')` → `str`

```python
# Python: str.center(width, fillchar=' ')
"hi".center(6)            # "  hi  "
"hi".center(6, "-")       # "--hi--"
```

#### `str.ljust(width, fillchar=' ')` → `str`

```python
# Python: str.ljust(width, fillchar=' ')
"hi".ljust(6)             # "hi    "
```

#### `str.rjust(width, fillchar=' ')` → `str`

```python
# Python: str.rjust(width, fillchar=' ')
"hi".rjust(6)             # "    hi"
```

#### `str.zfill(width)` → `str`

```python
# Python: str.zfill(width)
"42".zfill(5)             # "00042"
```

#### `str.rsplit(sep=None, maxsplit=-1)` → `list[str]`

```python
# Python: str.rsplit(sep=None, maxsplit=-1)
"a b c".rsplit()          # ["a", "b", "c"]
"a,b,c".rsplit(",", 1)    # ["a,b", "c"]
```

#### `str.format(*args)` → `str`

```python
# Python: str.format(*args)
"{} {}".format("a", 1)    # "a 1"
"{0} {1}".format("a", 1)  # "a 1"
```

> **注意**：仅支持按位置填充 `{}` 和 `{0}`, 不支持关键字参数和格式化说明符

---

### list 方法

#### `list.append(x)` → `None`

```python
# Python: list.append(x)
lst = [1, 2]; lst.append(3)  # [1, 2, 3]
```

#### `list.extend(iterable)` → `None`

```python
# Python: list.extend(iterable)
lst = [1, 2]; lst.extend([3, 4])  # [1, 2, 3, 4]
```

#### `list.pop(index=-1)` → `object`

```python
# Python: list.pop(index=-1)
lst = [1, 2, 3]; lst.pop()     # 3, lst → [1, 2]
lst.pop(0)                      # 1, lst → [2]
```

#### `list.remove(x)` → `None`

```python
# Python: list.remove(x)
lst = [1, 2, 3]; lst.remove(2)  # [1, 3]
```

#### `list.insert(index, x)` → `None`

```python
# Python: list.insert(index, x)
lst = [1, 2]; lst.insert(0, 0)  # [0, 1, 2]
```

#### `list.index(x)` → `int`

```python
# Python: list.index(x, start=0, end=len(list))
[1, 2, 3].index(2)              # 1
```

> **注意**：当前不支持 `start`/`end` 范围参数

#### `list.count(x)` → `int`

```python
# Python: list.count(x)
[1, 2, 2, 3].count(2)           # 2
```

#### `list.sort(*, key=None, reverse=False)` → `None`

```python
# Python: list.sort(*, key=None, reverse=False)
lst = [3, 1, 2]; lst.sort()         # [1, 2, 3]
lst.sort(reverse=True)              # [3, 2, 1]
lst.sort(key=lambda x: -x)          # 支持 key 函数
```

#### `list.reverse()` → `None`

```python
# Python: list.reverse()
lst = [1, 2, 3]; lst.reverse()      # [3, 2, 1]
```

#### `list.clear()` → `None`

```python
# Python: list.clear()
lst = [1, 2, 3]; lst.clear()        # []
```

#### `list.copy()` → `list`

```python
# Python: list.copy()
lst = [1, 2, 3]; lst.copy()         # [1, 2, 3] (浅拷贝)
```

---

### dict 方法

#### `dict.get(key, default=None)` → `object`

```python
# Python: dict.get(key, default=None)
d = {"a": 1}; d.get("a")            # 1
d.get("b", 0)                       # 0
```

#### `dict.pop(key, default=...)` → `object`

```python
# Python: dict.pop(key, default=...)
d = {"a": 1}; d.pop("a")            # 1, d → {}
d.pop("b", 0)                       # 0
```

#### `dict.update(other, **kwargs)` → `None`

```python
# Python: dict.update(other, **kwargs)
d = {"a": 1}; d.update({"b": 2})    # {"a": 1, "b": 2}
d.update([("c", 3)])                # {"a": 1, "b": 2, "c": 3}
```

#### `dict.clear()` → `None`

```python
# Python: dict.clear()
d = {"a": 1}; d.clear()             # {}
```

#### `dict.copy()` → `dict`

```python
# Python: dict.copy()
d = {"a": 1}; d.copy()              # {"a": 1} (浅拷贝)
```

#### `dict.setdefault(key, default=None)` → `object`

```python
# Python: dict.setdefault(key, default=None)
d = {"a": 1}; d.setdefault("b", 0)  # 0, d → {"a": 1, "b": 0}
```

#### `dict.popitem()` → `tuple`

```python
# Python: dict.popitem()
d = {"a": 1, "b": 2}; d.popitem()   # ("b", 2), d → {"a": 1}
```

#### `dict.keys()` → `view`

```python
# Python: dict.keys()
d = {"a": 1, "b": 2}; d.keys()      # dict_keys(["a", "b"])
```

#### `dict.values()` → `view`

```python
# Python: dict.values()
d = {"a": 1, "b": 2}; d.values()    # dict_values([1, 2])
```

#### `dict.items()` → `list[tuple]`

```python
# Python: dict.items()
d = {"a": 1, "b": 2}; d.items()     # [("a", 1), ("b", 2)]
```

---

### tuple 方法

#### `tuple.count(x)` → `int`

```python
# Python: tuple.count(x)
(1, 2, 2, 3).count(2)              # 2
```

#### `tuple.index(x)` → `int`

```python
# Python: tuple.index(x, start=0, end=len(tuple))
(1, 2, 3).index(2)                 # 1
```

> **注意**：当前不支持 `start`/`end` 范围参数
