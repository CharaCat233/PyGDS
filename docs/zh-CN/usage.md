# PyGDS 使用指南

PyGDS 是一个嵌入在 Godot 引擎中的类 Python 脚本解释器（DSL）。它实现了 Python 语言的核心子集，使开发者可以在 Godot 项目中使用 Python 风格的语法编写脚本逻辑，同时与 Godot 的原生 API 无缝交互

---

## 快速开始

### 最小示例

```gdscript
var dsl = PyGDS.new()
dsl.write_dsl_script("""
print("Hello, PyGDS!")
a = 1 + 2
print(a)
""")
dsl.run()
```

**输出：**

```txt
Hello, PyGDS!
3
```

### 工作流程

```txt
  PyGDS 实例
      │
      ├── write_dsl_script(source)
      │   ├── Lexer:  源代码 → Token 列表
      │   ├── Parser: Token 列表 → AST 语句列表
      │   └── 存入 self.statements
      │
      └── run()
          ├── 首次执行 (IDLE) 时创建 Interpreter 实例，后续恢复时复用
          ├── interpret(statements) — 遍历执行所有 AST 语句
          ├── 遇到挂起时保存执行栈，返回对应挂起状态
          ├── 收集 print_output / console_output
          └── 返回 State 枚举值反映当前状态
```

---

## 调试模式

### 开启调试输出

```gdscript
var dsl = PyGDS.new()
dsl.set_debug_mode(true)    # 打开调试模式
```

开启调试模式后，`print()` 的输出会直接显示在 Godot 控制台中

### 关闭调试输出

```gdscript
dsl.set_debug_mode(false)
```

关闭调试模式时，输出不会实时打印到控制台，但仍通过 `print_output` 和 `console_output` 属性累积，可以后续读取

---

## 日志级别控制

PyGDS 提供了内置的日志函数，其输出受日志级别控制

```gdscript
dsl.set_log_level(PyGDS.ConsoleReport.Level.WARN)
```

### 可用级别

| 级别常量 | 说明 |
| :--- | :--- |
| `ConsoleReport.Level.DEBUG` | 显示所有日志（最详细） |
| `ConsoleReport.Level.INFO` | 显示 info 及以上 |
| `ConsoleReport.Level.WARN` | 显示 warning 及以上 |
| `ConsoleReport.Level.ERROR` | 只显示 error 和 fatal |
| `ConsoleReport.Level.FATAL` | 只显示 fatal（最精简） |

### DSL 内置日志函数

```python
info("this is info log")       # 对应 ConsoleReport.Level.INFO
warn("this is warning log")    # 对应 ConsoleReport.Level.WARN
error("this is error log")     # 对应 ConsoleReport.Level.ERROR
```

---

## 获取输出

执行完 DSL 脚本后，可以通过以下属性获取所有输出

```gdscript
dsl.run()
print("=== Print Output ===")
print(dsl.print_output)      # 所有 print() 调用的累积输出

print("=== Console Output ===")
print(dsl.console_output)    # 所有日志和错误输出的累积
```

- `print_output`：仅包含 `print()` 函数的输出
- `console_output`：包含日志（`info`/`warn`/`error`）、错误报告等所有控制台输出

---

## 注册外部 API

PyGDS 最强大的功能之一是允许从 DSL 代码调用 Godot 原生函数，通过 `register_api` 注册外部函数

```gdscript
var dsl = PyGDS.new()

dsl.register_api({
    "get_player_name": func(args, kwargs):
        # args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]
        return PyGDS.DSLString.new("Alice"),

    "spawn_enemy": func(args, kwargs):
        var x = 0
        var y = 0
        if args.size() > 0:
            x = int(args[0]._dsl_str())
        if args.size() > 1:
            y = int(args[1]._dsl_str())
        # 在此处调用 Godot 逻辑: 实例化场景, 创建节点等
        # var enemy = enemy_scene.instantiate()
        # enemy.position = Vector2(x, y)
        # get_tree().current_scene.add_child(enemy)
        return PyGDS.DSLNone.new(),

    "get_health": func(args, kwargs):
        # 也可接收 kwargs 参数
        var target = "self"
        if kwargs.has("target"):
            target = kwargs["target"]._dsl_str()
        # 模拟获取生命值
        return PyGDS.DSLInteger.new(100),
})
```

### API 函数签名

每个注册的 API 函数接收两个参数，并必须返回一个 `DSLObject`

```gdscript
func my_api(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
    # 处理参数...
    return PyGDS.DSLString.new("result")
```

**命名约定**：DSLObject 上的方法遵循三层命名规范

| 前缀 | 层级 | 说明 | 示例 |
| :--- | :--- | :--- | :--- |
| `_*` | 内部辅助方法 | 供 GDScript 端调用的底层方法，不在 DSL 代码中直接使用 | `_dsl_str()` |
| `magic_*` | DSL 魔法方法 | 对应 Python 的 dunder 方法，在 DSL 代码中使用 | `__init__`, `__str__` |
| `builtin_*` | DSL 内置方法 | DSL 层面的内置函数，在 DSL 代码中使用 | `print()`, `len()`, `range()` |

### 在 DSL 脚本中调用

```python
name = get_player_name()
print(name)                         # Alice

spawn_enemy(100, 200)               # 在坐标 (100, 200) 生成敌人
spawn_enemy(300)                    # 在 x=300, y=0 生成

hp = get_health(target="enemy")
print(hp)                           # 100
```

### 创建返回值

所有 API 函数必须返回一个 `DSLObject` 实例，PyGDS 提供了以下工厂类

