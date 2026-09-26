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
| `DSLGenerator` | `generator` | 可变 | 否 |
| `DSLFunctionGenerator` | `generator` | 可变 | 否 |
| `DSLSlice` | `slice` | 不可变 | 是 |
| `DSLItemGetter` | `operator.itemgetter` | 不可变 | 否 |
| `DSLAttrGetter` | `operator.attrgetter` | 不可变 | 否 |
| `DSLCmpKey` | `functools.KeyWrapper` | 不可变 | 否 |

`match` / `case` 结构化模式匹配的类型参与规则（与 CPython 3.12 的类型标志语义一致）：

- **序列模式**仅接受内建 `list` 与 `tuple`；`str` / `bytes` / `bytearray` 与用户类实例（即使实现了 `__getitem__` / `__len__`）不参与序列匹配
- **映射模式**仅接受内建 `dict`；用户类实例不参与映射匹配
- **类模式**对任意类型可用（走 `isinstance`）；无 `__match_args__` 时，数值与容器类内建类型（`int` / `float` / `str` / `list` / `dict` / `tuple` / `set` / `frozenset` / `bytes` / `bytearray` / `bool`，含其子类）接受恰好一个位置子模式并直接绑定主题本身，其余类型位置子模式上限为 0

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

### DSLBytes — 字节串类型

对应 Python `bytes`，由 `b"..."` / `rb"..."` 字面量或 `bytes()` 构造函数创建（不可变）

```gdscript
class DSLBytes extends DSLObject:
    # 字节数组 (每个元素 0-255)
    var data: Array[int] = []
```

索引与迭代产出整数（`b"xy"[0] == 120`），`len` 为字节数，支持切片、`b"a" * 3` 重复与 `in` 判定；`repr` 形如 `b'xy'`，不可打印字节转义为 `\xNN` 形式；与 `str` 严格区分（`b"a" == "a"` 为 `False`）

### DSLRange — 惰性整数序列类型

对应 Python `range`，只保存 `start` / `stop` / `step`，按需求值（大范围不展开内存）

```gdscript
class DSLRange extends DSLObject:
    # 起始值 (含)
    var start: int = 0
    # 终止值 (不含)
    var stop: int = 0
    # 步长 (非 0)
    var step: int = 1
```

支持 `len` / 索引（含负索引）/ 切片（返回新 range）/ 成员判定 / 迭代 / `reversed()`；不可变，元素赋值与删除均报 `TypeError`

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

### DSLGenerator — 生成器类型

对应 Python 生成器（`generator`），由生成器表达式 `(expr for var in iterable [if cond])` 创建，**惰性求值**：仅在 `next()` 或迭代时逐一产出元素，适合大序列与无限序列

```gdscript
class DSLGenerator extends DSLObject:
    # 持有元素表达式、循环子句数组 (Array[CompClause]) 与闭包环境
    # 共享的 DSLGeneratorIterator 实现一次性迭代语义
```

```python
g = (x * x for x in range(5))
type(g)                 # <class 'generator'>
next(g)                 # 0 (逐次推进)
list(g)                 # [1, 4, 9, 16] (一次性: 已消费 0, 剩余继续)
list(g)                 # [] (已耗尽)
sum(x * x for x in range(4))     # 14 (裸写法)

list(x * y for x in [1, 2] for y in [10, 20])   # [10, 20, 20, 40] (多 for 子句)
```

> **注意**：生成器为**一次性迭代器**，多次迭代不会从头开始；`next()` 超出时抛 `StopIteration`
> （可传默认值 `next(g, default)`）。`list`/`tuple`/`sum`/`sorted`/`any`/`all`/`enumerate`/`zip`/
> `min`/`max` 等消费函数均通过 `_dsl_iter()` 接受生成器，`itertools.islice` 可惰性消费无限生成器

### DSLFunctionGenerator — 生成器函数类型

