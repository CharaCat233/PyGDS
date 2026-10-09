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

`DSLClass` 表示一个 Python 类（对标 CPython 的 `type` 类型），它存储类名、方法字典、基类列表、C3 线性化序列（MRO）和类属性

```gdscript
class DSLClass extends DSLObject:
    var name: String               # 类名 (如 "MyClass", "int", "list")
    var superclass: DSLClass       # 首个基类, 多基类时为 bases[0], 可为 null
    var bases: Array               # 直接基类数组 (DSLClass 对象, 无基类时为空)
    var mro: Array                 # C3 线性化序列 (含自身, 创建时计算并缓存)
    var methods: Dictionary        # 方法名 → DSLFunction / DSLBuiltinFunction / DSLMethodDescriptor / DSLWrappedDescriptor
    var class_attrs: Dictionary    # 类属性 (如 class_var = 100)
    var interp: Interpreter        # 解释器引用
```

### C3 线性化

`_compute_mro()` 实现 C3 线性化：`L[C] = C + merge(L[B1], ..., L[Bn], [B1, ..., Bn])`，每次从各序列头部选取未在任何序列尾部出现的类加入结果，无法选取时报 MRO 冲突。`_recompute_mro()` 在类创建与直接基类变化时调用并缓存结果；单基类的 MRO 退化为沿首个基类的链

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

DSLObject 通过 `fields` 是否为 `null` 来区分角色

- `fields != null`：表示这是一个 **实例**（用户类实例或内置类型包装）
- `fields == null`：表示这是 **值对象**（如 DSLInteger、DSLString 等纯值类型）

### `_wrapped` 字段

`_wrapped` 是一个独立的存储槽，用于在 DSLObject 包装器内部保存底层对象，主要用于以下场景

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
    # 1. 属性描述符 (`__set__`) 与用户数据描述符: 均优先于实例字段
    if klass != null:
        var prop = klass._dsl_getattribute(name)
        if prop != null and not (prop is DSLNone) and prop.has_method("__set__"):
            prop.__set__(self, value)
            return
        if prop != null and prop._is_user_descriptor() and prop.klass._lookup_method("__set__") != null:
            prop._call_user_descriptor_set(self, value)
            return
        # 2. 用户自定义 __setattr__, 调用它
        var method = klass._lookup_method("__setattr__")
        if method != null:
            klass._invoke_func(method, [self, DSLString.new(name), value] as Array[DSLObject], {} as Dictionary)
            return
    # 3. __slots__ 白名单: 仅当 MRO 上所有类都声明 slots 时限制实例写入
    if klass != null:
        var slot_names = _collect_slot_names(klass)
        if slot_names != null and not slot_names.has(name):
            last_error = "AttributeError: '%s' object has no attribute '%s'" % [_type_name(), name]
            return
    # 4. 直接存储在实例的 fields 字典中
    if fields != null:
        fields[name] = value
        return
    last_error = "AttributeError: '%s' object has no attribute '%s'" % [_type_name(), 属性名]
```

**设置优先级：** 属性描述符 (`__set__`) → 用户数据描述符 (`__set__`) → 类 `__setattr__` → `__slots__` 白名单 → 实例 `fields` 字典

**`__slots__` 白名单：** 用户类声明 `__slots__ = ['a', 'b']`（tuple / list / set / 单字符串）时，`_collect_slot_names` 沿 MRO 收集全部声明——**仅当 MRO 上所有类（除 `object`）都声明 `__slots__`** 时才产生白名单，任一类未声明（实例携带 `__dict__`）则返回 null、不限制写入；白名单生效时写入名单外的属性报 `AttributeError: '<class>' object has no attribute '<name>'`，名单内属性仍存进 `fields`（`__slots__` 不影响属性存储，仅做写入白名单校验）

**用户数据描述符：** 用户类自定义数据描述符（含 `__get__` 与 `__set__` 的对象）写入时经 `__set__` 调用（`_call_user_descriptor_set`），优先于实例字段——与 `@property` 数据描述符同级（`@property` 是 `DSLProperty` 内置实现，用户数据描述符是自定义类实例，两者都走描述符协议）

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
func _dsl_getattribute(attr_name: String) -> DSLObject:
    # 1. 类名内省
    if attr_name == "__name__":
        return DSLString.new(name)

    # 2. 沿 MRO 查找方法与类属性
    for k in mro:
        if k.methods.has(attr_name):
            var method = k.methods[attr_name]
            if method is DSLBuiltinFunction:
                return method
            if method.has_method("__get__"):
                return method.__get__(null, self)
            return method
        if k.class_attrs.has(attr_name):
            return k.class_attrs[attr_name]

    # 3. 类对象自带的内省成员 (用户定义的同名成员优先)
    if attr_name == "mro":
        return DSLBuiltinFunction.new("mro", Callable(self, "magic_mro"))
    if attr_name == "__mro__":
        ...

    # 4. 未找到: 记录 AttributeError 并返回 null
    last_error = "AttributeError: type object '%s' has no attribute '%s'" % [name, attr_name]
    return null
```

