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

对应 Python `dict` 类型构造函数，支持两种调用方式

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

### `info(msg)`

模仿 Python `logging.info()`，输出 INFO 级别的日志消息

```python
info("程序启动完成")
```

### `warn(msg)`

模仿 Python `logging.warn()`，输出 WARN 级别的日志消息

`warn()` 是 `warning()` 的别名，两者等价

```python
warn("配置项缺失，使用默认值")
warning("已弃用的 API，请迁移")
```

### `warning(msg)`

模仿 Python `logging.warning()`，输出 WARN 级别的日志消息

```python
warning("建议使用新的 API")
```

### `error(msg)`

模仿 Python `logging.error()`，输出 ERROR 级别的日志消息

```python
error("数据库连接失败")
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

模仿 Python `range()`，生成整数序列（列表）

- 返回类型：`list` (DSLList)

```python
range(5)                 # [0, 1, 2, 3, 4]
range(2, 5)              # [2, 3, 4]
range(0, 10, 2)          # [0, 2, 4, 6, 8]
```

### `type(obj)`

对应 Python `type()`，返回对象的类型对象

- 无参时返回 `"<class 'NoneType'>"` 字符串
- 对于有 klass 的对象，返回其所属的 DSLClass（类型对象）
- 对于内置值对象，尝试从全局作用域查找类型类

```python
type(42)                 # <class 'int'> (返回 DSLClass)
type("hello")            # <class 'str'> (返回 DSLClass)
type(type)               # <class 'type'> (返回 DSLClass)
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

### `hash(obj)`

对应 Python `hash()`，返回对象的哈希值

- 接收恰好 1 个参数
- 支持用户自定义 `__hash__` 方法
- 返回类型：`int`（DSLInteger）

### `round(number, ndigits=0)`

对应 Python `round()`，对数字进行四舍五入

```python
round(3.14)              # 3
round(3.14, 1)           # 3.1
```

### `abs(x)`

对应 Python `abs()`，返回数的绝对值

```python
abs(-42)                 # 42
abs(-3.14)               # 3.14
```

### `min(iterable)` / `min(a, b, ...)`

对应 Python `min()`，返回最小值

```python
min([3, 1, 4, 1, 5])     # 1
min(3, 1, 4)             # 1
```

### `max(iterable)` / `max(a, b, ...)`

对应 Python `max()`，返回最大值

```python
max([3, 1, 4, 1, 5])     # 5
max(3, 1, 4)             # 4
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

### `sorted(iterable, reverse=False)`

对应 Python `sorted()`，返回排序后的新列表

```python
sorted([3, 1, 2])        # [1, 2, 3]
sorted([3, 1, 2], reverse=True)  # [3, 2, 1]
```

### `reversed(seq)`

对应 Python `reversed()`，返回反向迭代器

```python
list(reversed([1, 2, 3]))  # [3, 2, 1]
```

### `enumerate(iterable, start=0)`

对应 Python `enumerate()`，返回 `(index, value)` 枚举序列

```python
list(enumerate(["a", "b"]))  # [(0, "a"), (1, "b")]
```

### `iter(iterable)`

对应 Python `iter()`，返回对象的迭代器

```python
it = iter([1, 2, 3])
```

### `zip(*iterables)`

对应 Python `zip()`，并行迭代多个可迭代对象

```python
list(zip([1, 2], ["a", "b"]))  # [(1, "a"), (2, "b")]
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

### `sleep(seconds)`

模仿 Python `time.sleep()`，挂起当前 DSL 脚本执行指定的秒数，超时后自动恢复

- `seconds`：挂起时长（秒），必须为非负数值

```python
sleep(1.5)  # 挂起 1.5 秒后自动恢复
sleep(0.0)  # 立即恢复 (无延迟)
```

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

### `map(func, iterable, ...)`

对应 Python `map()`，对可迭代对象的每个元素应用函数

- 支持多个可迭代对象（逐元素并行传入函数）
- **注意**：本实现为立即求值并返回列表（非 CPython 的惰性 map 对象），但行为上可与 `list()`/`for` 循环等配合使用

```python
list(map(lambda x: x * 2, [1, 2, 3]))          # [2, 4, 6]
list(map(str, [1, 2, 3]))                      # ["1", "2", "3"]
list(map(lambda a, b: a + b, [1, 2], [10, 20])) # [11, 22]
```

