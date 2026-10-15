# 内置类型与内置函数

PyGDS 在全局作用域中注册了多个内置类型和内置函数，对标 Python 3.x 标准库

## 内置类型（作为构造函数）

以下内置类型通过 DSLClass 注册，调用时触发 `__new__` → `__init__` 双阶段构造流程

### `str(obj="")`

对应 Python `str` 类型构造函数，将对象转为字符串表示

- 无参时返回空字符串 `""`
- 返回类型：`str` (DSLString)

```python
str()                    # ""
str(42)                  # "42"
str(3.14)                # "3.14"
str(True)                # "True"
```

### `int(obj=0)`

对应 Python `int` 类型构造函数，将对象转为整数

- 无参时返回 `0`
- 支持输入：`int`、`float`（截断）、`str`（解析）、`bool`
- 返回类型：`int` (DSLInteger)

```python
int()                    # 0
int(3.14)                # 3
int("42")                # 42
int(True)                # 1
```

### `float(obj=0.0)`

对应 Python `float` 类型构造函数，将对象转为浮点数

- 无参时返回 `0.0`
- 支持输入：`float`、`int`（提升）、`str`（解析）
- 返回类型：`float` (DSLFloat)

```python
float()                  # 0.0
float(42)                # 42.0
float("3.14")            # 3.14
```

### `bool(obj=False)`

对应 Python `bool` 类型构造函数，将对象转为布尔值

- 无参时返回 `False`
- 返回类型：`bool` (DSLBool)

```python
bool()                   # False
bool(0)                  # False
bool(1)                  # True
bool("")                 # False
bool("hello")            # True
bool([1, 2])             # True
```

### `list(iterable=[])`

对应 Python `list` 类型构造函数，构造列表

- 无参时返回 `[]`
- 参数必须是可迭代对象
- 返回类型：`list` (DSLList)

```python
list()                   # []
list("abc")              # ["a", "b", "c"]
list(range(3))           # [0, 1, 2]
```

### `dict(iterable=None, **kwargs)`

对应 Python `dict` 类型构造函数，支持以下调用方式

1. **迭代器方式**：传入一个可迭代对象，其中每个元素为 `(key, value)` 二元组
2. **关键字参数方式**：传入关键字参数，键为字符串，值为对应 DSL 对象

- 无参时返回 `{}`
- 返回类型：`dict` (DSLDict)

```python
dict()                   # {}
dict([("a", 1), ("b", 2)])    # {"a": 1, "b": 2}
dict(x=10, y=20)         # {"x": 10, "y": 20}
```

### `tuple(iterable=[])`

对应 Python `tuple` 类型构造函数

- 无参时返回 `()`
- 返回类型：`tuple` (DSLTuple)

### `bytes(obj=0)`

对应 Python `bytes` 类型构造函数，`b"..."` 字面量之外的字节串构造方式

- `bytes(3)`：3 个零字节
- `bytes([104, 105])`：可迭代对象，元素为 0-255 的整数（越界报 `ValueError`）
- `bytes("hi", "utf-8")`：字符串按编码转字节串
- `bytes(b"hi")`：拷贝
- 返回类型：`bytes` (DSLBytes)

---

## 内置函数

### `print(*args, sep=" ", end="\n")`

对应 Python `print()`，将参数输出到控制台

- `sep`：对象之间的分隔符，默认为空格 `" "`
- `end`：输出末尾的结束符，默认为换行 `"\n"`

```python
print("Hello", "World")              # Hello World
print("Hello", "World", sep=", ")    # Hello, World
print("Hello", end="!")              # Hello!
```

### `len(obj)`

对应 Python `len()`，返回序列或集合的长度

- 支持类型：`str`、`list`、`dict`、`tuple`
- 返回类型：`int`（DSLInteger）

```python
len("hello")             # 5
len([1, 2, 3])           # 3
len({"a": 1, "b": 2})    # 2
```

### `range(stop)` / `range(start, stop)` / `range(start, stop, step)`

模仿 Python `range()`，返回惰性的整数序列对象

- 返回类型：`range` (DSLRange)，只保存 `start` / `stop` / `step`，按需求值（大范围不展开内存）
- 支持 `len` / 索引（含负索引）/ 切片（返回新 range）/ 成员判定 / 迭代 / `reversed()`
- 不可变：元素赋值与删除均报 `TypeError`
- `step` 为 0 报 `ValueError`，参数非整数报 `TypeError`

```python
range(5)                 # range(0, 5)
list(range(5))           # [0, 1, 2, 3, 4]
range(0, 10, 2)          # range(0, 10, 2)
range(10)[2:5]           # range(2, 5)
len(range(1000000))      # 1000000 (不展开)
```

### `type(obj)`

对应 Python `type()`，返回对象的类型对象。`type` 名字绑定到类型类自身（`print(type)` 输出 `<class 'type'>`，`isinstance(int, type)` 为 `True`）

- 对于内置值对象，返回对应的类型类（从内置类型表查找）
- 对用户类（类对象本身），返回 `type` 类型类
- 三参数形式 `type(name, bases, dict)` 动态创建类（dict 中的函数成为方法，其余值为类属性）

```python
type(42)                 # <class 'int'>
type("hello")            # <class 'str'>
class C:
    pass
type(C)                  # <class 'type'>
type(C()).__name__       # "C"
isinstance(int, type)    # True
type(C) is type          # True
```

### `id(obj)`

对应 Python `id()`，返回对象的唯一整数标识 ID

- 每个 DSLObject 实例在创建时分配唯一的 `_object_id`
- 接收恰好 1 个参数，否则抛出 `TypeError`
- 返回类型：`int`（DSLInteger）

```python
id(x)                    # 某个唯一的整数
```

### `repr(obj)`

对应 Python `repr()`，返回对象的"官方"字符串表示

- 接收恰好 1 个参数
- 返回类型：`str`（DSLString）

```python
repr(42)                 # "42"
repr([1, 2, 3])          # "[1, 2, 3]"
```

### `ascii(obj)`

对应 Python `ascii()`，返回对象的 `repr` 字符串，非 ASCII 字符转义为 `\x` / `\u` / `\U` 形式