| 工厂 | 创建的值 |
| :--- | :--- |
| `PyGDS.DSLInteger.new(42)` | 整数 42 |
| `PyGDS.DSLFloat.new(3.14)` | 浮点数 3.14 |
| `PyGDS.DSLBool.new(true)` | 布尔值 True |
| `PyGDS.DSLString.new("hello")` | 字符串 "hello" |
| `PyGDS.DSLNone.new()` | None |
| `PyGDS.DSLList.new([...])` | 列表 |
| `PyGDS.DSLTuple.new([...])` | 元组 |
| `PyGDS.DSLDict.new({...})` | 字典 |

> **注意**：`DSLDict` 的键必须是 GDScript `Variant` 类型（`String`/`int`/`float`/`bool`），而非 `DSLObject`

---

## DSL 语法参考

### 变量与赋值

```python
x = 42
y = 3.14
name = "Alice"
flag = True
nothing = None

# 多变量解包
a, b, c = [1, 2, 3]
first, *rest = [10, 20, 30, 40]    # first=10, rest=[20, 30, 40]
```

### 字典合并与解包（Python 3.9+）

`dict` 支持 `|` / `|=` 合并运算符与 `{**a, **b}` 字面量解包，右侧覆盖左侧同键：

```python
d1 = {"a": 1, "b": 2}
d2 = {"b": 3, "c": 4}

d1 | d2              # {'a': 1, 'b': 3, 'c': 4} (返回新字典, 不修改原字典)
d3 = {"a": 1}
d3 |= d2             # 原地合并, d3 → {'a': 1, 'b': 3, 'c': 4}

{**d1, **d2}         # {'a': 1, 'b': 3, 'c': 4}
{**d1, "z": 9}       # {'a': 1, 'b': 2, 'z': 9} (显式键可覆盖解包值)

dict.fromkeys(["a", "b"], 0)    # {'a': 0, 'b': 0} (以可迭代对象为键构造字典)
```

### 字面量 `*` 解包（Python 3.5+）

列表、元组、集合字面量内可用 `*iterable` 展开元素，等价于把该可迭代对象的元素逐个写出：

```python
a = [1, 2, 3]
b = [4, 5]

[*a, 6]              # [1, 2, 3, 6]
[0, *a, *b]          # [0, 1, 2, 3, 4, 5]
[*"ab", "c"]         # ['a', 'b', 'c'] (任意可迭代对象)
[*range(3)]          # [0, 1, 2]
[*{"x": 1}]          # ['x'] (字典迭代键)

(*a,)                # (1, 2, 3) (元组字面量需保留逗号)
(0, *a, 6)           # (0, 1, 2, 3, 6)
sorted({*a, 10})     # [1, 2, 3, 10] (集合字面量; 集合本身无序, 用 sorted 观察元素)
```

> 单元素元组必须写逗号：`(*a,)` 合法，`(*a)` 报 `SyntaxError`（与 Python 一致）
> 推导式元素不支持 `*`（`[*x for x in it]` 报错）；`*` 后必须是可迭代对象，否则抛 `TypeError`

### 赋值表达式 walrus（Python 3.8+）

`x := 1` 是**表达式**：先给变量赋值，再以该值参与运算，常用于在条件里同时完成赋值与判断：

```python
if (n := 10) > 5:
    print(n)                     # 10
if m := 20:                      # 条件位置无需括号
    print(m)                     # 20

while (cur := data[i]) != 0:     # 边读边判断
    i += 1

print(x := 7)                    # 7 (作为实参)
print([(k := 2), k * 3])         # [2, 6]
print({(q := 1): q + 1})         # {1: 2}
print((a := (b := 3)) + a + b)   # 9 (嵌套需加括号)
```

推导式内的赋值表达式绑定到**外层作用域**（与 Python 一致）：

```python
vals = [y := v * 2 for v in range(4)]
print(vals)                      # [0, 2, 4, 6]
print(y)                         # 6 (泄漏到外层, 与 Python 相同)
print([z for v in range(6) if (z := v * v) > 4])   # [9, 16, 25]
```

> 目标必须是简单变量名：`(obj.attr := 1)` / `(lst[0] := 1)` 分别报 `cannot use assignment expressions with attribute` / `with subscript`
> 裸写 `x := 1` 作为语句报 `SyntaxError`（需写成 `(x := 1)`），`del (x := 1)` 报 `cannot delete named expression`——以上均与 Python 一致

**推导式内的两条禁止规则**（与 CPython 一致，均为解析期 `SyntaxError`）：

```python
[i := 0 for i in range(3)]          # assignment expression cannot rebind
                                    # comprehension iteration variable 'i'
[x for x in (y := [1, 2])]          # assignment expression cannot be used in a
                                    # comprehension iterable expression
```

- **不得重绑定推导式循环变量**：赋值表达式的目标名若与本推导式（或任意外层推导式）的循环目标同名即报错；适用于列表/集合/字典/生成器推导式的元素、键值、条件与后续子句的可迭代表达式。跨 `lambda` / `def` 边界不继承（`[lambda: (i := 0) for i in range(3)]` 合法）
- **不得出现在可迭代表达式内**：与名字无关，任何赋值表达式出现在推导式的 `for ... in <此处>` 都会报错，且不区分是否嵌套在 `lambda` / 内层推导式里

### 数字字面量

支持十六进制、八进制、二进制、下划线分隔与科学计数法：

```python
0x1F          # 31
0o17          # 15
0b101         # 5
1_000_000     # 1000000
0xFF_FF       # 65535
1_000.5       # 1000.5
1e3           # 1000.0
2.5e-2        # 0.025
```