对应 Python 生成器函数（`generator`），由 `def` 内含 `yield` 的函数调用创建

调用时**不执行函数体**、立即返回惰性生成器对象；持有函数声明/闭包、参数绑定后的局部环境，以及挂起时保存的解释器执行栈（栈切换机制见 `architecture.md` 的「生成器函数与栈切换」节）

```gdscript
class DSLFunctionGenerator extends DSLObject:
    # 持有 function / local_env / body 与挂起时保存的 exec_stack / call_stack / cur_class / cur_self
    # _step() 通过栈切换驱动函数体推进一个 yield, 共享的 DSLFunctionGeneratorIterator 实现一次性迭代
```

```python
def gen():
    yield 1
    yield 2
type(gen())             # <class 'generator'>
list(gen())             # [1, 2]
next(gen())             # 1 (逐次推进)

# 表达式级 yield: x = yield v 恢复时注入 send 值
def gexpr():
    x = yield 10
    yield x
g = gexpr()
next(g)                 # 10
g.send("hi")            # 'hi' (x 为 send 值)

# yield from 委托子可迭代对象
def gsub():
    yield from [1, 2, 3]
list(gsub())            # [1, 2, 3]

# send / throw / close
g.send(value)           # 注入值恢复 (send(None) 可启动)
g.throw(ValueError("e"))  # 在挂起位置抛出异常
g.close()               # 注入 GeneratorExit, finally 执行

# return value → StopIteration.value
def gret():
    yield 1
    return 42
it = gret()
next(it)
try:
    next(it)
except StopIteration as e:
    e.value            # 42
```

> **注意**：生成器函数同样是**一次性迭代器**；耗尽后再 `next()` 抛 `StopIteration`（携带 `return` 值），`next(g, default)` 返回默认值，`for` / `list()` 耗尽时正常结束
> 生成器体内可调用 `time.sleep()`（协作式挂起，与 CPython 行为一致），嵌套生成器内同理，详见 `time` 模块说明
> lambda 体内直接含 `yield`（Python 3.12+）也会生成 lambda 生成器

#### 循环子句 (CompClause)

生成器表达式与各类推导式共用 `CompClause` 描述循环：每个子句包含目标变量名数组、迭代对象表达式与 `if` 条件数组，多个子句按书写顺序嵌套（内层可引用外层循环变量）

```gdscript
class CompClause:
    var targets: Array      # 循环目标变量名 (元组目标 for k, v in ... 为多个)
    var iterable: Expr      # 迭代对象表达式
    var conditions: Array   # 过滤条件表达式数组 (可零个或多个)
```

- **急切求值**（`ListComp` / `SetComp` / `DictComp`）：`_eval_comp_clauses` 递归展开子句，在每个完整绑定组合上求值元素表达式
- **惰性求值**（`DSLGenerator`）：`DSLGeneratorIterator` 用帧栈保存每层子句的迭代器与绑定快照，每次 `next()` 只推进到下一个满足条件的元素

### DSLSlice — 切片类型

对应 Python `slice`，描述切片区间 `start:stop:step`，可保存复用，用于 `lst[slice(...)]` / `"str"[slice(...)]`

```python
s = slice(1, 4)             # slice(1, 4, None)
s.start / s.stop / s.step   # 1 / 4 / None (未指定为 None)
isinstance(s, slice)        # True
lst[slice(1, 4)]            # 等价于 lst[1:4]
lst[slice(0, 6, 2)]         # 等价于 lst[0:6:2]
lst[slice(4, 0, -1)]        # 负步长反向
```

## 迭代器体系

PyGDS 为不同集合类型提供了专门的迭代器实现

### DSLSeqIterator