```python
ascii("abc")        # "'abc'"
ascii("é")          # "'\xe9'"
ascii("中")         # "'\u4e2d'"
ascii([1, "é"])     # "[1, '\xe9']"
```

### `hash(obj)`

对应 Python `hash()`，返回对象的哈希值

- 接收恰好 1 个参数
- 支持用户自定义 `__hash__` 方法
- 返回类型：`int`（DSLInteger）

### `round(number, ndigits=0)`

对应 Python `round()`，基于二进制精确值做银行家舍入（半到偶），中程值的舍入方向与 CPython 一致

```python
round(3.14)              # 3
round(3.14, 1)           # 3.1
round(2.675, 2)          # 2.67 (二进制精确值低于十进制中程)
round(2.5)               # 2
round(0.5)               # 0
round(1234, -2)          # 1200
```

### `abs(x)`

对应 Python `abs()`，返回数的绝对值

```python
abs(-42)                 # 42
abs(-3.14)               # 3.14
```

### `min(iterable, key=None, default=...)` / `min(a, b, ...)`

对应 Python `min()`，返回最小值；`key` 为取比较键的函数，`default` 为可迭代对象为空时的返回值

```python
min([3, 1, 4, 1, 5])     # 1
min(3, 1, 4)             # 1
min(["bb", "a"], key=len)  # "a"
min([], default="empty")   # empty
```

### `max(iterable, key=None, default=...)` / `max(a, b, ...)`

对应 Python `max()`，返回最大值；`key` 为取比较键的函数，`default` 为可迭代对象为空时的返回值

```python
max([3, 1, 4, 1, 5])     # 5
max(3, 1, 4)             # 4
max(["bb", "a"], key=len)  # "bb"
max([], default=0)         # 0
```

### `sum(iterable, start=0)`

对应 Python `sum()`，对可迭代对象求和

```python
sum([1, 2, 3])           # 6
sum([1, 2, 3], 10)       # 16
```

### `pow(base, exp, mod=None)`

对应 Python `pow()`，计算幂运算，支持三参数取模形式

```python
pow(2, 3)                # 8
pow(2, 3, 5)             # 3
```

### `divmod(a, b)`

对应 Python `divmod()`，返回商和余数元组

```python
divmod(10, 3)            # (3, 1)
```

### `sorted(iterable, key=None, reverse=False)`

对应 Python `sorted()`，返回排序后的新列表；`key` 为取排序键的函数，`reverse` 为降序开关

```python
sorted([3, 1, 2])        # [1, 2, 3]
sorted([3, 1, 2], reverse=True)  # [3, 2, 1]
sorted(["bb", "a"], key=len)     # ["a", "bb"]
```

### `reversed(seq)`

对应 Python `reversed()`，返回反向迭代器

```python
list(reversed([1, 2, 3]))  # [3, 2, 1]
```

### `enumerate(iterable, start=0)`

对应 Python `enumerate()`，返回 `(index, value)` 枚举序列

- 返回惰性 `enumerate` 迭代器对象（CPython 同形）：一次性消费，`iter(e) is e`，耗尽后为空
- 元素惰性拉取，支持生成器与无限序列配合；源消费中途可挂起

```python
list(enumerate(["a", "b"]))  # [(0, "a"), (1, "b")]
print(type(enumerate([])).__name__)  # enumerate
```

### `iter(iterable)` / `iter(callable, sentinel)`

对应 Python `iter()`，返回对象的迭代器。对 `list` / `tuple` / `str` / `range` / `dict` / `set` 返回真正的一等迭代器对象（类型名为 `list_iterator` / `tuple_iterator` / `str_ascii_iterator`（纯 ASCII 字符串）/ `str_iterator` / `range_iterator` / `dict_keyiterator` / `dict_valueiterator` / `dict_itemiterator` / `set_iterator`），持有原容器引用（活动视图，迭代期间容器追加的元素可见）、耗尽后再迭代为空、`iter(it)` 返回自身；`iter(生成器)` 返回生成器自身（耗尽后不可重复消费）；`iter(d)` 迭代期间对字典增删键报 `RuntimeError: dictionary changed size during iteration`（既有键的值替换不触发）。这些类型名不是内建名（与 CPython 一致，经 `type(x).__name__` 查看）

两参形式 `iter(callable, sentinel)` 每步以无参方式调用 `callable`，结果与 `sentinel` 相等时结束（类型名为 `callable_iterator`）；callable 为用户函数时其内不得发起程序挂起（如 `time.sleep`）

```python
it = iter([1, 2, 3])
lst = [1, 2]
it2 = iter(lst)
lst.append(3)
print(list(it2))                # [1, 2, 3] (活动视图)

def g():
    yield 1
it3 = iter(g())
print(list(it3), list(it3))     # [1] [] (生成器耗尽后不可重复消费)
```

### `next(iterator[, default])`

对应 Python `next()`，取迭代器的下一项。迭代器耗尽时：提供 `default` 返回默认值，否则报 `StopIteration`；实参不是迭代器（缺 `__next__`）报 `TypeError: '<t>' object is not an iterator`

```python
it = iter([1, 2])
next(it)            # 1
next(it, 99)        # 2
next(it, 99)        # 99 (已耗尽, 返回默认值)
```

### `zip(*iterables, strict=False)`

对应 Python `zip()`，并行迭代多个可迭代对象；`strict=True` 时若某个可迭代对象先耗尽而其余仍有剩余，报 `ValueError`

- 返回惰性 `zip` 迭代器对象（CPython 同形）：一次性消费，`iter(z) is z`，耗尽后为空
- 成员惰性拉取，支持生成器与无限序列配合（如 `islice(zip(count(), "ab"), 2)`）；成员消费中途可挂起
- `strict` 校验在首个成员耗尽处按 CPython 文案报错（多参时含 `argument 3 is shorter than arguments 1-2` 的复数形态）

```python
list(zip([1, 2], ["a", "b"]))  # [(1, "a"), (2, "b")]
try:
    list(zip([1, 2], [3], strict=True))
except ValueError as e:
    print(e)                     # zip() argument 2 is shorter than argument 1
print(type(zip()).__name__)      # zip
```

