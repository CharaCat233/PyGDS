# 方法类型系统 — 对标 CPython

## 概述

PyGDS 的方法类型系统严格对标 CPython 的六种底层函数/方法类型。每种类型在 Python 交互环境中都有不同的 `type()` 输出和不同的行为语义，PyGDS 通过 `_type_name()` 方法返回与 CPython 一致的名称

这六种类型分别定义在 `pygds.gd` 中，外加一种 Property 描述符类型

| PyGDS 类 | CPython 对应 |
| :--- | :--- |
| `PyGDS.DSLFunction` | `PyFunction_Type` |
| `PyGDS.DSLBuiltinFunction` | `PyCFunction_Type` |
| `PyGDS.DSLMethod` | `PyMethod_Type` |
| `PyGDS.DSLMethodDescriptor` | `PyMethodDescr_Type` |
| `PyGDS.DSLWrappedDescriptor` | `PyWrapperDescr_Type` |
| `PyGDS.DSLMethodWrapper` | `PyMethodWrapper_Type` |
| `PyGDS.DSLProperty` | `PyProperty_Type` |

---

## 类型对照表

| PyGDS 类 | `_type_name()` 返回值 | CPython 类型 | 说明 |
| :--- | :--- | :--- | :--- |
| `DSLFunction` | `"function"` | `PyFunction_Type` | 用户定义的普通函数/静态方法 |
| `DSLBuiltinFunction` | `"builtin_function_or_method"` | `PyCFunction_Type` | 内置函数或已绑定的内置方法 |
| `DSLMethod` | `"method"` | `PyMethod_Type` | 用户定义的绑定方法（实例方法、类方法） |
| `DSLMethodDescriptor` | `"method_descriptor"` | `PyMethodDescr_Type` | 类级非魔法内置方法描述符（如 `str.upper`） |
| `DSLWrappedDescriptor` | `"wrapper_descriptor"` | `PyWrapperDescr_Type` | 类级魔法方法描述符（如 `int.__add__`） |
| `DSLMethodWrapper` | `"method-wrapper"` | `PyMethodWrapper_Type` | 实例级魔法方法包装器（如 `(1).__add__`） |
| `DSLProperty` | `"property"` | `PyProperty_Type` | `@property` 装饰器生成的数据描述符 |

---

## 行为对照：与 Python 的访问语义一致

以下展示了 PyGDS 中每种方法类型的访问方式，与 CPython 的行为完全一致

```python
# === DSLBuiltinFunction (有 __self__) ===
"hello".upper           # → builtin_function_or_method
                        #    DSLBuiltinFunction(name="upper", callback=..., __self__=DSLString("hello"))

# === DSLMethodDescriptor (类级访问, 无实例) ===
str.upper               # → method_descriptor
                        #    DSLMethodDescriptor(name="upper", callback=...)

# === DSLWrappedDescriptor (类级魔法方法描述符) ===
int.__add__             # → wrapper_descriptor
                        #    DSLWrappedDescriptor(name="__add__", callback=...)

# === DSLMethodWrapper (实例级的魔法方法包装器) ===
(1).__add__             # → method-wrapper
                        #    DSLMethodWrapper(descriptor=..., bound_self=DSLInteger(1))

# === DSLMethod (用户定义的绑定方法) ===
obj.method              # → method
                        #    DSLMethod(instance=obj, function=DSLFunction(...), interp=...)

# === DSLFunction(类级用户方法 / 静态方法 / 顶层函数) ===
MyClass.method          # → function       [普通方法在类上访问]
MyClass.static_method   # → function       [staticmethod 在类上访问]
obj.static_method       # → function       [staticmethod 在实例上访问, 不绑定]
```

---

## 七种方法类型详解