`iter()` 对 list / tuple / str / range / dict / set 等返回的一等迭代器对象（对应 CPython 的 `list_iterator` / `tuple_iterator` / `str_iterator` / `range_iterator` / `dict_keyiterator` / `set_iterator` 等）：持有原容器引用（活动视图），内部驱动器在 `iter()` 调用时创建并复用（保证耗尽后再迭代为空）；`iter(it)` 返回自身。这些类型类仅注册进内置类型表（供 `type()` 返回），不是内建名

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

迭代字典的键，并将内部存储的 `Variant` 键自动包装回 `DSLObject`；创建时记录键数快照，迭代期间对字典增删键时报 `RuntimeError: dictionary changed size during iteration`（既有键的值替换不触发）

```gdscript
class DSLDictKeyIterator extends DSLIterator:
    var dict: Dictionary
    var keys: Array
    var index: int = 0
```

### DSLStringIterator

逐字符迭代字符串

### DSLGeneratorIterator

生成器表达式迭代器：每次 `next()` 惰性推进一次推导式循环（求值迭代源 → 绑定循环变量 → 判定条件 → 产出元素），采用**预取缓冲**保证 `has_next()` 准确；状态保存在迭代器字段中

### DSLInfiniteIterator

无限迭代器，`itertools` 的 `repeat`/`cycle`/`count` 返回无限对象，其 `_dsl_iter()` 产出无限迭代器（`DSLRepeatIterator`/`DSLCycleIterator`/`DSLCountIterator`），`has_next()` 恒为 `true`，需配合 `islice`/`takewhile` 等惰性消费

## 内置类型方法

### int 方法

#### `int.bit_length() -> int`

返回整数的二进制表示位数（不含符号与前导零）

```python
# Python: int.bit_length()
(255).bit_length()                  # 8
(5).bit_length()                    # 3
```

#### `int.bit_count() -> int`

返回整数的二进制表示中 1 的个数

```python
# Python: int.bit_count()
(7).bit_count()                     # 3
```

#### `int.to_bytes(length, byteorder, signed=False) -> bytes`

按指定长度与字节序（`"big"` / `"little"`）转为字节串；值放不下报 `OverflowError: int too big to convert`，负数转无符号报 `OverflowError: can't convert negative int to unsigned`

```python
# Python: int.to_bytes(length, byteorder)
(16706).to_bytes(2, "big")          # b'AB'
```

#### `int.hex() -> str`

返回整数的十六进制字符串（带 `0x` 前缀，负数带 `-`）

```python
(255).hex()                         # "0xff"
```

#### `int.from_bytes(bytes, byteorder, signed=False) -> int`

类方法：按指定字节序把字节串转为整数

```python
# Python: int.from_bytes(bytes, byteorder)
int.from_bytes(b'AB', "big")         # 16706
int.from_bytes(b'AB', "little")      # 16961
```

### float 方法

#### `float.is_integer() -> bool`

浮点值是否为整数

```python
# Python: float.is_integer()
(2.0).is_integer()                  # True
(1.5).is_integer()                  # False
```

#### `float.as_integer_ratio() -> tuple`

返回精确的分数表示 `(分子, 分母)`；Infinity / NaN 报 `OverflowError`

```python
# Python: float.as_integer_ratio()
(2.0).as_integer_ratio()            # (2, 1)
(0.5).as_integer_ratio()            # (1, 2)
```

#### `float.hex() -> str`

返回 IEEE 754 双精度的十六进制浮点字符串（隐含首位 1 + 13 位十六进制小数 + 2 的幂指数）；`±inf` 为 `inf` / `-inf`，`nan` 为 `nan`

```python
# Python: float.hex()
(1.5).hex()                         # 0x1.8000000000000p+0
(3.0).hex()                         # 0x1.8000000000000p+1
(0.1).hex()                         # 0x1.999999999999ap-4
(0.0).hex()                         # 0x0.0p+0
(-2.5).hex()                        # -0x1.4000000000000p+1
```

### str 方法

Python 对应签名在括号内给出，用于对照行为是否一致

#### `str.upper() -> str`

