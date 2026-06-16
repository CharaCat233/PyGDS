# 类与实例系统

## 概述

PyGDS 的类与实例系统严格对标 CPython 的对象模型，实现了类的继承、方法查找、描述符协议以及 `__new__` → `__init__` 双阶段构造流程

内置类型的方法通过 `_inject_builtin_methods()` 方法注入

| 类 | 对标 CPython |
| :--- | :--- |
| `DSLClass` | `PyType_Type` |
| `DSLObject` | `PyObject`（同时充当基类和实例） |

---

## DSLClass

`DSLClass` 表示一个 Python 类（对标 CPython 的 `type` 类型），它存储类名、方法字典、基类引用和类属性

```gdscript
class DSLClass extends DSLObject:
    var name: String               # 类名 (如 "MyClass", "int", "list")
    var superclass: DSLClass       # 基类, 可为 null (仅 object 的基类为 null)
    var methods: Dictionary        # 方法名 → DSLFunction / DSLBuiltinFunction / DSLMethodDescriptor / DSLWrappedDescriptor
    var class_attrs: Dictionary    # 类属性 (如 class_var = 100)
    var interp: Interpreter        # 解释器引用
```

---

## DSLObject 作为实例

DSLObject 不仅仅是基类，它直接充当所有类实例的角色，自身承担实例功能

```gdscript
class DSLObject:
    var klass: DSLClass            # 所属的类 (仅在作为实例时有值)
    var fields: Dictionary         # 实例属性字典 (name → DSLObject), 用户自定义类为 {}
    var _wrapped                   # 底层原始对象: 异常实例存 DSLException, 内置类型子类实例存 DSLInteger/DSLFloat 等
    var interp: Interpreter        # 解释器引用
```

DSLObject 通过 `fields` 是否为 `null` 来区分两种角色

- `fields != null`：表示这是一个 **实例**（用户类实例或内置类型包装）
- `fields == null`：表示这是 **值对象**（如 DSLInteger、DSLString 等纯值类型）

### `_wrapped` 字段

`_wrapped` 是一个独立的存储槽，用于在 DSLObject 包装器内部保存底层对象，主要用于两类场景

- **内置类型子类实例**：`MyInt(5)` → `DSLObject(klass=MyInt, fields={}, _wrapped=DSLInteger(5))`
- **异常实例**：`TypeError("msg")` → `DSLObject(klass=TypeError, fields={"args": ...}, _wrapped=DSLException(...))`

它仅承担**存储**职责，不参与方法分派。属性查找始终通过 `klass` → MRO 完成，确保子类重载不被绕过

### `_dsl_getattribute(name)` — 属性访问链路

这是实例属性查找的完整链路，位于 `PyGDS.DSLObject._dsl_getattribute`

```gdscript
func _dsl_getattribute(name: String) -> DSLObject:
    # 1. 首先检查实例字段
    if fields != null and fields.has(name):
        return fields[name]

    # 2. 从类中查找方法 (沿 MRO 链)
    if klass != null:
        var method = klass._dsl_getattribute(name)
        if method != null and not (method is DSLNone) and method.has_method("__get__"):
            return method.__get__(self, klass)  # 描述符协议：绑定到当前实例
        if method != null and not (method is DSLNone):
            return method

    # 3. 如果存在 __getattr__, 则调用它
    if klass != null:
        var getattr_method = klass._lookup_method("__getattr__")
        if getattr_method != null:
            return klass._invoke_func(getattr_method, [self, DSLString.new(name)] as Array[DSLObject], {} as Dictionary)

    return DSLNone.new()
```

**查找优先级：** 实例字段 → 类描述符链（MRO）→ `__getattr__` 回退

### `_dsl_setattr(name, value)` — 设置实例属性

位于 `PyGDS.DSLObject._dsl_setattr`

```gdscript
func _dsl_setattr(name: String, value: DSLObject):
    # 1. 如果存在属性描述符, 使用 __set__ 设置
    if klass != null:
        var attr = klass._dsl_getattribute(name)
        if attr != null and not (attr is DSLNone) and attr.has_method("__set__"):
            attr.__set__(self, value)
            return

    # 2. 如果类定义了 __setattr__, 调用它
    if klass != null:
        var setattr_method = klass._lookup_method("__setattr__")
        if setattr_method != null:
            klass._invoke_func(setattr_method, [self, DSLString.new(name), value] as Array[DSLObject], {} as Dictionary)
            return

    # 3. 直接存储在实例的 fields 字典中
    if fields != null:
        fields[name] = value
        return
    last_error = "TypeError: '%s' object has no __dict__" % _type_name()
```

**设置优先级：** 属性描述符 (`__set__`) → 类 `__setattr__` → 实例 `fields` 字典

### `_dsl_str()` — 字符串表示