**进制转换**：`int(str, base)` 支持按进制解析字符串，`base=0` 时按 `0x`/`0o`/`0b` 前缀自动识别：

```python
int("ff", 16)       # 255
int("101", 2)       # 5
int("0x1f", 0)      # 31 (自动识别十六进制前缀)
int("-ff", 16)      # -255 (支持符号)
```

### 运算符

| 类别 | 运算符 |
| :--- | :--- |
| 算术 | `+`, `-`, `*`, `/`, `//`, `%`, `**` |
| 比较 | `==`, `!=`, `<`, `>`, `<=`, `>=` |
| 逻辑 | `and`, `or`, `not` |
| 赋值 | `=`, `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `**=` |
| 赋值表达式 | `:=`（walrus） |
| 成员检查 | `in`, `not in` |

`%` 运算符在字符串上执行 printf 风格格式化：

```python
"%s is %d years old" % ("Alice", 30)   # "Alice is 30 years old"
"%5.2f" % 3.14159                      # " 3.14"
"%x" % 255                             # "ff"
"%05d" % 42                            # "00042"
"%d%%" % 50                            # "50%"
```

支持转换说明 `%s` `%r` `%d` `%i` `%u` `%f` `%F` `%e` `%E` `%g` `%G` `%x` `%X` `%o` `%c` `%%`，以及标志（`-` `+` 空格 `0`）、宽度与精度

**`str.format`**：支持位置/关键字参数与格式说明符（对齐、填充、符号、零填充、宽度、千分位、精度、类型）

```python
"{} and {}".format(1, 2)            # "1 and 2"
"{name} = {value:.2f}".format(name="pi", value=3.14159)   # "pi = 3.14"
"{:>8}".format("hi")                # "      hi"
"{0:04d}".format(42)                # "0042"
"{{{}}}".format(5)                  # "{5}"
```

### 字符串插值 (f-string)

支持 Python 3.6+ 的 f-string 语法，可在字符串中直接嵌入表达式

```python
name = "Alice"
age = 30
print(f"Hello, {name}!")            # Hello, Alice!
print(f"Age: {age}")                # Age: 30
print(f"Sum: {1 + 2}")              # Sum: 3
print(f"Upper: {'hello'.upper()}")  # Upper: HELLO
print(f"literal {{braces}}")        # literal {braces}
```

**格式说明符**：支持对齐（`<` `>` `^` `=`）、填充字符、符号（`+` `-` 空格）、零填充、宽度、千分位逗号、精度与类型（`d` `f` `e` `g` `s` `x` `X` `o` `b` `c` `%`）

```python
print(f"{42:05d}")                  # 00042
print(f"{3.14159:.2f}")             # 3.14
print(f"|{42:>6}|")                 # |    42|
print(f"|{'hi':*^8}|")              # |***hi***|
print(f"{255:x} {5:b} {8:o}")       # ff 101 10
print(f"{1000000:,}")               # 1,000,000
print(f"{0.25:.1%}")                # 25.0%
```

**转换标志**：`!s`（str）、`!r`（repr）、`!a`（ascii）

```python
print(f"{[1, 2, 3]!r}")             # [1, 2, 3]
```

**嵌套表达式**：支持字典/列表下标、函数调用、三目表达式等

```python
d = {"k": "v"}
print(f"d = {d['k']}")              # d = v
lst = [10, 20, 30]
print(f"lst[1] = {lst[1]}")         # lst[1] = 20
```

**`=` 调试说明符**（Python 3.8+）：输出 `表达式源码=值`，便于调试；默认用 `repr`，可叠加转换标志与格式说明符

```python
x = 42
s = "hi"
print(f"{x=}")              # x=42
print(f"{s=}")              # s='hi'
print(f"{x=:05d}")          # x=00042
print(f"{x + y=}")          # x + y=47
```

**嵌套格式宽度/精度**：宽度与精度可由变量在运行期决定（`f"{x:{w}d}"`）

```python
w = 8
print(f"{123:0{w}d}")       # 00000123
print(f"{'abc':>{w}}")      #      abc
p = 2
print(f"{3.14159:.{p}f}")   # 3.14
```

### 条件语句

```python
if x > 0:
    print("positive")
elif x < 0:
    print("negative")
else:
    print("zero")
```

### 循环语句

```python
# while 循环
i = 0
while i < 5:
    print(i)
    i = i + 1

# for 循环 (列表)
for item in [1, 2, 3]:
    print(item)

# for 循环 (字典键)
for key in {"a": 1, "b": 2}:
    print(key, d[key])

# for 循环 (字符串字符)
for ch in "ABC":
    print(ch)

# range 循环
for i in range(5):
    print(i)    # 0, 1, 2, 3, 4

# break / continue
for i in range(10):
    if i == 3:
        continue
    if i == 7:
        break
    print(i)    # 0, 1, 2, 4, 5, 6
```

### 函数定义

```python
# 基本函数
def greet(name):
    return "Hello, " + name

print(greet("World"))   # Hello, World

# 默认参数
def power(x, n=2):
    return x ** n

print(power(5))         # 25
print(power(5, 3))      # 125

# 位置参数 (/ 之前)
def f(a, b, /, c, d=0):
    print(a, b, c, d)

f(1, 2, 3)              # 1 2 3 0
f(1, 2, c=3)            # 1 2 3 0

# *args 可变参数
def sum_all(a, b, *args):
    total = a + b
    for x in args:
        total = total + x
    return total

print(sum_all(1, 2, 3, 4, 5))   # 15

# 关键字参数和 **kwargs
def config(host, *, port=80, **kwargs):
    print(host, port, kwargs)