### `any(iterable)`

对应 Python `any()`，有任一元素为真时返回 `True`

```python
any([False, True, False])  # True
any([False, False])        # False
```

### `all(iterable)`

对应 Python `all()`，所有元素为真时返回 `True`

```python
all([True, True])        # True
all([True, False])       # False
```

### `ord(c)`

对应 Python `ord()`，返回单个字符的 Unicode 码点

```python
ord("A")                 # 65
```

### `chr(i)`

对应 Python `chr()`，返回 Unicode 码点对应的字符

```python
chr(65)                  # "A"
```

### `hex(x)`

对应 Python `hex()`，将整数转为十六进制字符串

```python
hex(255)                 # "0xff"
```

### `oct(x)`

对应 Python `oct()`，将整数转为八进制字符串

```python
oct(8)                   # "0o10"
```

### `bin(x)`

对应 Python `bin()`，将整数转为二进制字符串

```python
bin(3)                   # "0b11"
```

### `format(value, spec="")`

对应 Python `format()`，按格式说明符把值转为字符串，与 f-string 及 `str.format` 的格式说明符语法一致

```python
format(255, "x")         # "ff"
format(1234567, ",")     # "1,234,567" (千位分隔)
format(3.14, ".1f")      # "3.1"
format(42)               # "42" (无说明符等价于 str)
```

### `isinstance(obj, classinfo)`

对应 Python `isinstance()`，检查对象是否为指定类型或其子类的实例

```python
isinstance(42, int)      # True
isinstance(True, int)    # True
```

### `issubclass(cls, classinfo)`

对应 Python `issubclass()`，检查类是否为指定类的子类

```python
issubclass(bool, int)    # True
```

### `callable(obj)`

对应 Python `callable()`，检查对象是否可调用

```python
callable(print)          # True
callable(42)             # False
```

### `input(prompt="")`

对应 Python `input()`，显示提示并读取用户输入

```python
name = input("Enter name: ")
```

> [!WARNING]
> 该方法始终抛出 `EOFError` 异常

### `getattr(obj, name, default=None)`

对应 Python `getattr()`，获取对象的属性

- 属性存在时返回属性值
- 属性不存在且提供了 `default` 时返回 `default`
- 属性不存在且未提供 `default` 时抛出 `AttributeError`
- 返回类型：任意 DSLObject

```python
class Point:
    def __init__(self):
        self.x = 42

p = Point()
getattr(p, "x")                 # 42
getattr(p, "missing", "N/A")    # "N/A"
getattr(p, "missing")           # AttributeError
getattr([], "append")           # 获取绑定方法 (可调用)
```

### `hasattr(obj, name)`

对应 Python `hasattr()`，判断对象是否有给定属性（属性不存在返回 `False`；`__getattr__` 内抛出的非 `AttributeError` 异常会原样传播）

```python
class Point:
    pass

p = Point()
p.x = 1
print(hasattr(p, "x"))          # True
print(hasattr(p, "y"))          # False
print(hasattr(int, "nope"))     # False
```

### `setattr(obj, name, value)`

对应 Python `setattr()`，设置对象的属性

```python
class Point:
    pass

p = Point()
setattr(p, "x", 10)
print(p.x)                      # 10
```

### `delattr(obj, name)`

对应 Python `delattr()`，删除对象的属性，属性不存在时抛出 `AttributeError`

```python
p = Point()
setattr(p, "y", 5)
delattr(p, "y")
getattr(p, "y", "gone")         # "gone"
```

### `dir(obj)`

对应 Python `dir()`，按字母序列出对象可访问的属性与方法名

- 用户类实例：实例属性 + 类方法 + 类属性（含继承链）
- 类对象：类方法与类属性；模块：模块成员
- 内置类型实例（如 `[]`、`5`、`{}`）：按类型收集方法名（含已实现的魔术方法）
- 无参调用：返回当前作用域的用户定义名（排序）

```python
class C:
    def greet(self):
        return "hi"

dir(C)                   # ["greet", ...] (排序后的名字列表)
"append" in dir([])      # True
```

### `map(func, iterable, ...)`

对应 Python `map()`，对可迭代对象的每个元素应用函数

- 支持多个可迭代对象（逐元素并行传入函数）
- 返回惰性 `map` 迭代器对象（CPython 同形）：一次性消费，`iter(m) is m`，耗尽后为空，实参在 `map()` 调用处即要求可迭代
- 成员惰性拉取，支持生成器与无限序列配合（如 `islice(map(f, count()), 3)`），消费中途可挂起

```python
list(map(lambda x: x * 2, [1, 2, 3]))          # [2, 4, 6]
list(map(str, [1, 2, 3]))                      # ["1", "2", "3"]
list(map(lambda a, b: a + b, [1, 2], [10, 20])) # [11, 22]
m = map(str, [1])
print(type(m).__name__)                        # map
print(list(m), list(m))                        # ['1'] [] (一次性)
```

### `filter(func, iterable)`

对应 Python `filter()`，保留满足条件的元素

- `func` 为 `None` 时按元素真值过滤
- 返回惰性 `filter` 迭代器对象（CPython 同形）：一次性消费，`iter(f) is f`，耗尽后为空
- 谓词惰性调用，支持生成器与无限序列配合，谓词体内可挂起

```python
list(filter(lambda x: x > 1, [0, 1, 2, 3]))   # [2, 3]
list(filter(None, [0, 1, "", "a", []]))        # [1, "a"]
f = filter(None, [1])
print(type(f).__name__)                        # filter
```

---

### 动态求值与作用域字典

以下函数（`eval` / `exec` / `compile` / `globals` / `locals` / `vars`）与 CPython 对齐，差异点随文注明

#### `eval(source[, globals])`

把字符串按单表达式求值并返回结果；多语句或赋值语句报 `SyntaxError`（`invalid syntax (<string>, line 1)`）；第二实参为 `dict` 时以其建独立环境（差异：CPython 为活 dict 视图，PyGDS 为快照写回），内建名在该环境可见

