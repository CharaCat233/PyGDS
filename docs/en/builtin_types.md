# Built-in Types

PyGDS implements a built-in type system highly consistent with Python.

All DSL types inherit from the `DSLObject` base class, simulating Python's magic method protocol through the `magic_*` series of methods.

---

## Type Overview

| DSL Type | Python Equivalent | Mutability | Hashable |
| :--- | :--- | :--- | :--- |
| `DSLInteger` | `int` | Immutable | Yes |
| `DSLFloat` | `float` | Immutable | Yes |
| `DSLBool` | `bool` | Immutable | Yes |
| `DSLNone` | `NoneType` | Immutable | Yes |
| `DSLString` | `str` | Immutable | Yes |
| `DSLList` | `list` | Mutable | No |
| `DSLTuple` | `tuple` | Immutable | Yes |
| `DSLDict` | `dict` | Mutable | No |

---

## DSLInteger — Integer Type

```gdscript
class DSLInteger extends DSLObject:
    # Integer value
    var value: int
```

Has a **type promotion mechanism**.

When `DSLInteger` is operated on with `DSLFloat`, the integer is automatically promoted to float. See the `PyGDS.DSLInteger._promote` method for details.

## DSLFloat — Float Type

```gdscript
class DSLFloat extends DSLObject:
    # Float value
    var value: float
```

Has a **type promotion mechanism**.

When `DSLInteger` is operated on with `DSLFloat`, the integer is automatically promoted to float. See the `PyGDS.DSLFloat._promote` method for details.

## DSLBool — Boolean Type

```gdscript
class DSLBool extends DSLObject:
    # Underlying boolean value
    var value: bool
```

Has a **singleton caching mechanism**.

To improve performance and ensure consistency, the values `True` and `False` are cached as singletons in the `Interpreter`.

```gdscript
# Interpreter static variables
static var _cached_true: DSLBool   # Singleton of DSLBool.new(true)
static var _cached_false: DSLBool  # Singleton of DSLBool.new(false)
```

When the interpreter encounters the literal `True` or `False`, it does not create a new `DSLBool` instance, but instead returns the cached singleton.

## DSLNone — None Type

```gdscript
class DSLNone extends DSLObject:
    pass
```

Has a **singleton caching mechanism**.

To improve performance and ensure consistency, the value `None` is cached as a singleton in the `Interpreter`.

```gdscript
# Interpreter static variable
static var _cached_none: DSLNone   # Singleton of DSLNone.new()
```

When the interpreter encounters the literal `None`, it does not create a new `DSLNone` instance, but instead returns the cached singleton.

## DSLString — String Type

```gdscript
class DSLString extends DSLObject:
    # GDScript native String
    var value: String
```

## DSLList — List Type

```gdscript
class DSLList extends DSLObject:
    # Element array
    var items: Array[DSLObject]
```

Has an **internal unwrapping mechanism**.

When a `DSLList` is wrapped via `DSLObject` (user-defined classes inheriting from `list`), methods need to obtain the underlying raw `DSLList` object through `DSLObject._unwrap_dsl`.

```gdscript
static func _unwrap_dsl(obj: DSLObject) -> DSLObject:
    if obj._wrapped != null:
        return obj._wrapped
    return obj
```

## DSLTuple — Tuple Type

```gdscript
class DSLTuple extends DSLObject:
    # Element array (immutable)
    var items: Array[DSLObject]
```

## DSLDict — Dictionary Type

```gdscript
class DSLDict extends DSLObject:
    # Keys are GDScript Variant (String/int/float/bool)
    var dict: Dictionary[Variant, DSLObject]
```

Has a special **key type restriction mechanism**.

`DSLDict` keys are stored as GDScript native `Variant` types (rather than `DSLObject`) to improve lookup efficiency.

| DSL Type | Corresponding Variant Type |
| :--- | :--- |
| `DSLString` | `String` |
| `DSLInteger` | `int` |
| `DSLFloat` | `float` |
| `DSLBool` | `bool` |

The `PyGDS.DSLDict._key_to_variant` method is responsible for this conversion. If the key type is not in the above list, it returns `null` and sets a `TypeError: unhashable type`.

## Iterator System

PyGDS provides specialized iterator implementations for different collection types.

### DSLListIterator

Used by `DSLList` and `DSLTuple`.

```gdscript
class DSLListIterator extends DSLIterator:
    var items: Array
    var index: int = 0

    func has_next() -> bool:
        return index < items.size()

    func next() -> DSLObject:
        var res = items[index]
        index += 1
        return res
```

### DSLDictKeyIterator

Iterates over dictionary keys, automatically wrapping the internally stored `Variant` keys back into `DSLObject`.

```gdscript
class DSLDictKeyIterator extends DSLIterator:
    var dict: Dictionary
    var keys: Array
    var index: int = 0
```