```python
# Python: str.upper()
"hello".upper()           # "HELLO"
```

#### `str.lower() -> str`

```python
# Python: str.lower()
"HELLO".lower()           # "hello"
```

#### `str.strip(chars=None) -> str`

```python
# Python: str.strip(chars=None)
"  hello  ".strip()       # "hello"
"xxhelloxx".strip("x")    # "hello"
```

#### `str.split(sep=None, maxsplit=-1) -> list[str]`

```python
# Python: str.split(sep=None, maxsplit=-1)
"a b c".split()           # ["a", "b", "c"]
"a,b,c".split(",")        # ["a", "b", "c"]
"a,b,c".split(",", 1)     # ["a", "b,c"]
```

#### `str.join(iterable) -> str`

```python
# Python: str.join(iterable)
",".join(["a", "b", "c"]) # "a,b,c"
```

#### `str.replace(old, new) -> str`

```python
# Python: str.replace(old, new, count=-1)
"hello".replace("l", "x") # "hexxo"
```

> **注意**：当前不支持 `count` 参数

#### `str.find(sub) -> int`

```python
# Python: str.find(sub)
"hello".find("l")         # 2
"hello".find("z")         # -1
```

> **注意**：当前不支持 `start`/`end` 范围参数

#### `str.startswith(prefix) -> bool`

```python
# Python: str.startswith(prefix)
"hello".startswith("he")  # True
"hello".startswith("xx")  # False
```

#### `str.endswith(suffix) -> bool`

```python
# Python: str.endswith(suffix)
"hello".endswith("lo")    # True
```

#### `str.lstrip(chars=None) -> str`

```python
# Python: str.lstrip(chars=None)
"  hello".lstrip()        # "hello"
"xxhello".lstrip("x")     # "hello"
```

#### `str.rstrip(chars=None) -> str`

```python
# Python: str.rstrip(chars=None)
"hello  ".rstrip()        # "hello"
```

#### `str.capitalize() -> str`

```python
# Python: str.capitalize()
"hello world".capitalize() # "Hello world"
```

#### `str.casefold() -> str`

```python
# Python: str.casefold()
"HELLO".casefold()        # "hello"
```

> **注意**：当前等价于 `lower()`，未实现完整 Unicode case folding

#### `str.title() -> str`

```python
# Python: str.title()
"hello world".title()     # "Hello World"
```

#### `str.swapcase() -> str`

```python
# Python: str.swapcase()
"Hello".swapcase()        # "hELLO"
```

#### `str.count(sub, start=0, end=...) -> int`

```python
# Python: str.count(sub, start=0, end=len(str))
"hello hello".count("he") # 2
"hello".count("l", 0, 3)  # 1
```

#### `str.isdigit() -> bool`

```python
# Python: str.isdigit()
"123".isdigit()           # True
"abc".isdigit()           # False
```

#### `str.isalpha() -> bool`

```python
# Python: str.isalpha()
"abc".isalpha()           # True
"abc123".isalpha()        # False
```

#### `str.isalnum() -> bool`

```python
# Python: str.isalnum()
"abc123".isalnum()        # True
```

#### `str.isspace() -> bool`

```python
# Python: str.isspace()
"   ".isspace()           # True
```

#### `str.islower() -> bool`

```python
# Python: str.islower()
"hello".islower()         # True
```

#### `str.isupper() -> bool`

```python
# Python: str.isupper()
"HELLO".isupper()         # True
```

#### `str.istitle() -> bool`

```python
# Python: str.istitle()
"Hello World".istitle()   # True
```

#### `str.center(width, fillchar=' ') -> str`

```python
# Python: str.center(width, fillchar=' ')
"hi".center(6)            # "  hi  "
"hi".center(6, "-")       # "--hi--"
```

#### `str.ljust(width, fillchar=' ') -> str`

```python
# Python: str.ljust(width, fillchar=' ')
"hi".ljust(6)             # "hi    "
```