config("localhost", port=8080, debug=True, timeout=30)
# localhost 8080 {"debug": True, "timeout": 30}
```

### lambda 匿名函数

支持 Python 的 `lambda` 表达式，行为与普通函数一致（可调用、可作 `sort`/`map`/`filter` 的 `key`/函数参数）

```python
# 基本用法
f = lambda x: x * 2
print(f(21))                        # 42

# 立即调用
print((lambda x: x + 1)(9))         # 10

# 默认参数
g = lambda a, b=10: a + b
print(g(5))                         # 15
print(g(5, 100))                    # 105

# 无参数
h = lambda: "no args"
print(h())                          # no args

# 作为 sort / sorted 的 key
lst = [3, 1, 2]
lst.sort(key=lambda x: -x)
print(lst)                          # [3, 2, 1]

# 与 map / filter 配合
print(list(map(lambda x: x ** 2, [1, 2, 3])))               # [1, 4, 9]
print(list(filter(lambda x: x % 2 == 0, [1, 2, 3, 4])))     # [2, 4]

# 捕获外部变量 (闭包)
base = 100
add_base = lambda x: x + base
print(add_base(1))                  # 101
```

### 调用处 `*`/`**` 解包

函数调用时可用 `*iterable` 将可迭代对象解包为位置参数，`**mapping` 将字典解包为关键字参数：

```python
def add(a, b, c=0):
    return a + b + c

add(*[1, 2])                # 3        (*list 解包)
add(*[1, 2, 3])             # 6
add(1, *[2])                # 3        (混合位置与 *)
add(1, **{"b": 2, "c": 3})  # 6        (**dict 解包)
add(*[1], **{"b": 2})       # 3        (* 与 ** 同时)
print(*[1, 2, 3], sep="-")  # 1-2-3    (与内置函数配合)
```

### import 与内置模块

支持 `import` / `from-import` 导入内置模块（`math` / `random` / `statistics` / `functools` / `itertools` / `collections` / `string` / `operator`）：

```python
import math
math.sqrt(16)                 # 4.0

import math as m
m.floor(3.7)                  # 3

from math import sqrt, pi as p
sqrt(9)                       # 3.0

from math import *
gcd(12, 18)                   # 6

import operator
sorted([(2, "b"), (1, "a")], key=operator.itemgetter(0))   # [(1, 'a'), (2, 'b')]
```

> **注意**：目前仅支持内置模块，不支持导入用户编写的 `.py` 文件，模块详情见 [内置模块文档](./builtin.md)

### global / nonlocal

```python
x = 1

def outer():
    y = 2

    def inner():
        nonlocal y
        y = 3       # 修改外层变量

    inner()
    print(y)        # 3

def change_global():
    global x
    x = 100         # 修改全局变量

print(x)            # 1
outer()             # 3
print(x)            # 1
change_global()
print(x)            # 100
```

### 推导式与生成器表达式

**列表 / 字典 / 集合推导式**：

```python
[x * x for x in range(5) if x % 2 == 0]       # [0, 4, 16]
{k: v for k, v in [("a", 1), ("b", 2)]}       # {'a': 1, 'b': 2}
{x * x for x in [1, 2, 2, 3]}                 # {1, 4, 9} (自动去重)
```

**多 `for` 子句**：推导式可写多个 `for`（按书写顺序嵌套，内层可引用外层循环变量），
每个 `for` 都可带多个 `if`；列表/字典/集合推导式与生成器表达式全部支持：

```python
[x * y for x in [1, 2] for y in [10, 20]]     # [10, 20, 20, 40]
[x + y for x in range(3) for y in range(x)]   # [1, 2, 3] (内层依赖外层)

[x for x in range(10) if x % 2 == 0 if x > 4] # [6, 8] (同一 for 多个 if)
[x * y for x in range(5) if x % 2 == 1 for y in range(3) if y != 1]

{k: v for k, v in [("a", 1), ("b", 2)] if v > 1}   # {'b': 2}
sorted({x * y for x in [1, 2] for y in [2, 3]})    # [2, 3, 4, 6]

list(x * y for x in [1, 2] for y in [10, 20])      # [10, 20, 20, 40] (生成器)
```

**元组目标**：循环变量可写成 `k, v` 形式，按序列顺序解包每个元素：

```python
[k for k, v in [("a", 1), ("b", 2)]]          # ['a', 'b']
{v * 10 for k, v in [("a", 1), ("b", 2)]}     # {10, 20}
```

**生成器表达式**：`(expr for var in iterable [if cond])` 求值为惰性生成器对象，每次 `next()` 或迭代时逐一产出，适合大序列与无限序列；可作函数位置参数（裸写法）：

```python
g = (x * x for x in range(5))
type(g)                 # <class 'generator'>
list(g)                 # [0, 1, 4, 9, 16]

next(g2)                # 逐次推进 (一次性迭代器, 耗尽后停止)
sum(x * x for x in range(4))     # 14 (裸写法)
list(x for x in range(6) if x % 2 == 0)    # [0, 2, 4]

from itertools import islice
list(islice((x * x for x in count()), 5))   # [0, 1, 4, 9, 16] (配合无限序列)
```

> **⚠️ 破坏性变更（v0.3.0）**：此前 `(x for x in it)` 被当作列表推导式**急切求值为列表**，现在改为**惰性生成器对象**
> 旧代码若直接对结果下标/`len()`/调用列表方法会报错，需先用 `list(g)` / `tuple(g)` 转换
> 生成器为**一次性迭代器**，重复迭代不会从头开始

### `time` 模块与 sleep

`sleep()` 位于 `time` 模块（与 CPython 一致，CPython 同样没有裸 `sleep`），是**协作式挂起**：挂起期间宿主继续运行，超时后自动恢复，不阻塞游戏

```python
import time
from time import sleep

