# 异常系统

PyGDS 实现了与 Python 高度一致的异常处理机制，包括 `raise`、`try/except`、异常继承体系以及自定义异常类

---

## DSLException — 底层异常对象

`DSLException` 是 PyGDS 底层用于表示异常的原始对象，直接继承自 `DSLObject`

### 类结构

```gdscript
class DSLException extends DSLObject:
    # 错误消息字符串
    var message: String
    # 异常类型名称
    var error_type: String
    # 额外的异常参数
    var args: Array[DSLObject] = []
```

### 核心方法

| 方法 | 行为 |
| :--- | :--- |
| `_type_name()` | 返回 `error_type`（异常类型名） |
| `_dsl_str()` | 若 `message` 非空：`"ErrorType: message"`；否则：`"ErrorType"` |
| `_dsl_bool()` | 始终返回 `true`（异常对象的布尔值总是真） |
| `_dsl_eq(other)` | 比较 `error_type` 和 `message` 是否都相同 |

### 构造示例

```gdscript
var exc = DSLException.new("division by zero", "ZeroDivisionError", [])
print(exc._dsl_str())    # ZeroDivisionError: division by zero
print(exc._type_name())  # ZeroDivisionError
print(exc._dsl_bool())   # true
```

---

## 异常类体系

PyGDS 将异常类型定义为 **`DSLClass` 实例**，而非单独的构造函数类，所有异常类都通过 `_define_exception` 函数统一注册

### 内置异常层次结构

```python
Exception                          # 根基类
├── TypeError                      # 类型错误
├── ValueError                     # 值错误
├── RuntimeError                   # 运行时错误
├── NameError                      # 名称错误
├── KeyError                       # 键错误
├── IndexError                     # 索引错误
├── AttributeError                 # 属性错误
├── ArithmeticError                # 算术错误
│   └── ZeroDivisionError          # 除零错误
├── StopIteration                  # 迭代停止
└── AssertionError                 # 断言错误
```

### 注册机制 — `_define_exception`

位于 `PyGDS.Interpreter._define_exception`

```gdscript
func _define_exception(type_name: String, base_name: String = "Exception"):
    var base_class = null
    if base_name != "":
        base_class = globals.get_val(base_name)

    var methods = {}
    # 1. 注入 __new__ (使用 _make_builtin 创建)
    var obj_new = _make_builtin("__new__", Callable(self, "api_object_new"))
    if obj_new is DSLBuiltinFunction:
        methods["__new__"] = obj_new

    # 2. 注入 __init__ (使用 _exception_init 回调)
    var init_desc = DSLMethodDescriptor.new("__init__", Callable(self, "_exception_init"))
    methods["__init__"] = init_desc

    # 3. 注入 __str__ (使用 _exception_str 回调)
    var str_desc = DSLWrappedDescriptor.new("__str__", Callable(self, "_exception_str"))
    methods["__str__"] = str_desc

    # 4. 创建 DSLClass 并注册到全局作用域
    var class_obj = DSLClass.new(type_name, base_class, methods, self)
    globals.define(type_name, class_obj)
    exception_hierarchy[type_name] = base_name
```

***参数说明***

| 参数 | 说明 |
| :--- | :--- |
| `type_name` | 异常类型的名称（如 `"TypeError"`） |
| `base_name` | 父异常类型名称，默认为 `"Exception"`，传入 `""` 表示无父类（仅根 Exception 使用） |

**内置异常注册顺序**（在 `register_builtins` 中）

```gdscript
_define_exception("Exception", "")              # 根基类, 无父类
_define_exception("TypeError")                  # 默认继承自 Exception
_define_exception("ValueError")
_define_exception("RuntimeError")
_define_exception("NameError")
_define_exception("KeyError")
_define_exception("IndexError")
_define_exception("AttributeError")
_define_exception("ArithmeticError")
_define_exception("ZeroDivisionError", "ArithmeticError")   # 指定父类
_define_exception("StopIteration")
_define_exception("AssertionError")
```

---

## `_exception_init` 回调 — 异常构造过程

位于 `PyGDS.Interpreter._exception_init`

当 `DSLClass` 的 `magic_call` 被调用时（即 `TypeError("some message")`），首先 `__new__` 创建 `DSLObject` 包装器，然后 `__init__` 触发 `_exception_init` 回调：