#### `str.rjust(width, fillchar=' ') -> str`

```python
# Python: str.rjust(width, fillchar=' ')
"hi".rjust(6)             # "    hi"
```

#### `str.zfill(width) -> str`

```python
# Python: str.zfill(width)
"42".zfill(5)             # "00042"
```

#### `str.rsplit(sep=None, maxsplit=-1) -> list[str]`

```python
# Python: str.rsplit(sep=None, maxsplit=-1)
"a b c".rsplit()          # ["a", "b", "c"]
"a,b,c".rsplit(",", 1)    # ["a,b", "c"]
```

#### `str.format(*args, **kwargs) -> str`

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

#### `str.encode(encoding="utf-8") -> bytes`

按编码把字符串转为字节串（支持 UTF-8）

```python
# Python: str.encode(encoding)
"hi".encode()                       # b'hi'
```

#### `str.format_map(mapping) -> str`

与 `str.format` 相同，但通过映射对象提供命名占位符的值

```python
# Python: str.format_map(mapping)
"{x}".format_map({"x": 42})         # "42"
```

---

### bytes 方法

操作对象为字节串，涉及「子序列」的参数均接受 bytes；下标与区间语义与 str 对应方法一致

#### `bytes.decode(encoding="utf-8") -> str`

按编码把字节串转为字符串

```python
# Python: bytes.decode(encoding)
b'hi'.decode()                      # "hi"
```

#### `bytes.hex(sep="") -> str`

返回小写十六进制字符串；可选 `sep` 作为字节间分隔符

```python
# Python: bytes.hex(sep)
b'AB'.hex()                         # "4142"
b'AB'.hex(" ")                      # "41 42"
```

#### `bytes.upper()` / `bytes.lower()` / `bytes.title() -> bytes`

ASCII 大写 / 小写 / 词首大写

```python
b'abc'.upper()                      # b'ABC'
b'ABC'.lower()                      # b'abc'
b'ab c'.title()                     # b'Ab C'
```

#### `bytes.strip(chars=None)` / `bytes.lstrip(chars=None)` / `bytes.rstrip(chars=None) -> bytes`

去除首尾（或单侧）字节，缺省去除 ASCII 空白（空格、制表、换行等），`chars` 可指定字节集合

```python
b'  hi  '.strip()                   # b'hi'
b'xxhixx'.strip(b'x')               # b'hi'
```

#### `bytes.split(sep=None, maxsplit=-1) -> list[bytes]`

按 `sep`（bytes）分割，缺省按连续 ASCII 空白分割

```python
b'a,b,c'.split(b',')                # [b'a', b'b', b'c']
b'a b  c'.split()                   # [b'a', b'b', b'c']
```

#### `bytes.replace(old, new, count=-1) -> bytes`

替换子序列，`count` 限制替换次数

```python
b'aaa'.replace(b'a', b'b')          # b'bbb'
```

#### `bytes.find(sub, start=0, end=...) -> int` / `bytes.index(...) -> int`

查找子序列首个下标；`find` 找不到返回 -1，`index` 报 `ValueError`；`bytes.count(sub)` 统计出现次数

```python
b'hello'.find(b'll')                # 2
b'hello'.count(b'l')                # 2
```

#### `bytes.startswith(prefix)` / `bytes.endswith(suffix) -> bool`

```python
b'abc'.startswith(b'ab')            # True
```

#### `bytes.join(iterable) -> bytes`

以自身为分隔符连接 bytes 可迭代对象

```python
b'-'.join([b'a', b'b'])             # b'a-b'
```

#### `bytes.center(width, fillchar=b' ')` / `bytes.ljust(...)` / `bytes.rjust(...) -> bytes`

宽度对齐（居中 / 左对齐 / 右对齐），`fillchar` 为填充字节