位于 `PyGDS.DSLObject._dsl_str`

```gdscript
func _dsl_str() -> String:
    if _wrapped != null and _wrapped is DSLException:
        return _wrapped._dsl_str()
    if fields != null and klass != null:
        return "<%s object>" % klass.name
    return "<%s object at 0x%x>" % [_type_name(), _object_id]
```

### `_type_name()` — 类型名称

位于 `PyGDS.DSLObject._type_name`

```gdscript
func _type_name() -> String:
    if klass != null:
        return klass.name
    return "object"
```

---

## DSLClass 属性查找

### `DSLClass._dsl_getattribute(name)` — 类属性/方法查找

位于 `PyGDS.DSLClass._dsl_getattribute`，用于在类上查找属性（访问 `MyClass.method` 时走此链路）

```gdscript
func _dsl_getattribute(name: String) -> DSLObject:
    # 1. 查找方法
    if methods.has(name):
        var method = methods[name]
        if method is DSLBuiltinFunction:
            return method
        if method.has_method("__get__"):
            return method.__get__(null, self)  # 描述符协议: null 实例 = 返回描述符本身
        return method

    # 2. 查找类属性
    if class_attrs.has(name):
        return class_attrs[name]

    # 3. 沿超类链查找
    var super_klass = superclass
    while super_klass != null:
        var result = super_klass._dsl_getattribute(name)
        if result != null and not (result is DSLNone):
            return result
        super_klass = super_klass.superclass

    # 4. 未找到, 返回 DSLNone (不再委托给 DSLObject 父类，避免无限递归)
    return DSLNone.new()
```

**查找优先级：** 方法字典 → 类属性 → 超类链（MRO）→ DSLNone

注意：最后一步返回 `DSLNone.new()` 而非 `super._dsl_getattribute(name)`，因为后者会再次调用 `klass._dsl_getattribute` 形成无限递归

---

## 双阶段构造流程

`__new__` → `__init__` 双阶段构造流程是 PyGDS 中对象创建的核心流程，严格对标 CPython

### 完整流程

```txt
MyClass(args...)
    ↓
DSLClass.magic_call(args, kwargs)
    ↓
    1. _lookup_method("__new__")
       → 在继承链上查找 __new__
       → 默认落在 object.__new__（api_object_new）
    ↓
    2. _invoke_func(new_func, [class, ...args], kwargs)
       → 调用 __new__
       → 返回一个 fields={} 的 DSLObject（无 _wrapped）
    ↓
    3. 检查：instance._is_subclass_of_klass(self) ?
       → 是 → 继续
       → 否 → 直接返回 instance
    ↓
    4. _lookup_method("__init__")
       → 在继承链上查找 __init__
       → 默认落在 object.__init__（pass）或类型的 api_*_init
    ↓
    5. _invoke_func(init_func, [instance, ...args], kwargs)
       → 调用 __init__
       → 初始化实例属性（fields）或设置 _wrapped
    ↓
    6. 返回 instance
```

### `object.__new__` 的实现

位于 `PyGDS.Interpreter.api_object_new`

```gdscript
func api_object_new(args, _kwargs):
    var cls = args[0]
    if not cls is DSLClass:
        raise_exception("TypeError", "object.__new__(X): X is not a type object")
        return null
    var obj = DSLObject.new()
    obj.klass = cls
    obj.fields = {}
    obj.interp = self
    return obj
```

仅创建一个空的 DSLObject 实例（`fields = {}`），不做任何属性初始化

### `object.__init__` 的实现

在 `object` 类中定义为

```python
class object:
    def __init__(self):
        pass
```

用户定义的 `__init__` 覆盖此默认实现

### 内置类型的 `__init__`

内置类型（`int`、`float`、`str`、`list`、`tuple`、`dict`、`bool`）的 `__init__` 在 `PyGDS.Interpreter.register_builtins` 中注册，调用对应的 `api_<type>_init` 方法

以 `int.__init__` 为例，位于 `PyGDS.Interpreter.api_int_init`

```gdscript
func api_int_init(args, _kwargs):
    var wrapper = args[0]           # DSLObject 实例
    var raw = DSLInteger.new(0)
    if args.size() >= 2:
        var arg = args[1]
        if arg is DSLInteger:       raw = DSLInteger.new(arg.value)
        elif arg is DSLFloat:       raw = DSLInteger.new(int(arg.value))
        elif arg is DSLString:      raw = DSLInteger.new(int(arg.value))
        elif arg is DSLBool:        raw = DSLInteger.new(1 if arg.value else 0)
    if wrapper.fields != null:
        wrapper._wrapped = raw      # 将底层对象存入 _wrapped
    return DSLNone.new()
```

---

## 隐式继承

### 默认继承 `object`

