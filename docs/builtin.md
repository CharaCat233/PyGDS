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

---

## 内置类型的方法

除了全局内置函数，每个内置类型（`str`、`list`、`tuple`、`dict`）还提供了对标 Python 的方法

详见 [内置类型 builtin_types.md](./builtin_types.md)