```python
b'hi'.center(4)                     # b' hi '
b'hi'.ljust(4)                      # b'hi  '
b'hi'.rjust(4)                      # b'  hi'
```

### list 方法

#### `list.append(x) -> None`

```python
# Python: list.append(x)
lst = [1, 2]; lst.append(3)  # [1, 2, 3]
```

#### `list.extend(iterable) -> None`

```python
# Python: list.extend(iterable)
lst = [1, 2]; lst.extend([3, 4])  # [1, 2, 3, 4]
```

#### `list.pop(index=-1) -> object`

```python
# Python: list.pop(index=-1)
lst = [1, 2, 3]; lst.pop()     # 3, lst → [1, 2]
lst.pop(0)                      # 1, lst → [2]
```

#### `list.remove(x) -> None`

```python
# Python: list.remove(x)
lst = [1, 2, 3]; lst.remove(2)  # [1, 3]
```

#### `list.insert(index, x) -> None`

```python
# Python: list.insert(index, x)
lst = [1, 2]; lst.insert(0, 0)  # [0, 1, 2]
```

#### `list.index(x) -> int`

```python
# Python: list.index(x, start=0, end=len(list))
[1, 2, 3].index(2)              # 1
```

> **注意**：当前不支持 `start`/`end` 范围参数

#### `list.count(x) -> int`

```python
# Python: list.count(x)
[1, 2, 2, 3].count(2)           # 2
```

#### `list.sort(*, key=None, reverse=False) -> None`

```python
# Python: list.sort(*, key=None, reverse=False)
lst = [3, 1, 2]; lst.sort()         # [1, 2, 3]
lst.sort(reverse=True)              # [3, 2, 1]
lst.sort(key=lambda x: -x)          # 支持 key 函数
```

#### `list.reverse() -> None`

```python
# Python: list.reverse()
lst = [1, 2, 3]; lst.reverse()      # [3, 2, 1]
```

#### `list.clear() -> None`

```python
# Python: list.clear()
lst = [1, 2, 3]; lst.clear()        # []
```

#### `list.copy() -> list`

```python
# Python: list.copy()
lst = [1, 2, 3]; lst.copy()         # [1, 2, 3] (浅拷贝)
```

---

### dict 方法

#### `dict.get(key, default=None) -> object`

```python
# Python: dict.get(key, default=None)
d = {"a": 1}; d.get("a")            # 1
d.get("b", 0)                       # 0
```

#### `dict.pop(key, default=...) -> object`

```python
# Python: dict.pop(key, default=...)
d = {"a": 1}; d.pop("a")            # 1, d → {}
d.pop("b", 0)                       # 0
```

#### `dict.update(other, **kwargs) -> None`

```python
# Python: dict.update(other, **kwargs)
d = {"a": 1}; d.update({"b": 2})    # {"a": 1, "b": 2}
d.update([("c", 3)])                # {"a": 1, "b": 2, "c": 3}
```

#### `dict.clear() -> None`

```python
# Python: dict.clear()
d = {"a": 1}; d.clear()             # {}
```

#### `dict.copy() -> dict`

```python
# Python: dict.copy()
d = {"a": 1}; d.copy()              # {"a": 1} (浅拷贝)
```

#### `dict.setdefault(key, default=None) -> object`

```python
# Python: dict.setdefault(key, default=None)
d = {"a": 1}; d.setdefault("b", 0)  # 0, d → {"a": 1, "b": 0}
```

#### `dict.popitem() -> tuple`

```python
# Python: dict.popitem()
d = {"a": 1, "b": 2}; d.popitem()   # ("b", 2), d → {"a": 1}
```

#### `dict.keys() -> view`

```python
# Python: dict.keys()
d = {"a": 1, "b": 2}; d.keys()      # dict_keys(["a", "b"])
```

#### `dict.values() -> view`

```python
# Python: dict.values()
d = {"a": 1, "b": 2}; d.values()    # dict_values([1, 2])
```