#### `exec(source[, globals])`

把字符串按语句集执行，返回 `None`；`globals` 实参为 `dict` 时以其建独立环境并写回顶层绑定（含被 `del` 删除的键）。动态代码顶层不支持程序挂起（遇 `time.sleep` 等报 `RuntimeError: dynamic code top-level cannot be suspended`）；`exec` 内定义的函数 / 生成器被主脚本调用时可正常挂起

#### `compile(source, filename, mode)`

返回 code 对象（`mode` 限 `"exec"` / `"eval"` / `"single"`，非法值报 `ValueError`）；code 对象带 `co_name` / `co_filename` / `co_firstlineno` 元数据，可透传给 `eval` / `exec` 执行；`co_code` 字节码不实现（PyGDS 持 AST）

#### `globals()` / `locals()` / `vars(obj)`

- `globals()`：返回全局环境的活视图（dict 形态，读写即时生效，可 `del` 删除名字）
- `locals()`：函数内返回局部绑定快照；模块层等价 `globals()`
- `vars(obj)`：返回实例字典；无 `__dict__` 的对象（如 `5`）报 `TypeError: vars() argument must have __dict__ attribute`

```python
eval("1 + 2")                                # 3
exec("y = 7")                                # y 绑定到当前作用域
g = {}
exec("q = 9", g)
print(g["q"])                                # 9 (写回 globals 实参)

eval(compile("3+4", "<s>", "eval"))          # 7
c = compile("1", "<x>", "eval")
print(c.co_name, c.co_filename)              # <module> <x>

globals()["gv"] = 42
print(gv)                                    # 42 (活视图读写)
```

## 内置模块 (import)

PyGDS 支持 `import` / `from-import` 语法导入内置模块，当前提供 `math`、`random`、`statistics`、`functools`、`itertools`、`collections`、`string`、`operator`、`time`、`sys`、`contextlib`、`bisect`、`heapq`、`base64`、`json`、`logging` 内置模块（其余引擎相关能力建议通过 `register_api()` 由 GDScript 侧提供）

### import 语法

```python
import math                       # 导入整个模块
import math as m                  # 别名
from math import sqrt             # 导入单个成员
from math import sqrt as s, pi    # 别名与多个成员
from math import *                # 导入所有公开成员 (非下划线开头)
```

### `math` 模块

| 类别 | 成员 |
| :--- | :--- |
| 常量 | `pi` `e` `tau` `inf` `nan` |
| 基础 | `sqrt` `isqrt` `cbrt` `floor` `ceil` `trunc` `fabs` `fmod` `pow` `remainder` |
| 指数/对数 | `exp` `log` `log1p` `expm1` `log2` `log10` |
| 几何 | `dist` |
| 三角函数 | `sin` `cos` `tan` `asin` `acos` `atan` `atan2` `hypot` |
| 角度 | `degrees` `radians` |
| 整数 | `factorial` `gcd` `comb` `perm` `prod` `lcm` |
| 符号 | `copysign` |
| 判定 | `isnan` `isinf` `isfinite` |

```python
import math
math.sqrt(16)        # 4.0
math.floor(3.7)      # 3
math.gcd(12, 18)     # 6
math.factorial(5)    # 120
math.comb(5, 2)      # 10   (组合数)
math.perm(5, 2)      # 20   (排列数)
math.prod([2, 3, 4]) # 24   (连乘, start 为关键字参数)
math.lcm(4, 6)       # 12   (最小公倍数)
math.cbrt(-8)        # -2.0 (立方根, 支持负数)
math.remainder(7, 3) # 1.0  (IEEE 754 余数, 商取最近偶数)
math.remainder(1.5, 1)  # -0.5
math.log1p(0.5)      # 0.4054651081081644 (ln(1+x), 小 x 高精度)
math.expm1(0.5)      # 0.6487212707001282 (e**x - 1, 小 x 高精度)
math.dist([1, 2], [4, 6])   # 5.0 (欧氏距离, 两序列须等长)
```

> `math.remainder(x, y)` 返回 `x - n*y`，其中 `n` 为 `x/y` 四舍五入到最近偶数，除数为零或 `x` 为无穷时抛 `ValueError`
> `math.gcd()` / `math.lcm()` 零参返回 `0` / `1`；`math.hypot(x)` 单参返回 `abs(x)`；`math.dist` 两序列长度不等报 `ValueError`

### `random` 模块

| 函数 | 说明 |
| :--- | :--- |
| `seed(n)` | 设置随机种子（可复现序列） |
| `random()` | 返回 `[0, 1)` 的浮点数 |
| `uniform(a, b)` | 返回 `[a, b]` 的浮点数 |
| `randint(a, b)` | 返回 `[a, b]` 的整数（含端点） |
| `randrange(start, stop, step)` | 返回范围内的随机整数 |
| `choice(seq)` | 从序列中随机选一个元素 |
| `choices(population, weights=None, k=1)` | 有放回抽样，可按 `weights` 加权，返回长度为 k 的列表 |
| `shuffle(seq)` | 原地打乱列表 |
| `sample(population, k)` | 返回 k 个不重复的随机元素 |
| `gauss(mu=0.0, sigma=1.0)` | 正态分布采样（Box-Muller 变换） |
| `triangular(low=0.0, high=1.0, mode=None)` | 三角分布采样 |
| `randbytes(n)` | 返回 n 字节随机 `bytes` |
| `getrandbits(k)` | 返回 k 个随机二进制位的整数 |
| `getstate()` / `setstate(state)` | 保存与恢复生成器内部状态 |

```python
import random
random.seed(42)
random.random()        # [0, 1) 内
random.choices(["a", "b"], weights=[1, 0], k=3)   # ['a', 'a', 'a'] (权重为 0 不会被抽中)
random.gauss(0, 1)     # 服从 N(0, 1) 的浮点数
random.randint(1, 6)   # 1..6 内
```