### `filter(func, iterable)`

对应 Python `filter()`，保留满足条件的元素

- `func` 为 `None` 时按元素真值过滤
- **注意**：本实现为立即求值并返回列表

```python
list(filter(lambda x: x > 1, [0, 1, 2, 3]))   # [2, 3]
list(filter(None, [0, 1, "", "a", []]))        # [1, "a"]
```

---

## 内置模块 (import)

PyGDS 支持 `import` / `from-import` 语法导入内置模块，当前提供 `math` 与 `random` 两个纯逻辑模块（引擎相关能力建议通过 `register_api()` 由 GDScript 侧提供）

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
| 常量 | `pi` `e` `tau` |
| 基础 | `sqrt` `isqrt` `floor` `ceil` `trunc` `fabs` `fmod` `pow` |
| 指数/对数 | `exp` `log` `log2` `log10` |
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
```

### `random` 模块

| 函数 | 说明 |
| :--- | :--- |
| `seed(n)` | 设置随机种子（可复现序列） |
| `random()` | 返回 `[0, 1)` 的浮点数 |
| `uniform(a, b)` | 返回 `[a, b]` 的浮点数 |
| `randint(a, b)` | 返回 `[a, b]` 的整数（含端点） |
| `randrange(start, stop, step)` | 返回范围内的随机整数 |
| `choice(seq)` | 从序列中随机选一个元素 |
| `shuffle(seq)` | 原地打乱列表 |
| `sample(population, k)` | 返回 k 个不重复的随机元素 |

```python
import random
random.seed(42)
random.random()        # [0, 1) 内
random.randint(1, 6)   # 1..6 内
```

> **注意**：PyGDS 使用内置 xorshift32 PRNG，数值序列与 CPython 的 Mersenne Twister **不同**；但 `seed()` 可保证在 PyGDS 内部复现相同序列

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

```python
import statistics
statistics.mean([1, 2, 3, 4])        # 2.5
statistics.median([1, 2, 3, 4])      # 2.5
statistics.mode([1, 2, 2, 3])        # 2
round(statistics.stdev([1, 2, 3]), 6)  # 1.0
```

### `functools` 模块

| 函数 | 说明 |
| :--- | :--- |
| `reduce(func, iterable[, initial])` | 从左到右累积归约 |
| `partial(func, *args, **kwargs)` | 偏函数（预绑定部分参数） |

```python
from functools import reduce, partial
reduce(lambda a, b: a + b, [1, 2, 3, 4])   # 10
add5 = partial(lambda a, b: a + b, 5)
add5(3)                                    # 8
```

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

```python
from itertools import chain, product, combinations, permutations, islice, repeat, cycle, count, zip_longest, takewhile, dropwhile
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
```

> **注意**：这些函数当前返回完整的 `list`（`list(chain(...))` 直接得到结果，不需要再包一层 `list()`）。无限对象（`repeat`/`cycle`/`count`）必须配合 `islice`/`takewhile` 等惰性消费，不能直接 `list()`

### `collections` 模块

| 成员 | 说明 |
| :--- | :--- |
| `Counter(iterable)` | 元素计数，缺失键返回 0（底层为 defaultdict(int)） |
| `Counter.most_common(n=None)` | 按出现次数降序返回 `[(元素, 次数)]` 列表，同次数按插入顺序 |
| `defaultdict(default_factory[, init_dict])` | 缺失键自动调用工厂创建默认值 |

```python
from collections import Counter, defaultdict
Counter("abca")              # Counter({'a': 2, 'b': 1, 'c': 1})
c = Counter("abc"); c["z"]   # 0
c.most_common()              # [('a', 1), ('b', 1), ('c', 1)]
c.most_common(1)             # [('a', 1)]
dd = defaultdict(list); dd["a"].append(1)   # dd["a"] → [1]
```

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
| `printable` | `digits + ascii_letters + punctuation + whitespace` |

```python
import string
string.ascii_letters   # 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
string.digits          # '0123456789'
```

---

## 内置类型的方法

除了全局内置函数，每个内置类型（`str`、`list`、`tuple`、`dict`）还提供了对标 Python 的方法

详见 [内置类型 builtin_types.md](./builtin_types.md)