#### `dict.items() -> view`

返回 `dict_items` 视图对象，支持 `len()`、成员判定（`(k, v) in d.items()`）、迭代与 `repr`（`dict_items([...])`）；视图相等按集合语义（与顺序无关）

```python
# Python: dict.items()
d = {"a": 1, "b": 2}; d.items()     # dict_items([('a', 1), ('b', 2)])
('a', 1) in d.items()               # True
len(d.items())                      # 2
```

---

### tuple 方法

#### `tuple.count(x) -> int`

```python
# Python: tuple.count(x)
(1, 2, 2, 3).count(2)              # 2
```

#### `tuple.index(x) -> int`

```python
# Python: tuple.index(x, start=0, end=len(tuple))
(1, 2, 3).index(2)                 # 1
```

> **注意**：当前不支持 `start`/`end` 范围参数

### set 方法

#### `set.add(x) -> None`

```python
# Python: set.add(x)
s = {1, 2}; s.add(3)          # {1, 2, 3}
```

#### `set.remove(x) -> None`

```python
# Python: set.remove(x)
s = {1, 2, 3}; s.remove(2)    # {1, 3}; 不存在抛 KeyError
```

#### `set.discard(x) -> None`

```python
# Python: set.discard(x)
s = {1, 2, 3}; s.discard(9)   # 不存在不报错
```

#### `set.pop() -> object`

```python
# Python: set.pop()
s = {1, 2, 3}; s.pop()        # 弹出任意元素, 空集合抛 KeyError
```

#### `set.clear() -> None`

```python
# Python: set.clear()
s = {1, 2}; s.clear()         # set()
```

#### `set.copy() -> set`

```python
# Python: set.copy()
s = {1, 2}; s.copy()          # {1, 2} (浅拷贝)
```

#### `set.union(other) -> set`

`other` 可为任意可迭代对象（集合运算方法族同此约定）

```python
# Python: set.union(other)
{1, 2}.union({2, 3})          # {1, 2, 3} (同 a | b)
{1, 2}.union([9])             # {1, 2, 9}
```

#### `set.intersection(other) -> set`

```python
# Python: set.intersection(other)
{1, 2}.intersection({2, 3})   # {2} (同 a & b)
{1, 2}.intersection([1, 3])   # {1}
```

#### `set.difference(other) -> set`

```python
# Python: set.difference(other)
{1, 2, 3}.difference({2})     # {1, 3} (同 a - b)
```

#### `set.symmetric_difference(other) -> set`

```python
# Python: set.symmetric_difference(other)
{1, 2}.symmetric_difference({2, 3})   # {1, 3} (同 a ^ b)
```

#### `set.isdisjoint(other) -> bool`

```python
# Python: set.isdisjoint(other)
{1, 2}.isdisjoint({3, 4})     # True
```

#### `set.issubset(other) -> bool`

```python
# Python: set.issubset(other)
{1, 2}.issubset({1, 2, 3})    # True (同 a <= b)
```

#### `set.issuperset(other) -> bool`

```python
# Python: set.issuperset(other)
{1, 2, 3}.issuperset({1})     # True (同 a >= b)
```

#### `set.update(other) -> None`

并集并入自身；`other` 可为任意可迭代对象（原地更新族同此约定）

```python
# Python: set.update(other)
st = {1, 2}; st.update([3])   # {1, 2, 3}
```

#### `set.intersection_update(other) -> None`

保留同时出现在 `other` 中的元素

```python
st = {1, 2}; st.intersection_update({2, 3})   # {2}
```

#### `set.difference_update(other) -> None`

移除 `other` 中出现的元素

```python
st = {1, 2}; st.difference_update([2])        # {1}
```

#### `set.symmetric_difference_update(other) -> None`

仅保留「只在其中一侧出现」的元素

```python
st = {1, 2}; st.symmetric_difference_update([1, 4])   # {2, 4}
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