> **注意**：PyGDS 的 `random` 实现与 CPython 同源的 MT19937（Mersenne Twister）：整数种子走 CPython 同款 `init_by_array` 播种路径，数值序列与 CPython 对齐（`random_mt` 用例守护）；字符串种子经 PyGDS 自有哈希展开，序列与 CPython 不同（文档化差异）。`seed()` 可保证在 PyGDS 内部复现相同序列
> **说明**：抽样函数的参数类型规则与 CPython 一致——`choice` / `shuffle` 取 `len(seq)` 后按整数下标索引/赋值，因此生成器报 `TypeError: object of type`generator`has no len()`、集合报 `not subscriptable`、`shuffle` 对元组/字符串/`range` 报 `does not support item assignment`，`choice` 支持字符串与 `range`，字典按键取（键非 `0..n-1` 时 `KeyError`）；`sample` 接受列表/元组/字符串/`range`；`choices` 的 `weights` 只需可迭代，可传生成器
> **`Random` 类**：`random.Random(seed)` 创建持有独立 MT 状态的实例（`r.random()` / `r.randint()` 等方法与模块级同名同语义），便于隔离随机序列；两个同种子实例产生相同序列

### `statistics` 模块

| 函数 | 说明 |
| :--- | :--- |
| `mean(data)` | 算术平均值 |
| `median(data)` | 中位数（偶数个取中间两数平均） |
| `mode(data)` | 众数（出现次数最多的元素，适用于任意可哈希类型） |
| `stdev(data)` | 样本标准差（除以 n-1） |
| `pstdev(data)` | 总体标准差（除以 n） |
| `variance(data)` | 样本方差（除以 n-1） |
| `pvariance(data)` | 总体方差（除以 n） |
| `fmean(data)` | 浮点算术平均值（结果恒为 float） |
| `geometric_mean(data)` | 几何平均值（数据须为正） |
| `harmonic_mean(data)` | 调和平均值（数据须为非负） |
| `quantiles(data, n=4)` | 分位切点（exclusive 方法，返回 n-1 个值，数据点少于 2 个时抛 `StatisticsError`） |

```python
import statistics
statistics.mean([1, 2, 3, 4])        # 2.5
statistics.median([1, 2, 3, 4])      # 2.5
statistics.mode([1, 2, 2, 3])        # 2
round(statistics.stdev([1, 2, 3]), 6)  # 1.0
statistics.quantiles([1, 2, 3, 4])   # [1.25, 2.5, 3.75] (四分位)
statistics.quantiles([1, 2, 3, 4], n=2)  # [2.5] (中位数切点)
```

> `statistics.StatisticsError` 继承自 `ValueError`（与 CPython 一致），既可用 `except statistics.StatisticsError` 捕获，也可用 `except ValueError` 捕获

### `functools` 模块

| 函数 | 说明 |
| :--- | :--- |
| `reduce(func, iterable[, initial])` | 从左到右累积归约 |
| `partial(func, *args, **kwargs)` | 偏函数（预绑定部分参数） |
| `wraps(wrapped)` | 装饰器：把被包装函数的 `__name__` / `__doc__` 等元数据复制到包装函数 |
| `lru_cache(maxsize=128, typed=False)` | LRU 缓存装饰器；`@lru_cache` 无括号形态按默认 `maxsize=128`；包装函数带 `cache_info()` / `cache_clear()` |
| `singledispatch(func)` | 单分派泛型函数；`@f.register(类型)` 注册实现，未命中走默认实现 |
| `cmp_to_key(func)` | 把旧式 `cmp(a, b)` 函数转成可用于 `key=` 的 key 工厂 |

```python
from functools import reduce, partial, cmp_to_key
reduce(lambda a, b: a + b, [1, 2, 3, 4])   # 10
add5 = partial(lambda a, b: a + b, 5)
add5(3)                                    # 8
sorted([3, 1, 2], key=cmp_to_key(lambda a, b: b - a))   # [3, 2, 1]
```

> `cmp_to_key(func)` 返回一个 key 工厂，调用它包装元素后，`sorted(key=...)` / `list.sort(key=...)`
> 按 `func(a, b)` 返回值的符号决定顺序（负数在前，零相等，正数在后）
> `partial` 对象可内省：`.func`（原函数）/ `.args`（位置实参元组）/ `.keywords`（关键字实参 dict）
> `lru_cache` 的 `maxsize=None` 为无界缓存；`typed=True` 时不同类型实参分别缓存

### `itertools` 模块（常用子集）

| 函数 | 说明 |
| :--- | :--- |
| `chain(*iterables)` | 拼接多个可迭代对象 |
| `product(*iterables)` | 笛卡尔积，返回元组流 |
| `combinations(iterable, r)` | 长度为 r 的组合 |
| `permutations(iterable[, r])` | 长度为 r 的排列 |
| `islice(iterable, start, stop[, step])` | 惰性切片（等价于 `iterable[start:stop:step]`） |
| `repeat(obj[, times])` | 重复对象；指定 times 返回列表，否则返回无限对象 |
| `cycle(iterable)` | 无限循环序列（返回无限对象） |
| `count(start=0, step=1)` | 无限递增计数（返回无限对象） |
| `zip_longest(*iterables, fillvalue=None)` | 以最长可迭代对象为准并行配对，不足处用 fillvalue 填充 |
| `takewhile(predicate, iterable)` | 取满足谓词的开头元素，遇首个不满足即止 |
| `dropwhile(predicate, iterable)` | 丢弃满足谓词的开头元素，其余原样返回 |
| `accumulate(iterable[, func][, initial])` | 前缀累积（默认加法，可传 `func` 与 `initial`） |
| `pairwise(iterable)` | 相邻元素配对，返回长度为 n-1 的元组列表 |
| `groupby(iterable, key=None)` | 相邻分组，产出 `(key, grouper)` 对；grouper 为与外层共享游标的惰性一次性迭代器，外层推进后旧 grouper 立即耗尽 |
| `starmap(func, iterable)` | 用每组参数解包调用 `func`，返回结果列表 |
| `filterfalse(predicate, iterable)` | 保留谓词为假的元素（`predicate` 为 `None` 时保留假值元素），返回惰性迭代器 |
| `batched(iterable, n)` | 按长度 n 批量切分为元组流（惰性）；`n < 1` 报 `ValueError` |
| `tee(iterable, n=2)` | 从一个可迭代对象派生 n 个独立游标（返回 n 元组） |
| `chain.from_iterable(iterable)` | 拼接一个可迭代对象中的各子可迭代对象 |