```gdscript
func _exception_init(exc_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
    var wrapper = exc_args[0]               # DSLObject (由 __new__ 创建)
    var pos_args: Array[DSLObject] = []
    for i in range(1, exc_args.size()):
        pos_args.append(exc_args[i])        # 收集位置参数
    var msg = ""
    if pos_args.size() > 0:
        msg = pos_args[0]._dsl_str()        # 第一个参数 = 消息
    var exc = DSLException.new(msg, wrapper.klass.name, pos_args)
    wrapper._wrapped = exc                  # 将 DSLException 存入 _wrapped
    wrapper.fields["args"] = DSLTuple.new(pos_args)  # 将参数存入 args
    return DSLNone.new()
```

### 执行流程

```txt
TypeError("bad type")
    │
    ▼
1. DSLClass("TypeError").magic_call([DSLString.new("bad type")])
    │
    ▼
2. __new__ 创建 DSLObject 包装器
    │  wrapper.klass = TypeError_class
    │
    ▼
3. __init__ → _exception_init(wrapper, pos_args)
    │  创建 DSLException(msg="bad type", error_type="TypeError", args=[DSLString("bad type")])
    │  存入 wrapper._wrapped
    │  存入 wrapper.fields["args"]
    │
    ▼
4. 返回 DSLObject (wrapper)
```

这就意味着

- `e.args` 返回一个 `DSLTuple`，包含传递给异常构造函数的参数
- `e._wrapped` 存储底层的 `DSLException` 对象
- `str(e)` 通过 `_exception_str` 回调获取字符串表示

---

## `_exception_str` 回调 — 异常的字符串表示

位于 `PyGDS.Interpreter._exception_str`

```gdscript
func _exception_str(exc_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
    var wrapper = exc_args[0]
    var raw = wrapper._wrapped
    if raw and raw is DSLException:
        return DSLString.new(raw._dsl_str())
    return DSLString.new(wrapper._type_name())
```

当调用 `str(e)` 时，解释器查找异常类上的 `__str__`，最终调用此回调。它会从 `wrapper._wrapped` 取出底层 `DSLException` 并返回其字符串表示

***示例***

```python
e = TypeError("bad type")
print(str(e))     # TypeError: bad type
print(e.args)     # ("bad type",)
```

---

## `raise` 语句执行流程

当解释器执行 `raise` 语句时，经过以下流程

```gdscript
if stmt is RaiseStmt:
    if stmt.expression != null:
        var exc = evaluate(stmt.expression)       # 1. 求值 raise 表达式
        if exc == null:
            return ExecResult.RAISE                # 求值失败, 向上传播

        var is_valid = false
        var err_type = ""
        var err_msg = ""

        if exc is DSLException:
            is_valid = true                        # 2a. 原始 DSLException
            err_type = exc.error_type
            err_msg = exc.message
        elif exc.fields != null:
            var exc_type = globals.get_val("Exception")
            if exc_type is DSLClass and exc._is_subclass_of_klass(exc_type):
                is_valid = true                    # 2b. DSLObject 且继承自 Exception
                err_type = exc._type_name()
                if exc._wrapped is DSLException:
                    err_msg = exc._wrapped.message
                elif exc.fields.has("args") and exc.fields["args"] is DSLTuple \
                    and exc.fields["args"].items.size() > 0:
                    err_msg = exc.fields["args"].items[0]._dsl_str()

        if is_valid:
            last_exception = exc                   # 3. 设置 last_exception
            report.error(err_type + ": " + err_msg) # 4. 报告错误
        else:
            raise_exception("TypeError", "exceptions must derive from Exception")
        return ExecResult.RAISE                    # 5. 返回 RAISE 状态
```

### 流程图

```txt
raise SomeError("msg")
        │
        ▼
1. evaluate(SomeError("msg"))
   → DSLClass("SomeError").magic_call → DSLObject
        │
        ▼
2. 验证异常类型合法性
   ├── 是 DSLObject 且继承自 Exception？ → 合法
   └── 否 → raise TypeError("exceptions must derive from Exception")
        │
        ▼
3. 设置 Interpreter.last_exception = exc
        │
        ▼
4. report.error(error_type + ": " + message)
        │
        ▼
5. 返回 ExecResult.RAISE
   → exec_block 检测到 RAISE → 向调用栈上方传播
```

### `raise` 重新抛出

```python
try:
    1 / 0
except ZeroDivisionError:
    print("caught")
    raise  # 重新抛出当前异常
```

当 `raise` 不带表达式时，解释器会检查 `last_exception` 是否已设置，并使用它进行重新抛出

---

## `try/except` 异常匹配

### `_is_exception_match` — 匹配核心

位于 `PyGDS.Interpreter._is_exception_match`