| 方法类型 | 位于 | 对标 CPython | `_type_name()` 返回值 |
| :--- | :--- | :--- | :--- |
| [DSLFunction](#dslfunction) | `PyGDS.DSLFunction` | `PyFunction_Type` | `"function"` |
| [DSLBuiltinFunction](#dslbuiltinfunction) | `PyGDS.DSLBuiltinFunction` | `PyCFunction_Type` | `"builtin_function_or_method"` |
| [DSLMethod](#dslmethod) | `PyGDS.DSLMethod` | `PyMethod_Type` | `"method"` |
| [DSLMethodDescriptor](#dslmethoddescriptor) | `PyGDS.DSLMethodDescriptor` | `PyMethodDescr_Type` | `"method_descriptor"` |
| [DSLWrappedDescriptor](#dslwrappeddescriptor) | `PyGDS.DSLWrappedDescriptor` | `PyWrapperDescr_Type` | `"wrapper_descriptor"` |
| [DSLMethodWrapper](#dslmethodwrapper) | `PyGDS.DSLMethodWrapper` | `PyMethodWrapper_Type` | `"method-wrapper"` |
| [DSLProperty](#dslproperty) | `PyGDS.DSLProperty` | `PyProperty_Type` | `"property"` |

### DSLFunction

用户通过 `def` 关键字定义的函数，承载函数声明 AST、闭包环境和方法类型标记

```gdscript
class DSLFunction extends DSLObject:
    var declaration: FunctionStmt     # 函数声明的 AST 节点
    var closure: DSLEnvironment       # 闭包环境（捕获的外部变量）
    var method_type: int = 0          # 0=普通方法, 1=classmethod, 2=staticmethod, 3=@property getter, 4=@name.setter, 5=@name.deleter
    var _cls_interp: Interpreter      # 类解释器引用
```

***描述符协议***

这是区分三种方法行为的关键，根据 `method_type` 和 `instance` 的值

```gdscript
func __get__(instance, owner):
    # staticmethod (method_type == 2)
    if method_type == 2:
        return self                      # 始终返回自身, 不绑定

    # classmethod (method_type == 1)
    if method_type == 1:
        return DSLMethod.new(owner, self, _cls_interp)   # 绑定到类

    # 普通方法 (method_type == 0)
    if instance == null:
        return self                      # 类级访问, 返回原始函数
    return DSLMethod.new(instance, self, _cls_interp)    # 实例级访问, 绑定到实例
```

| 场景 | `method_type` | `instance` | 返回值 |
| :--- | :--- | :--- | :--- |
| 函数作为 `staticmethod`，通过类访问 | 2 | null | `self`（DSLFunction） |
| 函数作为 `staticmethod`，通过实例访问 | 2 | obj | `self`（DSLFunction） |
| 函数作为 `classmethod`，通过类访问 | 1 | null | `DSLMethod(owner, self)` |
| 函数作为 `classmethod`，通过实例访问 | 1 | obj | `DSLMethod(owner, self)` |
| 普通函数（类级访问） | 0 | null | `self`（DSLFunction） |
| 普通函数（实例级访问） | 0 | obj | `DSLMethod(instance, self)` |

**调用机制：** `DSLFunction` 自身的 `magic_call()` 是占位方法，返回 `null`，实际调用由 `Interpreter.call_user_function()` 处理

---

### DSLBuiltinFunction

封装一个 GDScript `Callable` 作为内置函数，通过 `__self__` 字段区分是否已绑定

```gdscript
class DSLBuiltinFunction extends DSLObject:
    var name: String                  # 函数名称
    var callback: Callable            # GDScript 回调
    var __self__: DSLObject = null    # 绑定的 self 对象 (null = 未绑定, 非 null = 已绑定)
```

`_dsl_str()` **输出示例**

- 未绑定时：`"<built-in function print>"`
- 已绑定时：`"<built-in method 'append' of 'list' object>"`

```gdscript
func magic_call(args, kwargs):
    if __self__ != null:
        var full_args = [__self__]     # 自动在参数前插入 self
        full_args.append_array(args)
        return _wrap(callback.callv([full_args, kwargs]))
    return _wrap(callback.callv([args, kwargs]))
```

当 `__self__` 非空时（即已被描述符绑定），调用自动将 `__self__` 作为第一个参数插入

---

### DSLMethod

用户定义的绑定方法，当通过实例访问用户定义的函数时，描述符协议返回此类型

```gdscript
class DSLMethod extends DSLObject:
    var instance: DSLObject       # 方法所属的实例
    var function: DSLFunction      # 绑定的函数对象
    var interp: Interpreter        # 解释器引用
```

**`_dsl_str()` 输出示例：** `"<bound method MyClass.foo of <MyClass object>>"`

```gdscript
func magic_call(args, kwargs):
    var new_args = [instance]      # 自动在参数前插入 self (实例)
    new_args.append_array(args)
    return interp.call_user_function(function, new_args, kwargs)
```

调用时自动将绑定实例作为第一个参数传入函数，这正是 Python 中 `self` 参数的来源

---

### DSLMethodDescriptor

类级别的非魔法内置方法描述符，当在**类**上直接访问内置方法时返回（如 `str.upper`、`list.append`）

```gdscript
class DSLMethodDescriptor extends DSLObject:
    var name: String                # 方法名
    var callback: Callable          # GDScript 回调
```

**`_dsl_str()` 输出示例：** `"<method 'upper' of 'str' objects>"`

***描述符协议***

```gdscript
func __get__(instance, owner):
    if instance == null:
        return self                         # 类级访问 → 返回自身 (描述符)
    var bf = DSLBuiltinFunction.new(name, callback)
    bf.__self__ = instance                  # 实例级访问 → 返回绑定的 DSLBuiltinFunction
    return bf
```

这是将 `str.upper`（method_descriptor）转换为 `"hello".upper`（builtin_function_or_method）的机制

```gdscript
func magic_call(args, kwargs):
    return DSLBuiltinFunction._wrap_static(callback.callv([args, kwargs]))
```

---

### DSLWrappedDescriptor

类级别的魔法方法（双下划线方法）描述符，用于 `__add__`、`__str__`、`__eq__` 等特殊方法

```gdscript
class DSLWrappedDescriptor extends DSLObject:
    var name: String                # 方法名（如 "__add__"）
    var callback: Callable          # GDScript 回调
```

**`_dsl_str()` 输出示例：** `"<slot wrapper '__add__' of 'int' objects>"`

***描述符协议***

```gdscript
func __get__(instance, owner):
    if instance == null:
        return self                         # 类级访问 → 返回自身
    return DSLMethodWrapper.new(self, instance)  # 实例级访问 → 返回 method-wrapper
```

这与 `DSLMethodDescriptor` 的关键区别在于：绑定后返回的是 `DSLMethodWrapper` 而非 `DSLBuiltinFunction`，从而在 `_type_name()` 上产生 `"method-wrapper"` 与 `"builtin_function_or_method"` 的区分，完全对标 CPython

```gdscript
func magic_call(args, kwargs):
    return DSLBuiltinFunction._wrap_static(callback.callv([args, kwargs]))
```

---

### DSLMethodWrapper

实例级别的魔法方法包装器，当在 **实例** 上访问魔法方法时返回（如 `(1).__add__`）

```gdscript
class DSLMethodWrapper extends DSLObject:
    var descriptor: DSLWrappedDescriptor   # 所属的描述符
    var bound_self: DSLObject              # 绑定的实例
```

**`_dsl_str()` 输出示例：** `"<method-wrapper '__add__' of int object>"`

```gdscript
func magic_call(args, kwargs):
    var full_args = [bound_self]            # 自动在参数前插入 self
    full_args.append_array(args)
    return DSLBuiltinFunction._wrap_static(descriptor.callback.callv([full_args, kwargs]))
```

---

### DSLProperty

`@property` 装饰器将类方法转换为属性访问，`DSLProperty` 实现了数据描述符协议（`__get__` / `__set__` / `__delete__`），完全对标 Python 的 `property` 类型

```gdscript
class DSLProperty extends DSLObject:
    var prop_name: String       # 属性名
    var fget                     # getter 函数 (DSLFunction)
    var fset                     # setter 函数 (DSLFunction, 可为 null)
    var fdel                     # deleter 函数 (DSLFunction, 可为 null)
    var _cls_interp              # 解释器引用
```

***描述符协议***

```gdscript
# __get__: 读取属性值
func __get__(instance, _owner):
    if instance == null:
        return self                          # 类级访问返回 property 对象本身
    if fget == null:
        return DSLNone.new()
    return _cls_interp.call_user_function(fget, [instance], {})

# __set__: 设置属性值（需要 @name.setter）
func __set__(instance, value):
    if fset == null:
        instance.last_error = "AttributeError: can't set attribute"
        return
    _cls_interp.call_user_function(fset, [instance, value], {})

# __delete__: 删除属性（需要 @name.deleter）
func __delete__(instance):
    if fdel == null:
        instance.last_error = "AttributeError: can't delete attribute"
        return
    _cls_interp.call_user_function(fdel, [instance], {})
```

`Parser` 中 `method_type` 的对应关系

| `method_type` | 装饰器语法 | 含义 |
| :--- | :--- | :--- |
| 3 | `@property` | getter — 创建 DSLProperty 实例 |
| 4 | `@name.setter` | setter — 在已有 DSLProperty 上设置 fset |
| 5 | `@name.deleter` | deleter — 在已有 DSLProperty 上设置 fdel |

**使用示例：**

```python
class Circle:
    def __init__(self, radius):
        self._radius = radius

    @property
    def radius(self):
        return self._radius

    @radius.setter
    def radius(self, value):
        if value < 0:
            raise ValueError("radius must be non-negative")
        self._radius = value

    @property
    def area(self):
        return 3.14159 * self._radius ** 2  # 只读属性 (计算属性)

c = Circle(5)
print(c.radius)    # 5 — 调用 getter
c.radius = 10      # 调用 setter
print(c.area)      # ~314.159 — 计算属性
```

---

## 描述符协议 (`__get__`)

描述符协议是方法类型系统的核心，它实现了 Python 中通过实例访问类方法时自动绑定的机制

### 协议签名

```gdscript
func __get__(instance, owner) -> DSLObject
```

| 参数 | 含义 |
| :--- | :--- |
| `instance` | 访问方法的实例，若为类级访问则为 `null` |
| `owner` | 方法所属的类（`DSLClass`） |

### 各描述符类型的 `__get__` 行为汇总

| 描述符类型 | `instance == null`（类级访问） | `instance != null`（实例级访问） |
| :--- | :--- | :--- |
| `DSLMethodDescriptor` | 返回自身（`method_descriptor`） | 返回 `DSLBuiltinFunction(name, callback, __self__=instance)` |
| `DSLWrappedDescriptor` | 返回自身（`wrapper_descriptor`） | 返回 `DSLMethodWrapper(self, instance)` |
| `DSLFunction`（普通） | 返回自身（`function`） | 返回 `DSLMethod(instance, self)` |
| `DSLFunction`（classmethod） | 返回 `DSLMethod(owner, self)` | 返回 `DSLMethod(owner, self)` |
| `DSLFunction`（staticmethod） | 返回自身（`function`） | 返回自身（`function`） |
| `DSLProperty` | 返回自身（`property`） | 调用 `fget` 并返回其结果 |

---

## 属性查找链路中的方法绑定

### DSLObject 实例的属性查找 (`_dsl_getattribute`)

```txt
DSLObject._dsl_getattribute(name):
    1. fields                    ← 检查实例属性字典
    2. klass._dsl_getattribute(name)  ← 从类中查找方法 (沿 MRO 链)
       → 若找到且有 __get__ 方法 → method.__get__(self, klass)  ← 绑定到实例
       → 否则直接返回方法
    3. 返回 DSLNone
```

### DSLClass 的属性查找 (`_dsl_getattribute`)

```txt
DSLClass._dsl_getattribute(attr_name):
    1. methods[attr_name]        ← 检查方法字典
       → 若有 __get__ 方法 → 调用 __get__(null, self)  ← 类级访问, 不绑定
       → 否则直接返回
    2. class_attrs[attr_name]    ← 检查类属性
    3. superclass._dsl_getattribute(attr_name)  ← 沿继承链查找
    4. 委托给 DSLObject 父类
```

### 可见的绑定位置

所有通过描述符协议进行的绑定都发生在属性查找的时刻，即 `_dsl_getattribute` 调用的地方

- **DSLObject** 实例中的 `_dsl_getattribute` —— 处理实例级方法绑定
- **DSLClass** 中的 `_dsl_getattribute` —— 处理类级方法访问（不绑定）
- **Interpreter** 中的 `_call_magic_or_fallback` —— 在求值表达式时，从 class 的方法字典中查找并绑定魔法方法

---

## 方法调用统一入口 `_invoke_func`

`DSLClass._invoke_func` 是类中方法的统一调用入口

```gdscript
func _invoke_func(func_obj, args_ary, kw_args):
    if func_obj == null:
        return null
    if func_obj is DSLBuiltinFunction:
        return func_obj.magic_call(args_ary, kw_args)   # 内置函数, 直接调用
    if func_obj is DSLFunction:
        return interp.call_user_function(func_obj, args_ary, kw_args)  # 用户函数, 通过解释器调用
    return func_obj.magic_call(args_ary, kw_args)        # 其他(method-wrapper 等), 调用自身 magic_call
```

这个方法被 `DSLClass.magic_call()` 用于 `__new__` 和 `__init__` 的调用，确保不同类型的函数/方法对象都能通过统一入口被调用

---

## 魔法方法注册

### 注册位置

魔法方法在 `PyGDS.Interpreter._inject_builtin_methods` 中注入到内置类

### 注册方式

```gdscript
func _inject_builtin_methods(class_obj, cls_name):
    match cls_name:
        "int":
            class_obj.methods["__add__"] = DSLWrappedDescriptor.new("__add__", Callable(proto, "magic_add"))
            class_obj.methods["__sub__"] = DSLWrappedDescriptor.new("__sub__", Callable(proto, "magic_sub"))
            class_obj.methods["__mul__"] = DSLWrappedDescriptor.new("__mul__", Callable(proto, "magic_mul"))
            # ...
        "str":
            class_obj.methods["upper"] = DSLMethodDescriptor.new("upper", Callable(proto, "builtin_upper"))
            class_obj.methods["lower"] = DSLMethodDescriptor.new("lower", Callable(proto, "builtin_lower"))
            # ...
        "list":
            class_obj.methods["append"] = DSLMethodDescriptor.new("append", Callable(proto, "builtin_append"))
            # ...
        "dict":
            class_obj.methods["items"] = DSLMethodDescriptor.new("items", Callable(proto, "builtin_items"))
            # ...
        "tuple":
            class_obj.methods["count"] = DSLMethodDescriptor.new("count", Callable(proto, "builtin_count"))
            class_obj.methods["index"] = DSLMethodDescriptor.new("index", Callable(proto, "builtin_index"))
```

### 方法类型区分

- **魔法方法**（`__add__`、`__sub__` 等）→ 注册为 `DSLWrappedDescriptor` → 类级访问为 `wrapper_descriptor`，实例级为 `method-wrapper`
- **普通实例方法**（`append`、`upper`、`items` 等）→ 注册为 `DSLMethodDescriptor` → 类级访问为 `method_descriptor`，实例级为 `builtin_function_or_method`

### 运算符评估流程

当解释器求值 `a + b` 这样的二元运算时

1. `evaluate(Binary)` → 根据运算符类型分发
2. 调用 `_call_magic_or_fallback(left, "__add__", [right], fallback)`
3. 若 `left` 是 `DSLObject` 实例 → 在 `left.klass` 的继承链上查找 `__add__`
4. 找到 `DSLWrappedDescriptor` → 调用 `__get__(left, left.klass)` → 返回 `DSLMethodWrapper`
5. 调用 `DSLMethodWrapper.magic_call([right])` → 自动插入 `bound_self` → 实际调用 `magic_add([left, right])`
6. 若未找到魔法方法 → 回退到 `fallback()` → 直接调用 `left._dsl_add(right)`