print("start")
time.sleep(1.0)          # 挂起 1.0 秒后自动恢复
print("after")           # 输出顺序与 CPython 一致

time.sleep(0)            # 立即恢复; 返回值与 CPython 一致为 None
print(time.sleep(0) is None)     # True

# 时间戳与单调时钟
time.time()              # 当前 Unix 时间戳 (秒)
time.time_ns()           # 当前 Unix 时间戳 (纳秒)
time.monotonic()         # 单调递增时钟 (秒)
time.perf_counter()      # 性能计数器 (秒)
```

`sleep()` 可用于推导式、生成器表达式与生成器函数体内：

```python
[time.sleep(0) for x in range(3)]                  # [None, None, None]
[x for x in [1, 2, 3] if time.sleep(0)]            # []
list(time.sleep(0) for x in range(2))              # [None, None]
[v for v in (time.sleep(0) for x in range(2))]     # [None, None]

def counter():
    for i in range(3):
        time.sleep(0)
        yield i
print(list(counter()))                             # [0, 1, 2]
print(sum(counter()))                              # 3
```

> **⚠️ 破坏性变更（v0.5.0-alpha.1）**：裸 `sleep(n)` 不再存在，须 `import time` 后调用 `time.sleep(n)`

### 生成器函数 (`yield`)

`def` 函数体内含 `yield` 即为生成器函数：**调用时不执行函数体**，返回惰性生成器对象，每次 `next()` / `send()` / `for` 从上次 `yield` 之后继续执行。局部变量跨 `yield` 保持，闭包正常可见：

```python
def counter(n):
    i = 0
    while i < n:
        yield i
        i += 1

type(counter(3))        # <class 'generator'>
list(counter(3))        # [0, 1, 2]
next(counter(3))        # 0 (逐次推进, 一次性迭代器)

g = counter(2)
print(next(g), next(g)) # 0 1
print(list(g))          # [] (已耗尽)
print(list(g))          # [] (重复迭代不从头开始)

# for / 消费函数均可用
total = 0
for x in counter(4):
    total += x
print(total)            # 6
print(sum(counter(5)))  # 10
```

**表达式级 `yield` 与 `send`**：`yield` 是表达式，恢复时注入 `send` 值（`next()` 注入 `None`）：

```python
def echo():
    v = yield "start"
    yield v

g = echo()
print(next(g))          # start
print(g.send("hello"))  # hello (v 为 send 值)
```

**`yield from` 委托**：把子可迭代对象的元素逐个产出，耗尽后表达式的值为子生成器的 `return` 值（`send` / `throw` 不转发给子生成器，`x = yield from it` 赋值形式暂不支持）：

```python
def sub():
    yield 1
    return "done"
def parent():
    r = yield from sub()
    yield "got:" + r
list(parent())          # [1, 'got:done']
```

**`throw` / `close`**：在挂起位置注入异常 / `GeneratorExit`（`finally` 正常执行）：

```python
def guarded():
    try:
        yield 1
    except ValueError:
        yield "handled"
    finally:
        print("cleanup")

g = guarded()
next(g)                 # 1
print(g.throw(ValueError("e")))   # handled
g.close()               # cleanup
```

**`return` 值 → `StopIteration.value`**：生成器 `return value` 时，`next()` 超出的 `StopIteration` 携带该值：

```python
def with_value():
    yield 1
    return 42
g = with_value()
next(g)
try:
    next(g)
except StopIteration as e:
    print(e.value)      # 42
```

> **⚠️ 破坏性变更（v0.4.0）**：`yield` 现为保留关键字，不能再用作变量名等标识符
> **⚠️ 已知差异**：生成器体内调用 `sleep()` 会报错（与挂起系统暂不共存）；`yield` 恢复采用语句重执行，含副作用的前缀表达式会在恢复时重复求值（如 `f(a(), (yield 1))` 中 `a()` 执行两次）；`x = yield from it` 赋值形式不支持

### `slice` 对象

`slice(start, stop[, step])` 构造切片对象，可保存复用，用于 `lst[slice(...)]` / `"str"[slice(...)]`：

```python
s = slice(1, 4)
s.start / s.stop / s.step   # 1 / 4 / None (未指定为 None)
lst[slice(1, 4)]            # 等价于 lst[1:4]
lst[slice(0, 6, 2)]         # 等价于 lst[0:6:2]
lst[slice(4, 0, -1)]        # 负步长反向
"abcdef"[slice(1, 4)]       # "bcd"
isinstance(s, slice)        # True
```

### 列表 / 元组 / 字典操作

```python
# 列表
lst = [1, 2, 3]
lst.append(4)
lst.extend([5, 6])
last = lst.pop()
lst.insert(0, 99)
lst.remove(99)
print(lst.index(3))
print(lst.count(2))
lst.reverse()
lst.sort()

# 列表解包
a, b, c = [10, 20, 30]

# 字典
d = {"name": "Alice", "age": 30}
print(d["name"])
print(d.get("city", "N/A"))
d["city"] = "Beijing"
print(d.keys())
print(d.values())
d["age"] = None
d.pop("age")
d.update({"x": 1})

# 字典迭代
for key in d:
    print(key, d[key])
```

### 异常处理

```python
try:
    result = 10 / 0
except ZeroDivisionError as e:
    print("caught:", e)          # caught: ZeroDivisionError: division by zero