```gdscript
func _is_exception_match(exc, type_expr) -> bool:
    if type_expr == null:
        return true                              # 无类型限制 → 匹配所有

    var saved_has_error = report.has_error
    report.has_error = false
    var type_obj = evaluate(type_expr)           # 求值 except 类型表达式
    report.has_error = saved_has_error

    if type_obj == null:
        return false

    if type_obj is DSLTuple:                     # 元组形式: except (TypeError, ValueError)
        for item in type_obj.items:
            if item is DSLClass and exc.fields != null:
                if exc._is_subclass_of_klass(item):
                    return true
        return false

    if not type_obj is DSLClass:                 # 必须是 DSLClass
        return false

    if exc.fields != null:
        return exc._is_subclass_of_klass(type_obj)  # 检查继承关系

    return false
```

### 匹配规则

1. **单类型匹配**：`except TypeError` — 只有 `TypeError` 及其子类匹配
2. **元组匹配**：`except (TypeError, ValueError)` — 任一类型或其子类匹配
3. **无类型匹配**：`except` — 匹配所有异常
4. **继承感知**：利用 `_is_subclass_of_klass` 沿着类继承链检查

### `_is_subclass_of_klass` — 继承链检查

位于 `PyGDS.DSLObject._is_subclass_of_klass`

```gdscript
func _is_subclass_of_klass(target: DSLClass) -> bool:
    var current = klass
    while current != null:
        if current == target:
            return true
        current = current.superclass
    return false
```

从当前实例的类开始，沿着 `superclass` 链向上查找，检查是否到达目标类

---

## 自定义异常类

由于异常类型使用标准的 `DSLClass` 实现，用户可以像定义普通类一样定义自己的异常类

```python
class MyError(Exception):
    def __init__(self, msg, code):
        self.code = code

try:
    raise MyError("something failed", 404)
except MyError as e:
    print(e.code)       # 404
    print(e.args)       # ("something failed", 404)
    print(str(e))       # MyError: something failed
```

### 自定义异常的执行流程

```txt
class MyError(Exception):
    ↓
DSLClass("MyError", superclass=Exception_class, methods={...})
    ↓
raise MyError("failed", 404)
    ↓
1. MyError_class.magic_call([DSLString("failed"), DSLInteger(404)])
    │
2. __new__ 创建 DSLObject wrapper
    │  wrapper.fields = {}
    │
3. __init__ → 用户定义的 __init__
    │  wrapper.fields["code"] = DSLInteger(404)   ← 用户自定义属性
    │  (同时 _exception_init 也会被调用，设置 _wrapped 和 args)
    │
4. 返回 DSLObject (含有 code、_wrapped、args 字段)
    ↓
except MyError as e:
    ↓
_is_exception_match(exc, MyError_class)
    → exc._is_subclass_of_klass(MyError_class)
    → klass = MyError_class → superclass = Exception_class → null() → false
    → 但在当前类匹配成功！
```

### 多层继承支持

```python
class AppBaseError(Exception):
    def __init__(self, msg):
        pass

class NetworkError(AppBaseError):
    def __init__(self, msg, status_code):
        self.status_code = status_code

try:
    raise NetworkError("timeout", 503)
except AppBaseError as e:        # 父类匹配子类
    print("caught by base")
except NetworkError as e:        # 精确匹配
    print("caught by network")
```

由于 `_is_subclass_of_klass` 遍历整个继承链，`except AppBaseError` 能捕获 `NetworkError`

---

## `raise_exception` — 内置异常抛出工具

位于 `PyGDS.Interpreter.raise_exception`

解释器内部使用 `raise_exception` 方法快速创建并抛出异常：

```gdscript
func raise_exception(err_type: String, msg: String):
    var exc_class = globals.get_val(err_type)
    if exc_class is DSLClass:
        var exc_args: Array[DSLObject] = [DSLString.new(msg)]
        last_exception = exc_class.magic_call(exc_args, {})
    else:
        last_exception = DSLException.new(msg, err_type)
    report.error(err_type + ": " + msg)
```

***使用示例（解释器内部）***

```gdscript
raise_exception("TypeError", "cannot add int and str")
raise_exception("ZeroDivisionError", "division by zero")
raise_exception("RuntimeError", "maximum step count exceeded")
```

### `raise_exception_from_last_error` — 错误传播

位于 `PyGDS.Interpreter.raise_exception_from_last_error`

```gdscript
func raise_exception_from_last_error(last_err: String):
    var colon_idx = last_err.find(": ")
    if colon_idx != -1:
        raise_exception(last_err.substr(0, colon_idx), last_err.substr(colon_idx + 2))
    else:
        raise_exception("RuntimeError", last_err)
```