### DSLStringIterator

Iterates over a string character by character.

## Built-in Type Methods

### str Methods

The Python equivalent signature is given in parentheses for behavioral comparison.

#### `str.upper()` → `str`

```python
# Python: str.upper()
"hello".upper()           # "HELLO"
```

#### `str.lower()` → `str`

```python
# Python: str.lower()
"HELLO".lower()           # "hello"
```

#### `str.strip(chars=None)` → `str`

```python
# Python: str.strip(chars=None)
"  hello  ".strip()       # "hello"
"xxhelloxx".strip("x")    # "hello"
```

#### `str.split(sep=None, maxsplit=-1)` → `list[str]`

```python
# Python: str.split(sep=None, maxsplit=-1)
"a b c".split()           # ["a", "b", "c"]
"a,b,c".split(",")        # ["a", "b", "c"]
"a,b,c".split(",", 1)     # ["a", "b,c"]
```

#### `str.join(iterable)` → `str`

```python
# Python: str.join(iterable)
",".join(["a", "b", "c"]) # "a,b,c"
```

#### `str.replace(old, new)` → `str`

```python
# Python: str.replace(old, new, count=-1)
"hello".replace("l", "x") # "hexxo"
```

> **Note**: The `count` parameter is not currently supported.

#### `str.find(sub)` → `int`

```python
# Python: str.find(sub)
"hello".find("l")         # 2
"hello".find("z")         # -1
```

> **Note**: The `start`/`end` range parameters are not currently supported.

#### `str.startswith(prefix)` → `bool`

```python
# Python: str.startswith(prefix)
"hello".startswith("he")  # True
"hello".startswith("xx")  # False
```

#### `str.endswith(suffix)` → `bool`

```python
# Python: str.endswith(suffix)
"hello".endswith("lo")    # True
```

#### `str.lstrip(chars=None)` → `str`

```python
# Python: str.lstrip(chars=None)
"  hello".lstrip()        # "hello"
"xxhello".lstrip("x")     # "hello"
```

#### `str.rstrip(chars=None)` → `str`

```python
# Python: str.rstrip(chars=None)
"hello  ".rstrip()        # "hello"
```

#### `str.capitalize()` → `str`

```python
# Python: str.capitalize()
"hello world".capitalize() # "Hello world"
```

#### `str.casefold()` → `str`

```python
# Python: str.casefold()
"HELLO".casefold()        # "hello"
```

> **Note**: Currently equivalent to `lower()`. Full Unicode case folding is not implemented.

#### `str.title()` → `str`

```python
# Python: str.title()
"hello world".title()     # "Hello World"
```

#### `str.swapcase()` → `str`

```python
# Python: str.swapcase()
"Hello".swapcase()        # "hELLO"
```

#### `str.count(sub, start=0, end=...)` → `int`

```python
# Python: str.count(sub, start=0, end=len(str))
"hello hello".count("he") # 2
"hello".count("l", 0, 3)  # 1
```

#### `str.isdigit()` → `bool`

```python
# Python: str.isdigit()
"123".isdigit()           # True
"abc".isdigit()           # False
```

#### `str.isalpha()` → `bool`

```python
# Python: str.isalpha()
"abc".isalpha()           # True
"abc123".isalpha()        # False
```

#### `str.isalnum()` → `bool`

```python
# Python: str.isalnum()
"abc123".isalnum()        # True
```

#### `str.isspace()` → `bool`

```python
# Python: str.isspace()
"   ".isspace()           # True
```

#### `str.islower()` → `bool`

```python
# Python: str.islower()
"hello".islower()         # True
```

#### `str.isupper()` → `bool`

```python
# Python: str.isupper()
"HELLO".isupper()         # True
```

#### `str.istitle()` → `bool`

```python
# Python: str.istitle()
"Hello World".istitle()   # True
```

#### `str.center(width, fillchar=' ')` → `str`

```python
# Python: str.center(width, fillchar=' ')
"hi".center(6)            # "  hi  "
"hi".center(6, "-")       # "--hi--"
```

#### `str.ljust(width, fillchar=' ')` → `str`

```python
# Python: str.ljust(width, fillchar=' ')
"hi".ljust(6)             # "hi    "
```

#### `str.rjust(width, fillchar=' ')` → `str`

```python
# Python: str.rjust(width, fillchar=' ')
"hi".rjust(6)             # "    hi"
```

#### `str.zfill(width)` → `str`

```python
# Python: str.zfill(width)
"42".zfill(5)             # "00042"
```

#### `str.rsplit(sep=None, maxsplit=-1)` → `list[str]`

```python
# Python: str.rsplit(sep=None, maxsplit=-1)
"a b c".rsplit()          # ["a", "b", "c"]
"a,b,c".rsplit(",", 1)    # ["a,b", "c"]
```

