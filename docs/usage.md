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
          ├── 创建 Interpreter 实例
          ├── interpret(statements) — 遍历执行所有 AST 语句
          ├── 收集 print_output / console_output
          └── report.has_error 反映执行结果
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

### 运算符

| 类别 | 运算符 |
| :--- | :--- |
| 算术 | `+`, `-`, `*`, `/`, `//`, `%`, `**` |
| 比较 | `==`, `!=`, `<`, `>`, `<=`, `>=` |
| 逻辑 | `and`, `or`, `not` |
| 赋值 | `=`, `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `**=` |
| 成员检查 | `in`, `not in` |

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
dsl.run()

if dsl.report.has_error:
    print("DSL execution failed!")
    print("Error: ", dsl.report.last_error)
else:
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

> **注意**：每次调用 `write_dsl_script` 都会创建一个全新的解析环境（新的 AST 语句列表），而 `run()` 会创建一个新的 `Interpreter` 实例，因此变量不会在两次 `run()` 之间共享

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

## 性能考虑

### 步数限制

解释器有一个步数上限（`max_steps`），默认为防止无限循环而设置。每次执行一条语句时会递增步数计数器，超出限制时自动抛出异常

```python
# 默认情况下下面的无限循环会被中断
# while True:
#     pass
# → RuntimeError: maximum step count exceeded
```

### 每次 run() 的开销

- 创建新的 `Interpreter` 实例
- 注册所有内置函数和异常类型
- 构建全局作用域链

这意味着频繁调用 `write_dsl_script` + `run()` 时会有固定开销，对于性能敏感的场景，建议将逻辑集中在一次执行中完成

---

## 限制与注意事项

### 不支持的特性

| 特性 | 状态 |
| :--- | :--- |
| `import` / 模块系统 | ❌ 不支持 |
| `async` / `await` | ❌ 不支持 |
| `yield` / 生成器 | ❌ 不支持 |
| `with` 语句 | ❌ 不支持 |
| `classmethod` / `staticmethod` 装饰器 | ✅ 支持 |
| `@property` 装饰器 | ✅ 支持（getter / setter / deleter 完整支持） |
| 多继承 | ❌ 不支持（仅单继承） |
| `set` 类型 | ❌ 不支持 |
| comprehension（列表推导/字典推导） | ✅ 支持 |
| `lambda` 表达式 | ❌ 不支持 |
| `try/except/finally` 中 `else` 和 `finally` | ✅ 支持（部分） |

### 浮点精度

由于底层使用 GDScript 的双精度浮点数（`float` 即 64 位 IEEE 754），与 Python 的浮点计算存在细微差异

```python
# Godot 的 str() 与 Python 的 str() 输出格式可能不同
print(1.15)  # 在 Godot 中可能输出 "1.15"，而 Python 中为 "1.15"
print(1.0 / 3.0)  # 浮点精度一致，但字符串表示可能不同
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