```python
from itertools import chain, product, combinations, permutations, islice, repeat, cycle, count, zip_longest, takewhile, dropwhile
from itertools import accumulate, pairwise, groupby, starmap
list(chain([1, 2], [3], [4, 5]))       # [1, 2, 3, 4, 5]
list(product([1, 2], [3, 4]))          # [(1, 3), (1, 4), (2, 3), (2, 4)]
list(combinations([1, 2, 3], 2))       # [(1, 2), (1, 3), (2, 3)]
list(permutations([1, 2]))             # [(1, 2), (2, 1)]
list(islice([1, 2, 3, 4, 5], 1, 4))    # [2, 3, 4]
list(repeat(5, 3))                     # [5, 5, 5]
list(islice(cycle([1, 2]), 4))         # [1, 2, 1, 2]
list(islice(count(10, 5), 3))          # [10, 15, 20]
list(zip_longest([1, 2], [3], fillvalue=0))  # [(1, 3), (2, 0)]
list(takewhile(lambda x: x < 4, [1, 2, 5]))  # [1, 2]
list(dropwhile(lambda x: x < 3, [1, 2, 3, 4]))  # [3, 4]
list(accumulate([1, 2, 3, 4]))         # [1, 3, 6, 10]
list(accumulate([1, 2, 3], initial=10))  # [10, 11, 13, 16]
list(pairwise([1, 2, 3]))              # [(1, 2), (2, 3)]
[(k, list(g)) for k, g in groupby([1, 1, 2, 3, 3])]  # [(1, [1, 1]), (2, [2]), (3, [3, 3])]
list(starmap(lambda a, b: a + b, [(1, 2), (3, 4)]))   # [3, 7]
```

> **注意**：这些函数返回 **惰性迭代器**（与 CPython 同形，`type(...).__name__` 即函数名如 `'chain'` / `'product'`，`iter` 一致性成立）；可被 `list()` / `for` / `islice` 消费，且能配合无限源惰性推进（`islice(chain(count(), [1, 2]), 5)` 正常）
> `product([])` 等含空池调用返回空迭代器（不报错）；`repeat` 指定 `times` 时亦为迭代器（`list(repeat(5, 3))` 得 `[5, 5, 5]`）
> `groupby` 保持相邻分组语义（相同键不相邻时会分成多组）；grouper 为惰性迭代器，消费时用 `list(g)` 转换，且只能消费一次

### `collections` 模块

| 成员 | 说明 |
| :--- | :--- |
| `Counter(iterable)` | 元素计数，缺失键返回 0（底层为 defaultdict(int)） |
| `Counter.most_common(n=None)` | 按出现次数降序返回 `[(元素, 次数)]` 列表，同次数按插入顺序 |
| `defaultdict(default_factory[, init_dict])` | 缺失键自动调用工厂创建默认值 |
| `namedtuple(typename, field_names)` | 生成带命名字段的不可变元组子类；`field_names` 为空白 / 逗号分隔的字符串或字符串可迭代对象；实例支持下标、迭代、解包与按字段名访问，类上提供 `_fields` / `_make(iterable)` / `_replace(**kw)` / 实例方法 `_asdict()` |
| `deque(iterable=[], maxlen=None)` | 双端队列，有界时溢出静默挤出一端，不支持切片 |
| `OrderedDict([init_dict])` | 有序字典，repr 带前缀，键序敏感比较 |

```python
from collections import Counter, defaultdict
Counter("abca")              # Counter({'a': 2, 'b': 1, 'c': 1})
c = Counter("abc"); c["z"]   # 0
c.most_common()              # [('a', 1), ('b', 1), ('c', 1)]
c.most_common(1)             # [('a', 1)]
dd = defaultdict(list); dd["a"].append(1)   # dd["a"] → [1]

Point = namedtuple("Point", "x y")
p = Point(1, 2)
print(p.x, p.y, p[0], len(p))               # 1 2 1 2
print(repr(p))                              # Point(x=1, y=2)
print(list(p), p == (1, 2))                 # [1, 2] True
print(Point._fields)                        # ('x', 'y')
q = Point._make([7, 8])._replace(y=9)
print(q)                                    # Point(x=7, y=9)
print(p._asdict()["x"])                     # 1
```

### `operator` 模块

把内置运算符暴露为普通函数，便于与 `sorted(key=)`、`map` 等函数式工具配合。所有二元/一元函数都走与运算符相同的分派路径，因此自定义类的 `__add__` 等魔法方法同样生效。

| 类别 | 成员 |
| :--- | :--- |
| 算术 | `add` `sub` `mul` `truediv` `floordiv` `mod` `pow` `neg` `pos` `abs` |
| 位运算 | `and_` `or_` `xor` `invert` `lshift` `rshift` |
| 比较 | `eq` `ne` `lt` `le` `gt` `ge` `is_` `is_not` |
| 逻辑 | `not_` `truth` |
| 序列 | `concat` `contains` `getitem` `setitem` `delitem` `countOf` `indexOf` `length_hint` |
| 取值器 | `itemgetter` `attrgetter` |
| 调用 | `methodcaller(name, *args, **kwargs)`（调用目标对象的方法） |
| 矩阵乘 | `matmul` |
| 索引 | `index`（整数协议转换，等价 `__index__`） |

```python
import operator
operator.add(1, 2)                  # 3
operator.floordiv(7, 2)             # 3
operator.invert(5)                  # -6
operator.contains([1, 2, 3], 2)     # True (注意参数顺序: 容器在前)
operator.getitem([10, 20], 1)       # 20
operator.itemgetter(1)(["a", "b"])  # 'b'
operator.attrgetter("x")(obj)       # obj.x

# 与 sorted 配合
pairs = [(2, "b"), (1, "a")]
sorted(pairs, key=operator.itemgetter(0))   # [(1, 'a'), (2, 'b')]

operator.methodcaller("upper")("abc")     # 'ABC' (调用目标对象的方法)
operator.methodcaller("pop")([1, 2, 3])  # 3 (目标对象不再作为尾随实参)
```