**查找优先级：** 类名内省 → MRO 逐级（方法字典 → 类属性）→ `mro` / `__mro__` 内省成员 → AttributeError

`_lookup_method` 同样沿 MRO 逐级查找方法字典，供实例方法解析与 `__new__` / `__init__` 定位使用

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
       → 沿 MRO 查找 __new__
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
       → 沿 MRO 查找 __init__
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
        raise_exception("TypeError", "object.__new__(X): X is not a type object (%s)")
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
if base_objs.is_empty() and stmt.name != "object":
    base_objs.append(environment.get_val("object"))
```

这样：

```python
class Foo:       # 等价于 class Foo(object):
    pass
```

而 `object` 类自身没有基类（`bases` 为空、MRO 仅含自身），标志着继承链的终点

### `object` 类的初始化

`object` 类通过 `execute_class` 处理，此时 `base_objs == []` 且 `stmt.name == "object"`，因此不会被赋予任何基类

---

## 内置类型类定义

内置类型（`int`、`float`、`str`、`list`、`tuple`、`dict`、`bool`）通过 `PyGDS.Interpreter.register_builtins` 直接创建 `DSLClass` 实例并注册到全局作用域，而非走用户类的 `execute_class` 路径

其 `__new__` 被绑定到 `api_<type>_new`（返回原始 DSLObject），`__init__` 绑定到 `api_<type>_init`（设置 `_wrapped`），最后调用 `_inject_builtin_methods` 注入方法

### `execute_class` 的处理流程

`PyGDS.Interpreter.execute_class` 处理用户定义的类（包括 `object` 自身）

1. **求值基类列表**：逐个求值 `ClassStmt.bases` 中的表达式并校验为 `DSLClass`；`*iterable` 星参基类（PEP 448 类侧泛化）展开可迭代对象的每个元素各为一个基类（`Value after * must be an iterable, not X`；非类基类走元类候选解析，冲突报 metaclass conflict）；列表为空且类名非 `object` 时默认补 `object`
2. **一致性检查**（先于类体执行）：直接基类重复检查、C3 线性化计算（冲突报 `TypeError`）、实例布局冲突检查
3. **收集方法和类属性**（类体作用域 `class_env` 挂在模块环境之下）：
   - `FunctionStmt` → 创建 `DSLFunction`，存入 `methods`
   - `ExpressionStmt(Assign)`（类级赋值）→ 求值并存入 `class_attrs` 与 `class_env`
   - `GlobalStmt`（类体内 `global` 声明）→ 在 `class_env` 上标记；其后同名赋值经 `set_val` 写入模块全局，不落类属性（`nonlocal` 声明同法绑定外层函数作用域，找不到绑定时报 `no binding for nonlocal 'x' found`）
   - `AnnotatedAssign`（类体注解 `a: int = 1`）→ 注解求值并入类 `__annotations__`；带值时同 Assign 语义创建类属性，裸注解不创建类属性（CPython 语义）
4. **创建 DSLClass**：`DSLClass.new(name, 首个基类, methods, self)` 后写入 `bases` 并重算 MRO
5. **注册到环境**：`environment.define(name, class_obj)`，使类名在作用域中可见

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

Parser 的 `decorated_declaration()` 方法识别内建装饰器语法

| 装饰器语法 | `method_type` | 处理方式 |
| :--- | :--- | :--- |
| `@property` | 3 | 创建 `DSLProperty` 实例，存入 `methods[name]` |
| `@name.setter` | 4 | 在已有 `DSLProperty` 上调用 `.setter(func_obj)` |
| `@name.deleter` | 5 | 在已有 `DSLProperty` 上调用 `.deleter(func_obj)` |

除内建形式外，`decorated_declaration()` 也接受任意表达式作为装饰器（存入节点的 `decorators` 数组），并支持装饰 `class` 定义；内建形式最多出现一次，可与任意装饰器组合

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

## 任意装饰器

### 装饰器解析

`decorated_declaration()` 按源码顺序收集连续的 `@` 行：`@classmethod` / `@staticmethod` / `@property` / `@name.setter` / `@name.deleter` 这些内建形式记入 `method_type`（走既有快速路径），其余表达式存入节点的 `decorators` 数组（`FunctionStmt` 与 `ClassStmt` 均持有该字段）

### 装饰器应用

解释器的 `_apply_decorators()` 在函数 / 类对象创建后执行：先把装饰器表达式按源码顺序全部求值，再从最贴近定义者开始依次调用，最终返回值替换原绑定。应用点如下：

| 位置 | 时机 |
| :--- | :--- |
| 顶层 / 语句位置的 `def` | `DSLFunction` 创建并设置默认值之后 |
| 类体方法 | `methods[name]` 建立之后（property / setter / deleter 场景下装饰的是 `DSLProperty` 对象） |
| `class` 定义 | `DSLClass` 创建并绑定到环境之后 |

装饰器表达式经 `evaluate()` 通道求值，内部的 `time.sleep` 挂起向上返回 `SUSPENDED` 交回语句重放；装饰对象为类体方法时传入的是未绑定的 `DSLFunction`。当装饰器返回包装函数替换原对象时，内建形式改经真实的包装对象承载语义：staticmethod 包装原样返回持有对象，classmethod 包装绑定所属类，property 包装持有装饰后的 getter；包装对象实现 `__get__` 描述符协议与调用转发，`method_type` 快速路径仅在纯单一内建形式时保留

---

## 多继承与 MRO

### 类创建流程

`execute_class` 依次执行：逐个求值基类表达式（非类基类按元类候选解析并转发调用文案；三参 `type` 路径报 `bases must be types`）→ 无基类时默认补 `object` → 直接基类重复检查（`duplicate base class A`）→ 计算并缓存 C3 线性化（无法一致时报 `Cannot create a consistent method resolution order (MRO) for bases A, B`）→ 布局冲突检查（`multiple bases have instance lay-out conflict`，每个直接基类的布局根取其 MRO 上首个内建布局类型，异常类统一视为同一布局）→ 执行类体。`type(name, bases, dict)` 三参形式走同样的检查

### MRO 驱动的查找点

沿单父链遍历的代码已全部迁移为 MRO 迭代，包括：`DSLClass._lookup_method`（方法解析与 `__new__` / `__init__` 定位）、`DSLClass._dsl_getattribute`（类属性访问）、`DSLObject._is_subclass_of_klass`（isinstance / issubclass / 异常匹配 / 类实例化判定的公共底层）、`dir()` 的收集循环、`__match_args__` 与 match-self 判定、异常体系注册表核对（`_is_registered_exception_class`）与 `_inherits_exception`

### DSLSuper 沿 MRO 协作

`DSLSuper` 持有定义方法所在的类与绑定目标（实例或类），查找从定义类在目标 MRO 中的下一项开始；类方法经 super 访问时绑定到目标的类本身（而非查找命中的类），与 CPython 的描述符绑定一致。菱形继承下 `super().__init__()` 逐类恰好执行一次

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
| `_dsl_bool()` | `__bool__` | 布尔值（基类实现会查找用户类的 `__bool__`，未定义时回退 `__len__` != 0，两者都无则默认为真） |
| `_dsl_iter()` | `__iter__` | 迭代器 |
| `_dsl_str()` | `__str__` | 字符串表示 |
| `magic_call(args, kwargs)` | `__call__` | 可调用 |

每个方法的默认实现要么抛出类型错误（设置了 `last_error`），要么返回合理的默认值。子类通过重写这些方法来实现多态行为。