当用户定义类时，若未指定基类，在 `PyGDS.Interpreter.execute_class` 中会自动设置基类为 `object`

```gdscript
if superclass_obj == null and stmt.name != "object":
    superclass_obj = environment.get_val("object")
```

这样：

```python
class Foo:       # 等价于 class Foo(object):
    pass
```

而 `object` 类自身的基类为 `null`，标志着继承链的终点

### `object` 类的初始化

`object` 类通过 `execute_class` 处理，此时 `superclass_obj == null` 且 `stmt.name == "object"`，因此不会被赋予任何基类

---

## 内置类型类定义

内置类型（`int`、`float`、`str`、`list`、`tuple`、`dict`、`bool`）通过 `PyGDS.Interpreter.register_builtins` 直接创建 `DSLClass` 实例并注册到全局作用域，而非走用户类的 `execute_class` 路径

其 `__new__` 被绑定到 `api_<type>_new`（返回原始 DSLObject），`__init__` 绑定到 `api_<type>_init`（设置 `_wrapped`），最后调用 `_inject_builtin_methods` 注入方法

### `execute_class` 的处理流程

`PyGDS.Interpreter.execute_class` 处理用户定义的类（包括 `object` 自身）

1. **求值基类**：若 `ClassStmt` 有 `superclass` 表达式，求值得到 `DSLClass`；否则默认为 `object`
2. **收集方法和类属性**：
   - `FunctionStmt` → 创建 `DSLFunction`，存入 `methods`
   - `ExpressionStmt(Assign)`（类级赋值）→ 求值并存入 `class_attrs`
3. **创建 DSLClass**：`DSLClass.new(name, superclass, methods, self)`
4. **注册到环境**：`environment.define(name, class_obj)`，使类名在作用域中可见

### `_inject_builtin_methods` 详情

`PyGDS.Interpreter._inject_builtin_methods` 为内置类型类注入方法描述符

```gdscript
func _inject_builtin_methods(class_obj, cls_name):
    match cls_name:
        "int":
            class_obj.methods["__add__"] = DSLWrappedDescriptor.new("__add__", ...)
            class_obj.methods["__sub__"] = DSLWrappedDescriptor.new("__sub__", ...)
            # ...
        "str":
            class_obj.methods["upper"] = DSLMethodDescriptor.new("upper", ...)
            class_obj.methods["lower"] = DSLMethodDescriptor.new("lower", ...)
            # ...
        "list":
            class_obj.methods["append"] = DSLMethodDescriptor.new("append", ...)
            class_obj.methods["extend"] = DSLMethodDescriptor.new("extend", ...)
            # ...
        "tuple":
            class_obj.methods["count"] = DSLMethodDescriptor.new("count", ...)
            class_obj.methods["index"] = DSLMethodDescriptor.new("index", ...)
            # ...
        "dict":
            class_obj.methods["items"] = DSLMethodDescriptor.new("items", ...)
            class_obj.methods["keys"] = DSLMethodDescriptor.new("keys", ...)
            # ...
```

---

## `@property` 装饰器与 `DSLProperty` 描述符

PyGDS 支持 Python 的 `@property` 装饰器语法，包括 getter、setter 和 deleter。实现为 `DSLProperty` 类，实现了数据描述符协议（`__get__` / `__set__` / `__delete__`）

### DSLProperty 类

位于 `PyGDS.DSLProperty`

```gdscript
class DSLProperty extends DSLObject:
    var prop_name: String       # 属性名
    var fget                     # getter 函数 (DSLFunction)
    var fset                     # setter 函数 (DSLFunction, 可为 null)
    var fdel                     # deleter 函数 (DSLFunction, 可为 null)
    var _cls_interp              # 解释器引用
```

### 描述符协议

`DSLProperty` 实现了数据描述符协议，因此其优先级高于实例字段（`fields`）。在 `_dsl_getattribute` 和 `_dsl_setattr` 中，属性的访问和设置首先经过描述符协议

| 操作 | 协议方法 | 行为 |
| :--- | :--- | :--- |
| 读取 `obj.attr` | `__get__(instance, owner)` | 调用 `fget` 并返回结果 |
| 设置 `obj.attr = v` | `__set__(instance, value)` | 调用 `fset`（无 setter 时抛出 `AttributeError`） |
| 删除 `del obj.attr` | `__delete__(instance)` | 调用 `fdel`（无 deleter 时抛出 `AttributeError`） |

### Parser 处理

Parser 的 `decorated_declaration()` 方法识别三种装饰器语法

| 装饰器语法 | `method_type` | 处理方式 |
| :--- | :--- | :--- |
| `@property` | 3 | 创建 `DSLProperty` 实例，存入 `methods[name]` |
| `@name.setter` | 4 | 在已有 `DSLProperty` 上调用 `.setter(func_obj)` |
| `@name.deleter` | 5 | 在已有 `DSLProperty` 上调用 `.deleter(func_obj)` |