> `itemgetter(k1, k2, ...)` / `attrgetter("a", "b")` 返回可调用对象：单参数返回单个值，多参数返回由各值组成的元组；`attrgetter` 的属性名支持 `a.b` 点号路径
> `length_hint(obj)` 在对象无长度信息时返回 0（不抛异常）

### `time` 模块

时间相关功能，对标 CPython 的 `time` 模块；`sleep` 为**协作式挂起**（挂起期间宿主继续运行，不阻塞游戏）

```python
import time
from time import sleep

# 协作式睡眠: 挂起指定秒数后自动恢复; 返回值与 CPython 一致为 None
time.sleep(1.5)
time.sleep(0)

# 时间戳与单调时钟
time.time()             # 当前 Unix 时间戳 (秒, float)
time.time_ns()          # 当前 Unix 时间戳 (纳秒, int)
time.monotonic()        # 单调递增时钟 (秒, 不受系统时间调整影响)
time.monotonic_ns()     # 单调递增时钟 (纳秒)
time.perf_counter()     # 性能计数器 (秒)
time.perf_counter_ns()  # 性能计数器 (纳秒)
time.process_time()     # 当前进程 CPU 时间 (秒)
```

`time.sleep()` 可用于推导式、生成器表达式与生成器函数体内（与 CPython 行为一致）：

```python
import time

[time.sleep(0) for x in range(3)]                       # [None, None, None]
[x for x in [1, 2, 3] if time.sleep(0)]                 # []
list(time.sleep(0) for x in range(2))                   # [None, None]
[v for v in (time.sleep(0) for x in range(2))]          # [None, None]

def counter():
    for i in range(3):
        time.sleep(0)
        yield i
print(list(counter()))                                  # [0, 1, 2]
```

- 参数为非数值时报 `TypeError`，为负数时报 `ValueError`（错误信息与 CPython 一致）
- 支持在生成器函数体内、推导式内以及嵌套生成器（生成器体内再迭代另一个生成器）内调用，行为与 CPython 一致

> **未实现成员**：`strftime` / `strptime` / `gmtime` / `localtime` / `mktime` / `ctime` / `asctime` 未提供（`from time import strftime` 报 `ImportError`）

### `string` 模块（字符串常量）

| 常量 | 值 |
| :--- | :--- |
| `ascii_lowercase` | `'abcdefghijklmnopqrstuvwxyz'` |
| `ascii_uppercase` | `'ABCDEFGHIJKLMNOPQRSTUVWXYZ'` |
| `ascii_letters` | `ascii_lowercase + ascii_uppercase` |
| `digits` | `'0123456789'` |
| `hexdigits` | `'0123456789abcdefABCDEF'` |
| `octdigits` | `'01234567'` |
| `punctuation` | ASCII 标点符号（32 个） |
| `whitespace` | `' \t\n\r\v\f'` |
| `capwords(s, sep=None)` | 按分隔符切分并首字母大写后重新拼接（`sep` 为 `None` 时按空白切分并单空格连接） |
| `printable` | `digits + ascii_letters + punctuation + whitespace` |

```python
import string
string.ascii_letters   # 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
string.digits          # '0123456789'
string.capwords("the quick brown fox")   # 'The Quick Brown Fox'
string.capwords("a_b-c", "-")           # 'A_b-C' (按 '-' 切分)
```

### `sys` 模块

解释器与运行环境信息

| 成员 | 说明 |
| :--- | :--- |
| `version` / `version_info` | 版本字符串与版本元组（对齐 CPython 3.12 形态） |
| `maxsize` | 平台整数上限（`2**63 - 1`） |
| `byteorder` | 宿主字节序（`'little'` / `'big'`） |
| `platform` | 宿主平台（`win32` / `linux` / `darwin`） |
| `argv` | 命令行实参列表（脚本可读写） |
| `executable` | 解释器可执行文件路径 |
| `path` | 用户模块检索目录列表（初始 `[""]`，语义见 [usage.md](usage.md)） |
| `modules` | 模块缓存活视图；`del sys.modules["x"]` 驱逐缓存（再次 `import` 重新加载） |
| `intern(s)` | 字符串驻留（非 `str` 报 `TypeError`） |
| `exc_info()` | 活动异常三元组 `(type, value, traceback)`；无活动异常时为 `(None, None, None)` |
| `exit([code])` | 抛出 `SystemExit`（未捕获时按退出码进入错误终态） |
| `set_int_max_str_digits(n)` / `get_int_max_str_digits()` | 十进制转换上限（`0` 解除上限，非零值须 ≥ 640） |

```python
import sys
sys.maxsize                        # 9223372036854775807
sys.platform                       # 'win32' / 'linux' / 'darwin'
type(sys.modules["sys"]).__name__  # 'module'
del sys.modules["string"]          # 驱逐缓存 (再次 import 重新加载)
sys.intern("a" + "bc")             # 'abc' (驻留)
```

> `sys.exit` 的差异：未捕获时 PyGDS 进入解释器错误终态并报告，CPython 静默结束进程（`SystemExit` 可正常捕获，`.args` 为实参元组）

### `contextlib` 模块

| 成员 | 说明 |
| :--- | :--- |
| `contextmanager(func)` | 把生成器函数转为上下文管理器工厂；产出值绑定 `as` 目标，体异常经 `throw` 注入生成器，抑制则以无异常退出；产物同时是 `ContextDecorator` |
| `closing(thing)` | 退出时调用 `thing.close()` |
| `suppress(*exceptions)` | 抑制列出的异常，未命中的照常传播 |
| `nullcontext(enter_result=None)` | 空上下文管理器（`as` 目标为 `enter_result`） |
| `ExitStack()` | 回调栈：`enter_context(cm)` / `callback(fn, *a, **kw)`（返回回调本身，可作装饰器）/ `push(cm)` / `pop_all()` / `close()`，退出时逆序回放 |