当 `last_error` 字符串包含格式化的错误信息（如 `"TypeError: bad operand"`），此函数解析出异常类型并调用 `raise_exception`

---

## 异常存储结构

下图展示了 Raised 异常在内存中的完整结构

```txt
last_exception (DSLObject)
├── klass → DSLClass("MyError")
│   ├── superclass → DSLClass("Exception")
│   └── methods["__init__"] → user __init__ + _exception_init
│
├── _wrapped → DSLException
│   ├── message = "failed"
│   ├── error_type = "MyError"
│   └── args = [DSLString("failed"), DSLInteger(404)]
│
└── fields:
    ├── "args" → DSLTuple( [DSLString("failed"), DSLInteger(404)] )
    │
    └── "code" → DSLInteger(404)  ← 用户自定义属性
```

**访问路径：**

| Python 表达式 | 实际访问路径 |
| :--- | :--- |
| `str(e)` | `wrapper._wrapped._dsl_str()` |
| `e.args` | `wrapper.fields["args"]` |
| `e.code` | `wrapper.fields["code"]` |
| `type(e).__name__` | `wrapper.klass.name` |
| `isinstance(e, MyError)` | `wrapper._is_subclass_of_klass(MyError_class)` |

---

## `try/except/finally` 完整执行流程

```txt
try:
    # 语句块
except TypeError as e:
    # 处理 TypeError
except (ValueError, RuntimeError):
    # 处理这两个
except:
    # 兜底
else:
    # 无异常时执行
finally:
    # 始终执行
```

1. 执行 `try` 块中的语句
2. 若执行正常（返回 `ExecResult.NORMAL`），执行 `else` 块（如果存在）
3. 若返回 `ExecResult.RAISE`
   - 依次尝试每个 `except` 子句
   - 对每个子句调用 `_is_exception_match(last_exception, type_expr)`
   - 找到匹配后，将 `last_exception` 绑定到 `as` 变量
   - 执行该 `except` 块的语句
   - 清除 `last_exception`
4. 无论是否发生异常，始终执行 `finally` 块
5. 若 `finally` 块中又有 `return`/`raise`/`break`/`continue`，它将覆盖之前的状态

---

## 错误报告系统 — ConsoleReport

位于 `PyGDS.ConsoleReport`

`ConsoleReport` 负责收集和报告 DSL 执行过程中的所有错误和日志

### 关键属性

```gdscript
class ConsoleReport:
    var has_error: bool = false        # 是否有未处理的错误
    var last_error: String = ""        # 最近一次错误信息
    var log_entries: Array = []        # 日志条目列表
```

### 日志级别

| Level | 值 | 说明 |
| :--- | :--- | :--- |
| `PRINT` | -1 | 强制输出（不受日志级别过滤） |
| `ALL` | 0 | 所有级别 |
| `TRACE` | 1 | 追踪 |
| `DEBUG` | 2 | 调试信息 |
| `INFO` | 3 | 一般信息 |
| `WARN` | 4 | 警告 |
| `ERROR` | 5 | 错误 |
| `FATAL` | 6 | 致命错误 |
| `OFF` | 7 | 关闭所有输出 |

### 错误报告方法

| 方法 | 说明 |
| :--- | :--- |
| `error(msg)` | 报告一个错误，设置 `has_error = true`，`last_error = msg` |
| `fatal_error(msg)` | 报告致命错误并终止执行 |
| `info(msg)` | 记录一条 info 日志 |
| `warn(msg)` | 记录一条 warning 日志 |

---

## 调试与错误追踪

### 示例：完整异常处理流程

```python
def divide(a, b):
    if b == 0:
        raise ZeroDivisionError("cannot divide by zero")
    return a / b


try:
    result = divide(10, 0)
    print(result)
except ZeroDivisionError as e:
    print("caught:", e)        # caught: ZeroDivisionError: cannot divide by zero
except TypeError as e:
    print("type error:", e)
except:
    print("unknown error")
finally:
    print("cleanup")           # cleanup
```

### 异常不匹配时的传播

如果 `try` 块中抛出的异常不被任何 `except` 子句匹配，异常会向上传播到外层调用栈

```python
def inner():
    raise ValueError("bad value")


def outer():
    try:
        inner()
    except TypeError:            # ValueError 不匹配 TypeError
        print("type error")
    # ValueError 继续向上传播

outer()  # ValueError: bad value → 未捕获的异常
```

### 多层嵌套 try/except

```python
try:
    try:
        raise ValueError("inner")
    except TypeError:
        print("inner type error")    # 不匹配
    # ValueError 传播到外层
except ValueError as e:
    print("outer caught:", e)        # outer caught: ValueError: inner
```