except (TypeError, ValueError):
    print("type or value error")
except:
    print("unknown error")
else:
    print("no error occurred")
finally:
    print("cleanup")
```

### 自定义类与魔法方法

```python
class Vec:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __add__(self, other):
        return Vec(self.x + other.x, self.y + other.y)

    def __str__(self):
        return "Vec(" + str(self.x) + ", " + str(self.y) + ")"

    def __eq__(self, other):
        return self.x == other.x and self.y == other.y

a = Vec(10, 20)
b = Vec(5, 10)
c = a + b
print(c)                        # Vec(15, 30)
print(a == b)                   # False
print(c == Vec(15, 30))         # True
```

### 自定义异常类

```python
class AppError(Exception):
    def __init__(self, msg, code):
        self.code = code

try:
    raise AppError("not found", 404)
except AppError as e:
    print(e.code)               # 404
    print(e.args)               # ("not found", 404)
    print(str(e))               # AppError: not found

# 异常继承
class NetworkError(AppError):
    def __init__(self, msg, code, url):
        self.url = url

try:
    raise NetworkError("timeout", 503, "/api/data")
except AppError as e:           # 父类可捕获子类
    print("caught:", str(e))
```

### 继承

```python
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return self.name + " makes a sound"

class Dog(Animal):
    def speak(self):
        return self.name + " barks"

d = Dog("Buddy")
print(d.speak())                # Buddy barks
```

#### `super()` 调用父类方法

支持 Python 3 风格的零参数 `super()`，在子类方法中调用父类方法或构造函数，也支持双参数形式 `super(Class, obj)`

```python
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return self.name + " makes a sound"

class Dog(Animal):
    def __init__(self, name):
        super().__init__(name)          # 调用父类构造函数

    def speak(self):
        return super().speak() + " (from Dog)"   # 调用父类方法

d = Dog("Buddy")
print(d.speak())                # Buddy makes a sound (from Dog)

# 多层继承链: super() 沿继承链逐层向上
class A:
    def val(self):
        return 1
class B(A):
    def val(self):
        return super().val() + 10
class C(B):
    def val(self):
        return super().val() + 100
print(C().val())                # 111

# 双参数形式 super(Class, obj)
class Q(P):
    def greet(self):
        return "child"
q = Q()
print(super(Q, q).greet())      # parent
```

> **注意**：`super()` 只能在类的方法内使用（静态方法中无 self/cls，会抛出 `RuntimeError: super(): no arguments`）。

### assert 断言

```python
def divide(a, b):
    assert b != 0, "divisor cannot be zero"
    return a / b

divide(10, 0)   # AssertionError: divisor cannot be zero
```

---

## 错误处理

### 检查执行状态

```gdscript
var dsl = PyGDS.new()
dsl.write_dsl_script(source_code)
var state = dsl.run()

if state == PyGDS.State.ERROR:
    print("DSL execution failed!")
    print("Error: ", dsl.report.last_error)
elif state == PyGDS.State.FINISHED:
    print("DSL execution succeeded!")
