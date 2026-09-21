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
| `DSLSet` | `set` | 可变 | 否 |
| `DSLFrozenSet` | `frozenset` | 不可变 | 是 |

---

### DSLInteger — 整数类型

```gdscript
class DSLInteger extends DSLObject:
    # 整数值
    var value: int
```

拥有 **类型提升机制**

当 `DSLInteger` 与 `DSLFloat` 进行运算时，整型会自动提升为浮点型，详见 `PyGDS.DSLInteger._promote` 方法

### DSLFloat — 浮点数类型

```gdscript
class DSLFloat extends DSLObject:
    # 浮点数值
    var value: float
```

拥有 **类型提升机制**

当 `DSLInteger` 与 `DSLFloat` 进行运算时，整型会自动提升为浮点型，详见 `PyGDS.DSLFloat._promote` 方法

### DSLBool — 布尔类型

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

### DSLNone — 空值类型

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

### DSLString — 字符串类型

```gdscript
class DSLString extends DSLObject:
    # GDScript 原生 String
    var value: String
```

### DSLList — 列表类型

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

### DSLTuple — 元组类型

```gdscript
class DSLTuple extends DSLObject:
    # 元素数组 (不可变)
    var items: Array[DSLObject]
```

### DSLDict — 字典类型

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

### DSLSet — 集合类型

对应 Python `set`，元素为可哈希对象（`int`/`float`/`str`/`bool`/`None`/`tuple`），按值去重

```gdscript
class DSLSet extends DSLObject:
    # 规范化键 -> DSLObject 映射 (键如 "i:5" / "s:abc")
    var items: Dictionary
```

#### 字面量与构造

```python
{1, 2, 3}          # 集合字面量 (元素无冒号)
set()              # 空集合
set([1, 1, 2])     # 从可迭代对象构造 → {1, 2}
set("abca")        # 逐字符 → {'a', 'b', 'c'}
```

> **注意**：`{}` 是空字典；空集合用 `set()`

#### 集合运算

| 运算符 | 方法 | 说明 |
| :--- | :--- | :--- |
| `a \| b` | `a.union(b)` | 并集 |
| `a & b` | `a.intersection(b)` | 交集 |
| `a - b` | `a.difference(b)` | 差集 |
| `a ^ b` | `a.symmetric_difference(b)` | 对称差集 |
| `a == b` | — | 内容相等（与顺序无关） |
| `a < b` / `a <= b` | `a.issubset(b)` | 真子集 / 子集 |
| `a > b` / `a >= b` | `a.issuperset(b)` | 真超集 / 超集 |
| `a.isdisjoint(b)` | — | 是否不相交 |

```python
s = {1, 2, 3}
len(s)              # 3
2 in s              # True
sorted(s)           # [1, 2, 3] (集合无序, 排序后输出)
{1, 2} | {2, 3}     # {1, 2, 3}
isinstance(s, set)  # True
```

#### 可哈希规则

- 可哈希：`int`/`float`/`str`/`bool`/`None`/`tuple`（含嵌套）、`frozenset`
- 不可哈希：`list`/`dict`/`set` → 加入时抛 `TypeError: unhashable type`

#### 集合推导式

```python
{x * x for x in [1, 2, 3, 2]}              # {1, 4, 9} (自动去重)
{x for x in range(6) if x % 2 == 0}        # {0, 2, 4}
{s.upper() for s in ["a", "b", "a"]}       # {'A', 'B'}
```

### DSLFrozenSet — 不可变集合类型

对应 Python `frozenset`：与 `set` 相同的内容与运算语义，但**不可变**（无 `add`/`remove`/`discard`/`pop`/`clear`），因此**可哈希**，可嵌套进 `set` / `dict` 键 / 作为另一个 `frozenset` 元素

```gdscript
class DSLFrozenSet extends DSLSet:
    # 不可变: 继承 set 的存储, 但移除可变操作方法
```

#### 构造

```python
frozenset([1, 2, 2, 3])    # frozenset({1, 2, 3}) (自动去重)
frozenset()                # 空 frozenset
frozenset({1, 2, 3})       # 从 set 构造
frozenset("aabbc")         # frozenset({'a', 'b', 'c'})
```

#### 运算（均返回新 frozenset）

```python
a = frozenset([1, 2, 3])
b = frozenset([2, 3, 4])
a | b                # frozenset({1, 2, 3, 4})  并集
a & b                # frozenset({2, 3})        交集
a - b                # frozenset({1})           差集
a ^ b                # frozenset({1, 4})        对称差集
```