```python
from contextlib import contextmanager, suppress

@contextmanager
def cm(tag):
    print("enter", tag)
    try:
        yield tag
    finally:
        print("exit", tag)

with cm("a") as v:          # enter a / exit a
    print("body", v)

with suppress(ValueError):
    int("x")                 # 不抛出

@cm("deco")                 # contextmanager 产物作装饰器 (ContextDecorator)
def f():
    return 1
f()                         # enter deco / exit deco
```

> 生成器各阶段（进入前 / 暂停点 / 退出时）的 `time.sleep` 与主动挂起 API 支持挂起重放，副作用不重复执行

### `bisect` 模块

| 成员 | 说明 |
| :--- | :--- |
| `bisect_left(a, x[, lo[, hi]][, key=])` | 返回 x 在有序序列中的插入点（相等取左边界） |
| `bisect_right(a, x[, lo[, hi]][, key=])` / `bisect` | 右侧插入点（`bisect` 为标准别名） |
| `insort_left(a, x[, lo[, hi]][, key=])` | 按左边界插入（原地） |
| `insort_right(a, x[, lo[, hi]][, key=])` / `insort` | 按右边界插入（`insort` 为标准别名） |

```python
import bisect
a = [1, 3, 5, 7, 9]
bisect.bisect_left(a, 5)         # 2
bisect.bisect_right(a, 5)        # 3
bisect.bisect_left(a, 5, 0, 3)   # 2 (lo / hi 限定范围)
b = [1, 3, 5, 7]
bisect.insort_left(b, 5)         # b -> [1, 3, 5, 5, 7]
```

> `key=` 只施加于列表元素、不施加于检索值（CPython 语义）；元素不可比较时 `TypeError` 正常传播；`key` 不可调用或索引实参非法按 CPython 校验

### `heapq` 模块

| 成员 | 说明 |
| :--- | :--- |
| `heappush(heap, item)` / `heappop(heap)` | 入堆 / 弹出最小元素（原地维护小顶堆） |
| `heapify(heap)` | 原地建堆 |
| `heapreplace(heap, item)` | 弹出最小元素并推入新元素（空堆报 `IndexError`） |
| `heappushpop(heap, item)` | 推入并弹出最小元素 |
| `nsmallest(n, iterable[, key=])` / `nlargest(n, iterable[, key=])` | 前 n 小 / 前 n 大元素列表 |
| `merge(*iterables[, key=][, reverse=])` | 多路归并（要求各输入已排序），惰性迭代器 |

```python
import heapq
h = []
heapq.heappush(h, 3)
heapq.heappush(h, 1)
heapq.heappop(h)                          # 1
heapq.nsmallest(3, [5, 1, 8, 2, 9, 3])    # [1, 2, 3]
list(heapq.merge([1, 3, 5], [2, 4, 6]))   # [1, 2, 3, 4, 5, 6]
```

### `base64` 模块

| 成员 | 说明 |
| :--- | :--- |
| `b64encode(data[, altchars])` / `b64decode(s[, altchars[, validate]])` | 标准 Base64 编解码（`altchars` 替换 `+/`，如 `b"-_"`） |
| `standard_b64encode` / `standard_b64decode` | 标准字母表 |
| `urlsafe_b64encode` / `urlsafe_b64decode` | URL 安全字母表（`-` `_`） |
| `b16encode(data)` / `b16decode(s)` | Base16 编解码 |
| `encodebytes(data)` / `decodebytes(s)` | 每 76 字符换行的 Base64 文本形态 |

```python
import base64
base64.b64encode(b"hello")        # b'aGVsbG8='
base64.b64decode(b"aGVsbG8=")     # b'hello'
base64.b64encode(b"hi", b"-_")    # 自定义 altchars
base64.b16encode(b"\x01\xab")     # b'01AB'
```

> 编码侧拒绝 `str`（报 `TypeError`），解码侧接受 ASCII `str`；填充不合法按 CPython 报 `ValueError`（长度 mod 4 == 1 与非法填充的文案区分）

### `json` 模块

| 成员 | 说明 |
| :--- | :--- |
| `dumps(obj[, indent][, sort_keys][, separators][, ensure_ascii][, allow_nan][, default])` | 序列化为 JSON 字符串 |
| `loads(s)` | 反序列化（完整解析：字符串转义 / 数值 / 前导零校验 / 嵌套） |
| `dump(obj, fp, ...)` / `load(fp)` | 文件对象读写形态 |
| `JSONDecodeError` | 解析错误异常类（`ValueError` 子类） |

```python
import json
json.dumps({"a": 1})                          # '{"a": 1}'
json.dumps({"a": 1}, indent=2)                # 缩进多行输出
json.dumps({"a": 1}, sort_keys=True, separators=(",", ":"))
json.loads('{"a": [1, 2.5, true, null]}')     # {'a': [1, 2.5, True, None]}
json.dumps(10**40)                            # 大整数原样输出 (任意精度)
```

> `ensure_ascii=False` 输出原生非 ASCII 字符（默认转义为 `\uXXXX`）；`sort_keys` 排序键；`separators=(项分隔符, 键值分隔符)`；`allow_nan=False` 对 `nan` / `inf` 报 `ValueError`；非字符串键按 JSON 字面量转义（`{1: 2}` → `{"1": 2}`，bool 键 → `true` / `false`）；不可序列化对象报 `TypeError`（可传 `default=` 钩子转换）

### `logging` 模块（日志输出）

| 函数 | 级别 |
| :--- | :--- |
| `info(msg)` | INFO |
| `warning(msg)` | WARN |
| `warn(msg)` | WARN（`warning` 的别名，两者等价） |
| `error(msg)` | ERROR |

日志输出写入 `console_output`，受宿主日志级别（`set_log_level`）过滤；返回值均为 `None`

```python
import logging

logging.info("程序启动完成")
logging.warn("配置项缺失，使用默认值")
logging.warning("已弃用的 API，请迁移")
logging.error("数据库连接失败")
```

---

## 内置类型的方法

除了全局内置函数，每个内置类型（`str`、`list`、`tuple`、`dict`）还提供了对标 Python 的方法

详见 [内置类型 builtin_types.md](./builtin_types.md)