```

### 常见错误示例

```python
# 语法错误 (在 write_dsl_script 阶段检测)
print("hello"                 # 缺少右括号 → 解析错误

# 运行时错误
x = 1 + "hello"               # TypeError
lst = [1, 2, 3]
print(lst[5])                 # IndexError
d = {"key": "value"}
print(d["missing"])           # KeyError

# 除零错误
print(10 / 0)                 # ZeroDivisionError
print(10 // 0)                # ZeroDivisionError
print(10 % 0)                 # ZeroDivisionError
```

### 运行时错误行号

未捕获的运行时错误会在错误消息后附加出错语句所在的行号，便于定位问题

```python
a = 1
b = 2
c = a + undefined_var         # NameError: name 'undefined_var' is not defined (line 3)
```

错误消息通过 `dsl.report.last_error` 获取，格式为 `错误类型: 错误信息 (line N)`。

### 调试技巧

```python
# 使用 print 进行调试输出
x = 42
print("DEBUG: x =", x)       # 输出到 print_output

# 使用日志函数
info("entering function foo")
warn("potential issue detected")
error("unexpected state")
```

---

## 缩进说明

> **重要**：PyGDS 使用**空格缩进**，与 Python 一致，每 4 个空格为一个缩进层级
>
> GDScript 原生要求使用 **硬制表符（Tab）** 作为缩进。如果你在 Godot 编辑器中直接以字符串形式编写 DSL 代码，无需担心此问题——PyGDS 的 `write_dsl_script` 会将字符串原样传入词法分析器
>
> 但如果需要将从 Python 文件复制来的代码嵌入到 GDScript 字符串中，请注意 GDScript 字符串内不支持真正的 Tab 缩进（在 Godot 编辑器中 Tab 会自动被替换）。此时建议使用脚本编辑器或外部文本编辑器编写 DSL 代码，然后以文件形式加载

---

## 复用 PyGDS 实例

```gdscript
var dsl = PyGDS.new()
dsl.set_debug_mode(true)

# 第一次执行
dsl.write_dsl_script("""
x = 10
print(x)
""")
dsl.run()

# 第二次执行 — 每次 write_dsl_script 会清空之前的输出
dsl.write_dsl_script("""
y = 20
print(y)
print(x)  # 错误: x 不在作用域内！
""")
dsl.run()
```

> **注意**：每次调用 `write_dsl_script` 都会创建一个全新的解析环境（新的 AST 语句列表），并重置内部状态。首次 `run()` 会创建 `Interpreter` 实例，后续挂起恢复时复用同一实例。因此变量不会在两次 `write_dsl_script` 之间共享，但挂起恢复期间变量会保留

### 查看两轮执行的输出

```gdscript
dsl.write_dsl_script("print(1)")
dsl.run()
var output1 = dsl.print_output

dsl.write_dsl_script("print(2)")
dsl.run()
var output2 = dsl.print_output

print("Round 1:", output1)   # Round 1: 1
print("Round 2:", output2)   # Round 2: 2
```

---

## 挂起系统

PyGDS 提供了挂起（Suspend）机制，允许 DSL 脚本在执行过程中暂停，等待外部条件满足后恢复执行。这在游戏开发中非常有用，例如等待动画播放完毕、等待玩家输入、或实现延时逻辑

挂起系统将挂起分为两种类型

| 类型 | 状态 | 触发方式 | 恢复方式 |
| :--- | :--- | :--- | :--- |
| SLEEPING | `SUSPENDED_SLEEPING` | `sleep(n)` / `request_suspend_sleeping(n)` | Timer 超时后自动恢复 |
| WAITING | `SUSPENDED_WAITING` | `request_suspend_waiting()` (GDScript 端) | 外部设置 `state = RUNNING` 后调用 `run()` |

### 状态机

`PyGDS.State` 枚举定义了 DSL 实例的完整生命周期

- `IDLE`：初始状态，尚未执行
- `RUNNING`：正在执行中
- `SUSPENDED_SLEEPING`：SLEEPING 挂起，Timer 超时后自动恢复
- `SUSPENDED_WAITING`：WAITING 挂起，等待外部设置 `state = RUNNING` 后手动恢复
- `FINISHED`：执行完毕
- `ERROR`：执行出错

`run()` 方法返回当前状态，外部代码根据返回值决定后续行为

### SLEEPING 挂起

SLEEPING 挂起适用于已知等待时间的场景，例如战斗中的技能冷却、对话中的文字打印延时。`request_suspend_sleeping` 内部通过 `SceneTree.create_timer` 创建 Timer，超时后自动调用 `run()` 恢复执行

***DSL 内置函数***

```python
sleep(1.5)  # 挂起 1.5 秒后自动恢复
```

***GDScript 端直接调用***

```gdscript
dsl.request_suspend_sleeping(2.0)  # 挂起 2 秒后自动恢复

# 也可传入 on_resume 回调, 在 run() 恢复执行前调用
dsl.request_suspend_sleeping(2.0, func():
    print("即将从 SLEEPING 恢复")
)
```

***自定义恢复回调***

如果你需要在每次 Timer 超时后执行额外逻辑（如更新 UI），可以设置 `_sleeping_resume_callback`。该回调在 `run()` 恢复执行**前**被调用（注意：Timer 超时后始终由 `run()` 自动恢复，回调仅用于附加逻辑，不应再调用 `run()`）：

```gdscript
dsl._sleeping_resume_callback = func():
    print("从 SLEEPING 恢复")
    # 更新 UI 等附加逻辑 (不要在此调用 run())
```

> **注意**：`_sleeping_resume_callback` 在每次调用后被清除。如需在每次 SLEEPING 恢复时都触发，请在回调中或状态处理函数中重新设置

### WAITING 挂起

WAITING 挂起适用于等待时间不确定的场景，例如等待玩家点击按钮、等待动画播放完毕、等待网络请求返回

***GDScript 端使用***

WAITING 挂起不是 DSL 内置函数，而是通过注册的 API 函数在 GDScript 端调用 `request_suspend_waiting()` 触发

```gdscript
# 注册 API 来触发 WAITING 挂起
dsl.register_api_pair("wait_for_confirm", func(_args, _kwargs):
    dsl.request_suspend_waiting()
    # 执行挂起, run() 将返回 SUSPENDED_WAITING
)

dsl.write_dsl_script("""
print("请确认...")
wait_for_confirm()
print("已确认!")
""")

# 首次执行
var state = dsl.run()
# state == PyGDS.State.SUSPENDED_WAITING

# 外部恢复
dsl.state = PyGDS.State.RUNNING
state = dsl.run()
# 继续执行, 输出 "已确认!"
```

***自定义恢复回调***

`request_suspend_waiting` 支持可选的 `on_resume` 回调参数，在恢复执行**前**自动调用，适合执行清理或状态切换逻辑

```gdscript
dsl.register_api_pair("play_animation", func(args, _kwargs):
    var name = args[0].value
    print("开始播放动画: " + name)
    dsl.request_suspend_waiting(func():
        print("动画 '%s' 播放完毕!" % name)
    )
)
```

当外部恢复执行时，`on_resume` 回调先触发，然后 DSL 从挂起点继续执行

### 挂起 API 执行顺序

请注意，在 API 侧调用挂起请求函数（`request_suspend_sleeping` 与 `request_suspend_waiting`）时，总是 **先执行完函数再挂起** 的，例如

```gdscript
func move():
    move_start()
    request_suspend_waiting()  # on_resume = Callable()
    move_end()
```

该段代码的执行顺序为 `move_start -> request_suspend_waiting -> move_end -> 挂起 -(恢复后)-> on_resume.call()`

若需要代码块在恢复后运行，请使用 `on_resume` 参数，例如

```gdscript
func move():
    move_start()
    request_suspend_waiting(move_end)  # on_resume = move_end
```

该段代码的执行顺序为 `move_start -> request_suspend_waiting -> 挂起 -(恢复后)-> move_end.call()`

### 事件驱动执行模式

在实际游戏中使用挂起系统时，推荐采用 **事件驱动** 模式而非轮询：

```gdscript
# 推荐: 事件驱动
func _step_execute():
    var state = dsl.run()
    match state:
        PyGDS.State.SUSPENDED_SLEEPING:
            pass  # Timer 回调会自动触发 _step_execute()
        PyGDS.State.SUSPENDED_WAITING:
            show_continue_button()  # 等待用户点击
        PyGDS.State.FINISHED:
            on_script_finished()
        PyGDS.State.ERROR:
            on_script_error()

func _on_continue_button():
    dsl.state = PyGDS.State.RUNNING
    _step_execute()
```

### 预设代码

`set_preset_script` 允许在用户代码之前注入预设代码（如常量定义、工具函数），预设代码与用户代码 **独立解析**，确保错误行号准确

```gdscript
var dsl = PyGDS.new()

dsl.set_preset_script("""
MAX_HP = 100
def clamp(value, lo, hi):
    if value < lo:
        return lo
    if value > hi:
        return hi
    return value
""")

dsl.write_dsl_script("""
print(MAX_HP)         # 100
print(clamp(150, 0, 100))  # 100
""")
```

预设代码和用户代码的 AST 在解析后拼接执行，因此同名变量/函数/类会被后续定义覆盖，符合 Python 语义

## 限制与注意事项

### 浮点精度

由于底层使用 GDScript 的双精度浮点数（`float` 即 64 位 IEEE 754），与 Python 的浮点计算存在细微差异

```python
# Godot 的 str() 与 Python 的 str() 输出格式可能不同
print(1.15)  # 在 Godot 中可能输出 "1.15", 而 Python 中为 "1.15"
print(1.0 / 3.0)  # 浮点精度一致, 但字符串表示可能不同
```

### 字符串方法差异

| 方法 | 与 Python 的差异 |
| :--- | :--- |
| `strip()` | 使用 Godot 的 `strip_edges()`，行为与 Python 的 `.strip()` 有细微差异 |
| `split()` | 支持 `maxsplit` 参数，与 Python 一致 |
| `find()` | 仅支持单参数查找，不支持 `start`/`end` 范围参数 |

---

## 完整使用示例

### 游戏脚本中的 property

```gdscript
func configure_item_system(dsl: PyGDS):
    dsl.write_dsl_script("""
class Item:
    def __init__(self, name, price):
        self._name = name
        self._price = price

    @property
    def name(self):
        return self._name

    @property
    def price(self):
        return self._price

    @price.setter
    def price(self, value):
        if value < 0:
            raise ValueError("Price cannot be negative")
        self._price = value

    @property
    def info(self):
        return "{}: {} gold".format(self.name, self.price)

sword = Item("Sword", 100)
print(sword.name)         # 通过 getter 读取
print(sword.price)        # 100
sword.price = 150         # 通过 setter 写入
print(sword.info)         # "Sword: 150 gold" — 计算属性
""")
    dsl.run()
```

### 游戏脚本系统

```gdscript
# Godot 场景脚本
extends Node

var dsl: PyGDS

func _ready():
    dsl = PyGDS.new()
    dsl.set_debug_mode(true)

    # 注册游戏 API
    dsl.register_api({
        "say": func(args, _kwargs):
            var msg = args[0]._dsl_str()
            print("[NPC] " + msg)
            return PyGDS.DSLNone.new(),

        "give_item": func(args, _kwargs):
            var item_name = args[0]._dsl_str()
            var count = 1
            if args.size() > 1:
                count = int(args[1]._dsl_str())
            # inventory.add_item(item_name, count)
            print("Gave " + str(count) + " " + item_name + "(s) to player")
            return PyGDS.DSLNone.new(),

        "get_player_level": func(_args, _kwargs):
            return PyGDS.DSLInteger.new(42),
    })

    # 执行游戏脚本
    dsl.write_dsl_script("""
say("Welcome to the game!")

if get_player_level() >= 10:
    say("You are experienced!")
    give_item("Sword", 1)
else:
    say("Take this starter kit.")
    give_item("Dagger", 2)
    give_item("Potion", 5)
""")
    dsl.run()

    if dsl.report.has_error:
        print("Script error: ", dsl.report.last_error)
```

### 配置文件解释器

```gdscript
func load_config(config_text: String) -> Dictionary:
    var dsl = PyGDS.new()
    dsl.set_debug_mode(false)

    # 注册一个 API 将 Python 字典返回给 Godot
    var exported_config = {}
    dsl.register_api({
        "export_config": func(args, _kwargs):
            var raw_dict = args[0]
            # 将 DSLDict 转为 Godot Dictionary
            if raw_dict is PyGDS.DSLObject and raw_dict.fields.has("_obj"):
                raw_dict = raw_dict.fields["_obj"]
            if raw_dict is PyGDS.DSLDict:
                for key in raw_dict.dict.keys():
                    var val = raw_dict.dict[key]
                    if val is PyGDS.DSLString:
                        exported_config[key] = val.value
                    elif val is PyGDS.DSLInteger:
                        exported_config[key] = val.value
                    elif val is PyGDS.DSLFloat:
                        exported_config[key] = val.value
            return PyGDS.DSLNone.new(),
    })

    dsl.write_dsl_script(config_text)
    dsl.run()

    if dsl.report.has_error:
        push_error("Config error: " + dsl.report.last_error)
        return {}

    return exported_config

# 使用示例
var config = load_config("""
export_config({
    "window_width": 1920,
    "window_height": 1080,
    "fullscreen": True,
    "title": "My Game",
    "volume": 0.75
})
""")
print(config)  # {"window_width": 1920, "window_height": 1080, ...}
```