> **注意**：`frozenset` 可与 `set` 直接比较（`frozenset([1, 2]) == {1, 2}` 为 `True`），运算时也可与 `set` 混合；但运算结果始终为 `frozenset`

#### 可哈希性

```python
s = {frozenset([1, 2]), frozenset([2, 1]), frozenset([1, 2, 3])}
len(s)               # 2 (前两个内容相同去重)
isinstance(frozenset([1]), frozenset)   # True
isinstance({1}, frozenset)              # False
```

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

#### `str.format(*args, **kwargs)` → `str`

```python
# Python: str.format(*args, **kwargs)
"{} {}".format("a", 1)          # "a 1"
"{0} {1}".format("a", 1)        # "a 1"
"{name}".format(name="Alice")   # "Alice"
```

**格式说明符**：支持位置/关键字参数，以及对齐、填充、符号、零填充、宽度、千分位、精度与类型（与 f-string 相同的说明符语法）

```python
"{:.2f}".format(3.14159)        # 3.14
"{0:04d}".format(42)            # 0042
"{:x}".format(255)              # ff
"{:>8}".format("hi")            # "      hi"
"{:*^6}".format("ab")           # **ab**
"{:,}".format(12345)            # 12,345
"{0!r:>10}".format("hi")        # "      'hi'"
```

**转换标志**：`!r`（repr）、`!s`（str）、`!a`（ascii）；转义花括号 `{{` / `}}`

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

### set 方法

#### `set.add(x)` → `None`

```python
# Python: set.add(x)
s = {1, 2}; s.add(3)          # {1, 2, 3}
```

#### `set.remove(x)` → `None`

```python
# Python: set.remove(x)
s = {1, 2, 3}; s.remove(2)    # {1, 3}; 不存在抛 KeyError
```

#### `set.discard(x)` → `None`

```python
# Python: set.discard(x)
s = {1, 2, 3}; s.discard(9)   # 不存在不报错
```

#### `set.pop()` → `object`

```python
# Python: set.pop()
s = {1, 2, 3}; s.pop()        # 弹出任意元素, 空集合抛 KeyError
```

#### `set.clear()` → `None`

```python
# Python: set.clear()
s = {1, 2}; s.clear()         # set()
```

#### `set.copy()` → `set`

```python
# Python: set.copy()
s = {1, 2}; s.copy()          # {1, 2} (浅拷贝)
```

#### `set.union(other)` → `set`

```python
# Python: set.union(other)
{1, 2}.union({2, 3})          # {1, 2, 3} (同 a | b)
```

#### `set.intersection(other)` → `set`

```python
# Python: set.intersection(other)
{1, 2}.intersection({2, 3})   # {2} (同 a & b)
```

#### `set.difference(other)` → `set`

```python
# Python: set.difference(other)
{1, 2, 3}.difference({2})     # {1, 3} (同 a - b)
```

#### `set.symmetric_difference(other)` → `set`

```python
# Python: set.symmetric_difference(other)
{1, 2}.symmetric_difference({2, 3})   # {1, 3} (同 a ^ b)
```

#### `set.isdisjoint(other)` → `bool`

```python
# Python: set.isdisjoint(other)
{1, 2}.isdisjoint({3, 4})     # True
```

#### `set.issubset(other)` → `bool`

```python
# Python: set.issubset(other)
{1, 2}.issubset({1, 2, 3})    # True (同 a <= b)
```

#### `set.issuperset(other)` → `bool`

```python
# Python: set.issuperset(other)
{1, 2, 3}.issuperset({1})     # True (同 a >= b)
```

### frozenset 方法

`frozenset` 只读, 运算方法均返回新的 `frozenset`, 用法与 `set` 对应方法一致 (见上):

| 方法 | 说明 |
| :--- | :--- |
| `copy()` | 浅拷贝 |
| `union(other)` | 并集 (同 `a \| b`) |
| `intersection(other)` | 交集 (同 `a & b`) |
| `difference(other)` | 差集 (同 `a - b`) |
| `symmetric_difference(other)` | 对称差集 (同 `a ^ b`) |
| `isdisjoint(other)` | 是否不相交 |
| `issubset(other)` | 子集 (同 `a <= b`) |
| `issuperset(other)` | 超集 (同 `a >= b`) |

---
