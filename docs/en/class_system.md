# Class and Instance System

## Overview

PyGDS's class and instance system strictly aligns with CPython's object model, implementing class inheritance, method lookup, the descriptor protocol, and the `__new__` → `__init__` two-phase construction process.

Built-in type methods are injected via the `_inject_builtin_methods()` method.

| Class | CPython Equivalent |
| :--- | :--- |
| `DSLClass` | `PyType_Type` |
| `DSLObject` | `PyObject` (serves as both base class and instance) |

---

## DSLClass

`DSLClass` represents a Python class (equivalent to CPython's `type` type). It stores the class name, method dictionary, base class reference, and class attributes.

```gdscript
class DSLClass extends DSLObject:
    var name: String               # Class name (e.g. "MyClass", "int", "list")
    var superclass: DSLClass       # Base class, can be null (only object's base class is null)
    var methods: Dictionary        # method name → DSLFunction / DSLBuiltinFunction / DSLMethodDescriptor / DSLWrappedDescriptor
    var class_attrs: Dictionary    # Class attributes (e.g. class_var = 100)
    var interp: Interpreter        # Interpreter reference
```

---

## DSLObject as Instance

DSLObject is not merely a base class; it directly serves as the role of all class instances, bearing instance functionality itself.

```gdscript
class DSLObject:
    var klass: DSLClass            # The class this object belongs to (only has a value when acting as an instance)
    var fields: Dictionary         # Instance attribute dictionary (name → DSLObject), user-defined classes default to {}
    var _wrapped                   # Underlying raw object: exception instances store DSLException, built-in type subclass instances store DSLInteger/DSLFloat etc.
    var interp: Interpreter        # Interpreter reference
```

DSLObject distinguishes between two roles based on whether `fields` is `null`:

- `fields != null`: Indicates this is an **instance** (user class instance or built-in type wrapper)
- `fields == null`: Indicates this is a **value object** (pure value types like DSLInteger, DSLString, etc.)

### The `_wrapped` Field

`_wrapped` is an independent storage slot used to hold the underlying object inside a DSLObject wrapper. It is primarily used in two scenarios:

- **Built-in type subclass instances**: `MyInt(5)` → `DSLObject(klass=MyInt, fields={}, _wrapped=DSLInteger(5))`
- **Exception instances**: `TypeError("msg")` → `DSLObject(klass=TypeError, fields={"args": ...}, _wrapped=DSLException(...))`

It only serves a **storage** role and does not participate in method dispatch. Attribute lookup is always done through `klass` → MRO, ensuring that subclass overrides are not bypassed.

### `_dsl_getattribute(name)` — Attribute Access Chain

This is the complete attribute lookup chain for instances, located in `PyGDS.DSLObject._dsl_getattribute`.

```gdscript
func _dsl_getattribute(name: String) -> DSLObject:
    # 1. First check instance fields
    if fields != null and fields.has(name):
        return fields[name]

    # 2. Look up from the class (along the MRO chain)
    if klass != null:
        var method = klass._dsl_getattribute(name)
        if method != null and not (method is DSLNone) and method.has_method("__get__"):
            return method.__get__(self, klass)  # Descriptor protocol: bind to current instance
        if method != null and not (method is DSLNone):
            return method

    # 3. If __getattr__ exists, call it
    if klass != null:
        var getattr_method = klass._lookup_method("__getattr__")
        if getattr_method != null:
            return klass._invoke_func(getattr_method, [self, DSLString.new(name)] as Array[DSLObject], {} as Dictionary)

    return DSLNone.new()
```

**Lookup priority:** Instance fields → Class descriptor chain (MRO) → `__getattr__` fallback

### `_dsl_setattr(name, value)` — Setting Instance Attributes

Located in `PyGDS.DSLObject._dsl_setattr`.

```gdscript
func _dsl_setattr(name: String, value: DSLObject):
    # 1. If a property descriptor exists, use __set__ to set
    if klass != null:
        var attr = klass._dsl_getattribute(name)
        if attr != null and not (attr is DSLNone) and attr.has_method("__set__"):
            attr.__set__(self, value)
            return

    # 2. If the class defines __setattr__, call it
    if klass != null:
        var setattr_method = klass._lookup_method("__setattr__")
        if setattr_method != null:
            klass._invoke_func(setattr_method, [self, DSLString.new(name), value] as Array[DSLObject], {} as Dictionary)
            return

    # 3. Store directly in the instance's fields dictionary
    if fields != null:
        fields[name] = value
        return
    last_error = "TypeError: '%s' object has no __dict__" % _type_name()
```

**Setting priority:** Property descriptor (`__set__`) → Class `__setattr__` → Instance `fields` dictionary

### `_dsl_str()` — String Representation

Located in `PyGDS.DSLObject._dsl_str`.

```gdscript
func _dsl_str() -> String:
    if _wrapped != null and _wrapped is DSLException:
        return _wrapped._dsl_str()
    if fields != null and klass != null:
        return "<%s object>" % klass.name
    return "<%s object at 0x%x>" % [_type_name(), _object_id]
```

### `_type_name()` — Type Name

Located in `PyGDS.DSLObject._type_name`.

```gdscript
func _type_name() -> String:
    if klass != null:
        return klass.name
    return "object"
```

---

## DSLClass Attribute Lookup

### `DSLClass._dsl_getattribute(name)` — Class Attribute/Method Lookup

Located in `PyGDS.DSLClass._dsl_getattribute`, used to look up attributes on a class (this path is followed when accessing `MyClass.method`).

```gdscript
func _dsl_getattribute(name: String) -> DSLObject:
    # 1. Look up methods
    if methods.has(name):
        var method = methods[name]
        if method is DSLBuiltinFunction:
            return method
        if method.has_method("__get__"):
            return method.__get__(null, self)  # Descriptor protocol: null instance = return the descriptor itself
        return method

    # 2. Look up class attributes
    if class_attrs.has(name):
        return class_attrs[name]

    # 3. Search along the superclass chain
    var super_klass = superclass
    while super_klass != null:
        var result = super_klass._dsl_getattribute(name)
        if result != null and not (result is DSLNone):
            return result
        super_klass = super_klass.superclass

    # 4. Not found, return DSLNone (do not delegate to the DSLObject parent class to avoid infinite recursion)
    return DSLNone.new()
```

**Lookup priority:** Method dictionary → Class attributes → Superclass chain (MRO) → DSLNone

Note: The final step returns `DSLNone.new()` rather than `super._dsl_getattribute(name)`, because the latter would call `klass._dsl_getattribute` again, causing infinite recursion.

---

## Two-Phase Construction Process

The `__new__` → `__init__` two-phase construction process is the core flow for object creation in PyGDS, strictly aligned with CPython.

### Complete Flow

```txt
MyClass(args...)
    ↓
DSLClass.magic_call(args, kwargs)
    ↓
    1. _lookup_method("__new__")
       → Look up __new__ along the inheritance chain
       → Defaults to object.__new__ (api_object_new)
    ↓
    2. _invoke_func(new_func, [class, ...args], kwargs)
       → Invoke __new__
       → Returns a DSLObject with fields={} (no _wrapped)
    ↓
    3. Check: instance._is_subclass_of_klass(self) ?
       → Yes → continue
       → No → return instance directly
    ↓
    4. _lookup_method("__init__")
       → Look up __init__ along the inheritance chain
       → Defaults to object.__init__ (pass) or the type's api_*_init
    ↓
    5. _invoke_func(init_func, [instance, ...args], kwargs)
       → Invoke __init__
       → Initialize instance attributes (fields) or set _wrapped
    ↓
    6. Return instance
```

### `object.__new__` Implementation

Located in `PyGDS.Interpreter.api_object_new`.

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

It simply creates an empty DSLObject instance (`fields = {}`) without performing any attribute initialization.

### `object.__init__` Implementation

Defined in the `object` class as:

```python
class object:
    def __init__(self):
        pass
```

User-defined `__init__` overrides this default implementation.

### Built-in Type `__init__`

The `__init__` methods of built-in types (`int`, `float`, `str`, `list`, `tuple`, `dict`, `bool`) are registered in `PyGDS.Interpreter.register_builtins`, invoking the corresponding `api_<type>_init` method.

Using `int.__init__` as an example, located in `PyGDS.Interpreter.api_int_init`:

```gdscript
func api_int_init(args, _kwargs):
    var wrapper = args[0]           # DSLObject instance
    var raw = DSLInteger.new(0)
    if args.size() >= 2:
        var arg = args[1]
        if arg is DSLInteger:       raw = DSLInteger.new(arg.value)
        elif arg is DSLFloat:       raw = DSLInteger.new(int(arg.value))
        elif arg is DSLString:      raw = DSLInteger.new(int(arg.value))
        elif arg is DSLBool:        raw = DSLInteger.new(1 if arg.value else 0)
    if wrapper.fields != null:
        wrapper._wrapped = raw      # Store the underlying object in _wrapped
    return DSLNone.new()
```

---

## Implicit Inheritance

### Default Inheritance from `object`

When a user defines a class without specifying a base class, the base class is automatically set to `object` in `PyGDS.Interpreter.execute_class`.

```gdscript
if superclass_obj == null and stmt.name != "object":
    superclass_obj = environment.get_val("object")
```

Thus:

```python
class Foo:       # Equivalent to class Foo(object):
    pass
```

The `object` class itself has a base class of `null`, marking the end of the inheritance chain.

### Initialization of the `object` Class

The `object` class is processed by `execute_class`, at which point `superclass_obj == null` and `stmt.name == "object"`, so it is not given any base class.

---

## Built-in Type Class Definitions

Built-in types (`int`, `float`, `str`, `list`, `tuple`, `dict`, `bool`) are created directly as `DSLClass` instances via `PyGDS.Interpreter.register_builtins` and registered in the global scope, rather than going through the user class `execute_class` path.

Their `__new__` is bound to `api_<type>_new` (returning a raw DSLObject), and `__init__` is bound to `api_<type>_init` (setting `_wrapped`). Finally, `_inject_builtin_methods` is called to inject methods.

### `execute_class` Processing Flow

`PyGDS.Interpreter.execute_class` handles user-defined classes (including `object` itself).

1. **Evaluate base class**: If `ClassStmt` has a `superclass` expression, evaluate it to get a `DSLClass`; otherwise default to `object`.
2. **Collect methods and class attributes**:
   - `FunctionStmt` → Create `DSLFunction`, store in `methods`
   - `ExpressionStmt(Assign)` (class-level assignment) → Evaluate and store in `class_attrs`
3. **Create DSLClass**: `DSLClass.new(name, superclass, methods, self)`
4. **Register in environment**: `environment.define(name, class_obj)`, making the class name visible in the scope.

### `_inject_builtin_methods` Details

`PyGDS.Interpreter._inject_builtin_methods` injects method descriptors for built-in type classes.

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

## `@property` Decorator and `DSLProperty` Descriptor

PyGDS supports Python's `@property` decorator syntax, including getter, setter, and deleter. It is implemented as the `DSLProperty` class, which implements the data descriptor protocol (`__get__` / `__set__` / `__delete__`).

### DSLProperty Class

Located in `PyGDS.DSLProperty`.

```gdscript
class DSLProperty extends DSLObject:
    var prop_name: String       # Property name
    var fget                     # Getter function (DSLFunction)
    var fset                     # Setter function (DSLFunction, can be null)
    var fdel                     # Deleter function (DSLFunction, can be null)
    var _cls_interp              # Interpreter reference
```

### Descriptor Protocol

`DSLProperty` implements the data descriptor protocol, so its priority is higher than instance fields (`fields`). In `_dsl_getattribute` and `_dsl_setattr`, attribute access and assignment first go through the descriptor protocol.

| Operation | Protocol Method | Behavior |
| :--- | :--- | :--- |
| Read `obj.attr` | `__get__(instance, owner)` | Invoke `fget` and return the result |
| Set `obj.attr = v` | `__set__(instance, value)` | Invoke `fset` (raises `AttributeError` if no setter) |
| Delete `del obj.attr` | `__delete__(instance)` | Invoke `fdel` (raises `AttributeError` if no deleter) |

### Parser Handling

The Parser's `decorated_declaration()` method recognizes three decorator syntaxes:

| Decorator Syntax | `method_type` | Handling |
| :--- | :--- | :--- |
| `@property` | 3 | Create a `DSLProperty` instance, store in `methods[name]` |
| `@name.setter` | 4 | Call `.setter(func_obj)` on the existing `DSLProperty` |
| `@name.deleter` | 5 | Call `.deleter(func_obj)` on the existing `DSLProperty` |

### Usage Example

```python
class Circle:
    def __init__(self, radius):
        self._radius = radius

    @property
    def radius(self):
        """getter — called when reading the attribute"""
        return self._radius

    @radius.setter
    def radius(self, value):
        """setter — called when writing the attribute"""
        if value < 0:
            raise ValueError("radius must be non-negative")
        self._radius = value

    @property
    def area(self):
        """read-only property — computed property, no setter"""
        return 3.14159 * self._radius ** 2

c = Circle(5)
print(c.radius)     # 5 — calls getter
c.radius = 10       # calls setter
print(c.area)       # ~314.159 — computed property

# Attempting to write a read-only property
ro = Circle(42)
ro.area = 100       # AttributeError: can't set attribute
```

---

## Exception Class DSLClass Model

See [Exception System exception_system.md](./exception_system.md) for details.

---

## In-Memory Object Relationship Diagram

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

For built-in types:

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

## DSLObject Base Class Interface Overview

The public base class `DSLObject` for all DSL classes defines the following overridable interfaces, each corresponding to CPython's equivalent magic method.

### Three-Tier Naming Convention

| Prefix | Purpose | Example |
| :--- | :--- | :--- |
| `_*` | Internal helper methods | `_type_name()`, `_dsl_str()`, `_unwrap_dsl()` |
| `_dsl_*` | DSL internal dispatch methods (equivalent to Python magic methods) | `_dsl_str()`, `_dsl_bool()`, `_dsl_getattribute()` |
| `magic_*` | DSL magic methods (called directly by the interpreter) | `magic_call()`, `magic_add()` |
| `builtin_*` | DSL built-in methods (callable from user code) | `builtin_len()`, `builtin_print()` |

### Interface Table

| Method | CPython Equivalent | Description |
| :--- | :--- | :--- |
| `_type_name()` | `type(x).__name__` | Returns the type name |
| `_dsl_getattribute(name)` | `__getattribute__` | Attribute access |
| `_dsl_setattr(name, value)` | `__setattr__` | Attribute assignment |
| `_dsl_getitem(index)` | `__getitem__` | Index access |
| `_dsl_setitem(index, value)` | `__setitem__` | Index assignment |
| `_dsl_add(other)` | `__add__` | Addition |
| `_dsl_sub(other)` | `__sub__` | Subtraction |
| `_dsl_mul(other)` | `__mul__` | Multiplication |
| `_dsl_pow(other)` | `__pow__` | Exponentiation |
| `_dsl_div(other)` | `__truediv__` | Division |
| `_dsl_floordiv(other)` | `__floordiv__` | Floor division |
| `_dsl_mod(other)` | `__mod__` | Modulo |
| `_dsl_lt(other)` | `__lt__` | Less than |
| `_dsl_gt(other)` | `__gt__` | Greater than |
| `_dsl_le(other)` | `__le__` | Less than or equal |
| `_dsl_ge(other)` | `__ge__` | Greater than or equal |
| `_dsl_eq(other)` | `__eq__` | Equality |
| `_dsl_ne(other)` | `__ne__` | Inequality |
| `_dsl_bool()` | `__bool__` | Boolean value (the base implementation looks up the user class's `__bool__`, falling back to `__len__ != 0`, and defaults to true when neither exists) |
| `_dsl_iter()` | `__iter__` | Iterator |
| `_dsl_str()` | `__str__` | String representation |
| `magic_call(args, kwargs)` | `__call__` | Callable |

The default implementation of each method either raises a type error (setting `last_error`) or returns a reasonable default value. Subclasses achieve polymorphic behavior by overriding these methods.