### 使用示例

```python
class Circle:
    def __init__(self, radius):
        self._radius = radius

    @property
    def radius(self):
        """getter — 读取属性时调用"""
        return self._radius

    @radius.setter
    def radius(self, value):
        """setter — 写入属性时调用"""
        if value < 0:
            raise ValueError("radius must be non-negative")
        self._radius = value

    @property
    def area(self):
        """只读属性 — 计算属性, 无 setter"""
        return 3.14159 * self._radius ** 2

c = Circle(5)
print(c.radius)     # 5 — 调用 getter
c.radius = 10       # 调用 setter
print(c.area)       # ~314.159 — 计算属性

# 尝试写入只读属性
ro = Circle(42)
ro.area = 100       # AttributeError: can't set attribute
```

---

## 异常类的 DSLClass 模型

详见 [异常系统 exception_system.md](./exception_system.md)

---

## 内存中的对象关系图

```txt
DSLClass("MyClass", superclass=DSLClass("object"), methods={...})
    │
    │  magic_call(args)
    ▼
DSLObject(klass=MyClass, fields={"val": DSLInteger(42)})
    │
    │  _dsl_getattribute("method")
    ▼
DSLMethod(instance=..., function=DSLFunction(...), interp=...)
    │
    │  magic_call(args)
    ▼
Interpreter.call_user_function(DSLFunction, [self, ...args], kwargs)
```

对于内置类型：

```txt
DSLClass("int", superclass=DSLClass("object"), methods={"__add__": DSLWrappedDescriptor(...), ...})
    │
    │  magic_call([42])
    ▼
DSLObject(klass=int, fields={}, _wrapped=DSLInteger(42))
    │
    │  _dsl_getattribute("__add__")
    ▼  → klass._dsl_getattribute → DSLWrappedDescriptor.__get__(instance, klass)
    │
DSLMethodWrapper(descriptor=..., bound_self=DSLObject(...))
    │
    │  magic_call([right])
    ▼  → descriptor.callback.call([bound_self, right]) → magic_add([42, right])
```

---

## DSLObject 基类接口总览

所有 DSL 类的公共基类 `DSLObject` 定义了以下可重写的接口，每个对标 CPython 的对应魔术方法。

### 三阶命名约定

| 前缀 | 用途 | 示例 |
| :--- | :--- | :--- |
| `_*` | 内部辅助方法 | `_type_name()`, `_dsl_str()`, `_unwrap_dsl()` |
| `_dsl_*` | DSL 内部调度方法（对标 Python 魔术方法） | `_dsl_str()`, `_dsl_bool()`, `_dsl_getattribute()` |
| `magic_*` | DSL 魔术方法（供解释器直接调用） | `magic_call()`, `magic_add()` |
| `builtin_*` | DSL 内置方法（用户代码中可调用） | `builtin_len()`, `builtin_print()` |

### 接口表

| 方法 | 对标 CPython | 说明 |
| :--- | :--- | :--- |
| `_type_name()` | `type(x).__name__` | 返回类型名 |
| `_dsl_getattribute(name)` | `__getattribute__` | 属性访问 |
| `_dsl_setattr(name, value)` | `__setattr__` | 属性赋值 |
| `_dsl_getitem(index)` | `__getitem__` | 索引访问 |
| `_dsl_setitem(index, value)` | `__setitem__` | 索引赋值 |
| `_dsl_add(other)` | `__add__` | 加法 |
| `_dsl_sub(other)` | `__sub__` | 减法 |
| `_dsl_mul(other)` | `__mul__` | 乘法 |
| `_dsl_pow(other)` | `__pow__` | 幂运算 |
| `_dsl_div(other)` | `__truediv__` | 除法 |
| `_dsl_floordiv(other)` | `__floordiv__` | 整除 |
| `_dsl_mod(other)` | `__mod__` | 取模 |
| `_dsl_lt(other)` | `__lt__` | 小于 |
| `_dsl_gt(other)` | `__gt__` | 大于 |
| `_dsl_le(other)` | `__le__` | 小于等于 |
| `_dsl_ge(other)` | `__ge__` | 大于等于 |
| `_dsl_eq(other)` | `__eq__` | 相等 |
| `_dsl_ne(other)` | `__ne__` | 不等 |
| `_dsl_bool()` | `__bool__` | 布尔值 |
| `_dsl_iter()` | `__iter__` | 迭代器 |
| `_dsl_str()` | `__str__` | 字符串表示 |
| `magic_call(args, kwargs)` | `__call__` | 可调用 |

每个方法的默认实现要么抛出类型错误（设置了 `last_error`），要么返回合理的默认值。子类通过重写这些方法来实现多态行为。