#### `str.format(*args)` → `str`

```python
# Python: str.format(*args)
"{} {}".format("a", 1)    # "a 1"
"{0} {1}".format("a", 1)  # "a 1"
```

> **Note**: Only positional placeholders `{}` and `{0}` are supported. Keyword arguments and format specifiers are not supported.

---

### list Methods

#### `list.append(x)` → `None`

```python
# Python: list.append(x)
lst = [1, 2]; lst.append(3)  # [1, 2, 3]
```

#### `list.extend(iterable)` → `None`

```python
# Python: list.extend(iterable)
lst = [1, 2]; lst.extend([3, 4])  # [1, 2, 3, 4]
```

#### `list.pop(index=-1)` → `object`

```python
# Python: list.pop(index=-1)
lst = [1, 2, 3]; lst.pop()     # 3, lst → [1, 2]
lst.pop(0)                      # 1, lst → [2]
```

#### `list.remove(x)` → `None`

```python
# Python: list.remove(x)
lst = [1, 2, 3]; lst.remove(2)  # [1, 3]
```

#### `list.insert(index, x)` → `None`

```python
# Python: list.insert(index, x)
lst = [1, 2]; lst.insert(0, 0)  # [0, 1, 2]
```

#### `list.index(x)` → `int`

```python
# Python: list.index(x, start=0, end=len(list))
[1, 2, 3].index(2)              # 1
```

> **Note**: The `start`/`end` range parameters are not currently supported.

#### `list.count(x)` → `int`

```python
# Python: list.count(x)
[1, 2, 2, 3].count(2)           # 2
```

#### `list.sort(*, key=None, reverse=False)` → `None`

```python
# Python: list.sort(*, key=None, reverse=False)
lst = [3, 1, 2]; lst.sort()         # [1, 2, 3]
lst.sort(reverse=True)              # [3, 2, 1]
lst.sort(key=lambda x: -x)          # key function supported
```

#### `list.reverse()` → `None`

```python
# Python: list.reverse()
lst = [1, 2, 3]; lst.reverse()      # [3, 2, 1]
```

#### `list.clear()` → `None`

```python
# Python: list.clear()
lst = [1, 2, 3]; lst.clear()        # []
```

#### `list.copy()` → `list`

```python
# Python: list.copy()
lst = [1, 2, 3]; lst.copy()         # [1, 2, 3] (shallow copy)
```

---

### dict Methods

#### `dict.get(key, default=None)` → `object`

```python
# Python: dict.get(key, default=None)
d = {"a": 1}; d.get("a")            # 1
d.get("b", 0)                       # 0
```

#### `dict.pop(key, default=...)` → `object`

```python
# Python: dict.pop(key, default=...)
d = {"a": 1}; d.pop("a")            # 1, d → {}
d.pop("b", 0)                       # 0
```

#### `dict.update(other, **kwargs)` → `None`

```python
# Python: dict.update(other, **kwargs)
d = {"a": 1}; d.update({"b": 2})    # {"a": 1, "b": 2}
d.update([("c", 3)])                # {"a": 1, "b": 2, "c": 3}
```

#### `dict.clear()` → `None`

```python
# Python: dict.clear()
d = {"a": 1}; d.clear()             # {}
```

#### `dict.copy()` → `dict`

```python
# Python: dict.copy()
d = {"a": 1}; d.copy()              # {"a": 1} (shallow copy)
```

#### `dict.setdefault(key, default=None)` → `object`

```python
# Python: dict.setdefault(key, default=None)
d = {"a": 1}; d.setdefault("b", 0)  # 0, d → {"a": 1, "b": 0}
```

#### `dict.popitem()` → `tuple`

```python
# Python: dict.popitem()
d = {"a": 1, "b": 2}; d.popitem()   # ("b", 2), d → {"a": 1}
```

#### `dict.keys()` → `view`

```python
# Python: dict.keys()
d = {"a": 1, "b": 2}; d.keys()      # dict_keys(["a", "b"])
```

#### `dict.values()` → `view`

```python
# Python: dict.values()
d = {"a": 1, "b": 2}; d.values()    # dict_values([1, 2])
```

#### `dict.items()` → `list[tuple]`

```python
# Python: dict.items()
d = {"a": 1, "b": 2}; d.items()     # [("a", 1), ("b", 2)]
```

---

### tuple Methods

#### `tuple.count(x)` → `int`

```python
# Python: tuple.count(x)
(1, 2, 2, 3).count(2)              # 2
```

#### `tuple.index(x)` → `int`

```python
# Python: tuple.index(x, start=0, end=len(tuple))
(1, 2, 3).index(2)                 # 1
```

> **Note**: The `start`/`end` range parameters are not currently supported.
