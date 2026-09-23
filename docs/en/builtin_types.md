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
| `DSLSet` | `set` | Mutable | No |
| `DSLFrozenSet` | `frozenset` | Immutable | Yes |
| `DSLGenerator` | `generator` | Mutable | No |
| `DSLFunctionGenerator` | `generator` | Mutable | No |
| `DSLSlice` | `slice` | Immutable | Yes |
| `DSLItemGetter` | `operator.itemgetter` | Immutable | No |
| `DSLAttrGetter` | `operator.attrgetter` | Immutable | No |
| `DSLCmpKey` | `functools.KeyWrapper` | Immutable | No |

---

### DSLInteger — Integer Type

```gdscript
class DSLInteger extends DSLObject:
    # Integer value
    var value: int
```

Has a **type promotion mechanism**.

When `DSLInteger` is operated on with `DSLFloat`, the integer is automatically promoted to float. See the `PyGDS.DSLInteger._promote` method for details.

### DSLFloat — Float Type

```gdscript
class DSLFloat extends DSLObject:
    # Float value
    var value: float
```

Has a **type promotion mechanism**.

When `DSLInteger` is operated on with `DSLFloat`, the integer is automatically promoted to float. See the `PyGDS.DSLFloat._promote` method for details.

### DSLBool — Boolean Type

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

### DSLNone — None Type

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

### DSLString — String Type

```gdscript
class DSLString extends DSLObject:
    # GDScript native String
    var value: String
```

### DSLBytes — Bytes Type

Corresponds to Python `bytes`, created by `b"..."` / `rb"..."` literals (immutable)

```gdscript
class DSLBytes extends DSLObject:
    # byte array (each element 0-255)
    var data: Array[int] = []
```

Indexing and iteration yield integers (`b"xy"[0] == 120`); `len` is the byte count; slicing, `b"a" * 3` repetition and `in` are supported. `repr` looks like `b'xy'`, with non-printable bytes escaped as `\xNN`. Strictly distinct from `str` (`b"a" == "a"` is `False`).

### DSLRange — Lazy Integer Sequence Type

Corresponds to Python `range`, storing only `start` / `stop` / `step` and evaluating on demand (large ranges are not materialised)

```gdscript
class DSLRange extends DSLObject:
    # start value (inclusive)
    var start: int = 0
    # stop value (exclusive)
    var stop: int = 0
    # step (non-zero)
    var step: int = 1
```

Supports `len` / indexing (including negative) / slicing (returns a new range) / containment / iteration / `reversed()`. Immutable: item assignment and deletion both raise `TypeError`.

### DSLList — List Type

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

### DSLTuple — Tuple Type

```gdscript
class DSLTuple extends DSLObject:
    # Element array (immutable)
    var items: Array[DSLObject]
```

### DSLDict — Dictionary Type

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

### DSLSet — Set Type

Corresponds to Python `set`. Elements must be hashable objects (`int`/`float`/`str`/`bool`/`None`/`tuple`), deduplicated by value

```gdscript
class DSLSet extends DSLObject:
    # canonical key -> DSLObject mapping (keys like "i:5" / "s:abc")
    var items: Dictionary
```

#### Literal and Construction

```python
{1, 2, 3}          # set literal (elements without colons)
set()              # empty set
set([1, 1, 2])     # construct from an iterable → {1, 2}
set("abca")        # per character → {'a', 'b', 'c'}
```

> **Note**: `{}` is an empty dict; use `set()` for an empty set.

#### Set Operations

| Operator | Method | Description |
| :--- | :--- | :--- |
| `a \| b` | `a.union(b)` | Union |
| `a & b` | `a.intersection(b)` | Intersection |
| `a - b` | `a.difference(b)` | Difference |
| `a ^ b` | `a.symmetric_difference(b)` | Symmetric difference |
| `a == b` | — | Content equality (order-independent) |
| `a < b` / `a <= b` | `a.issubset(b)` | Proper subset / subset |
| `a > b` / `a >= b` | `a.issuperset(b)` | Proper superset / superset |
| `a.isdisjoint(b)` | — | Whether disjoint |

```python
s = {1, 2, 3}
len(s)              # 3
2 in s              # True
sorted(s)           # [1, 2, 3] (sets are unordered; sort for output)
{1, 2} | {2, 3}     # {1, 2, 3}
isinstance(s, set)  # True
```

#### Hashability Rules

- Hashable: `int`/`float`/`str`/`bool`/`None`/`tuple` (including nested), `frozenset`
- Unhashable: `list`/`dict`/`set` → raising `TypeError: unhashable type` when added

#### Set Comprehensions

```python
{x * x for x in [1, 2, 3, 2]}              # {1, 4, 9} (auto-deduplicated)
{x for x in range(6) if x % 2 == 0}        # {0, 2, 4}
{s.upper() for s in ["a", "b", "a"]}       # {'A', 'B'}
```

### DSLFrozenSet — Immutable Set Type

Corresponds to Python `frozenset`: same content and operations as `set`, but **immutable** (no `add`/`remove`/`discard`/`pop`/`clear`), hence **hashable** — it can be nested in `set` / used as a `dict` key / be an element of another `frozenset`

```gdscript
class DSLFrozenSet extends DSLSet:
    # immutable: inherits set storage, but removes mutating methods
```

#### Construction

```python
frozenset([1, 2, 2, 3])    # frozenset({1, 2, 3}) (auto-deduplicated)
frozenset()                # empty frozenset
frozenset({1, 2, 3})       # construct from a set
frozenset("aabbc")         # frozenset({'a', 'b', 'c'})
```

#### Operations (all return a new frozenset)

```python
a = frozenset([1, 2, 3])
b = frozenset([2, 3, 4])
a | b                # frozenset({1, 2, 3, 4})  union
a & b                # frozenset({2, 3})        intersection
a - b                # frozenset({1})           difference
a ^ b                # frozenset({1, 4})        symmetric difference
```

> **Note**: `frozenset` can be directly compared with `set` (`frozenset([1, 2]) == {1, 2}` is `True`), and can be mixed with `set` in operations; the result is always a `frozenset`.

#### Hashability

```python
s = {frozenset([1, 2]), frozenset([2, 1]), frozenset([1, 2, 3])}
len(s)               # 2 (the first two deduplicate by content)
isinstance(frozenset([1]), frozenset)   # True
isinstance({1}, frozenset)              # False
```

### DSLGenerator — Generator Type

Corresponds to a Python generator (`generator`), created by a generator expression `(expr for var in iterable [if cond])`. It is **lazily evaluated**: elements are produced one at a time on `next()` or iteration, ideal for large or infinite sequences.

```gdscript
class DSLGenerator extends DSLObject:
    # holds the element expression, the loop clause array (Array[CompClause]) and the closure environment
    # a shared DSLGeneratorIterator implements the one-shot iteration semantics
```

```python
g = (x * x for x in range(5))
type(g)                 # <class 'generator'>
next(g)                 # 0 (advance one step)
list(g)                 # [1, 4, 9, 16] (one-shot: 0 already consumed, rest continue)
list(g)                 # [] (exhausted)
sum(x * x for x in range(4))     # 14 (bare form)

list(x * y for x in [1, 2] for y in [10, 20])   # [10, 20, 20, 40] (multiple for clauses)
```

> **Note**: Generators are **one-shot iterators**; iterating again does not restart. `next()` past the end raises `StopIteration` (a default can be given: `next(g, default)`). The consumers `list`/`tuple`/`sum`/`sorted`/`any`/`all`/`enumerate`/`zip`/`min`/`max` all accept generators via `_dsl_iter()`, and `itertools.islice` can lazily consume infinite generators.

### DSLFunctionGenerator — Generator Function Type

Corresponds to a Python generator function (`generator`), created by calling a `def` whose body contains `yield`. Calling it **does not execute the body** and immediately returns a lazy generator object; it holds the function declaration/closure, the parameter-bound local environment, and the interpreter execution stacks saved while suspended (see "Generator Functions and Stack Switching" in `architecture.md`).

```gdscript
class DSLFunctionGenerator extends DSLObject:
    # holds function / local_env / body, plus exec_stack / call_stack / cur_class / cur_self saved while suspended
    # _step() drives the body forward one yield via stack switching; a shared DSLFunctionGeneratorIterator implements one-shot iteration
```

```python
def gen():
    yield 1
    yield 2
type(gen())             # <class 'generator'>
list(gen())             # [1, 2]
next(gen())             # 1 (advance one step)

# expression-level yield: x = yield v injects the send value on resume
def gexpr():
    x = yield 10
    yield x
g = gexpr()
next(g)                 # 10
g.send("hi")            # 'hi' (x is the send value)

# yield from delegates to a sub-iterable
def gsub():
    yield from [1, 2, 3]
list(gsub())            # [1, 2, 3]

# send / throw / close
g.send(value)           # resume, injecting value (send(None) starts the generator)
g.throw(ValueError("e"))  # raise at the suspended yield position
g.close()               # inject GeneratorExit; finally still runs

# return value → StopIteration.value
def gret():
    yield 1
    return 42
it = gret()
next(it)
try:
    next(it)
except StopIteration as e:
    e.value            # 42
```

> **Note**: Generator functions are also **one-shot iterators**; `next()` past the end raises `StopIteration` (carrying the `return` value), `next(g, default)` returns the default, and `for` / `list()` finish normally when exhausted. `time.sleep()` works inside a generator body (cooperative suspension, matching CPython), and likewise inside nested generators — see the `time` module notes. A lambda whose body directly contains `yield` (Python 3.12+) also produces a generator lambda.

#### Loop Clauses (CompClause)

Generator expressions and every kind of comprehension share `CompClause` to describe their loops: each clause carries an array of target variable names, the iterable expression, and an array of `if` conditions. Several clauses nest in the order written (inner clauses may reference outer loop variables).

```gdscript
class CompClause:
    var targets: Array      # loop target names (several for a tuple target like for k, v in ...)
    var iterable: Expr      # iterable expression
    var conditions: Array   # filter condition expressions (zero or more)
```

- **Eager** (`ListComp` / `SetComp` / `DictComp`): `_eval_comp_clauses` walks the clauses recursively and evaluates the element expression for every complete binding combination
- **Lazy** (`DSLGenerator`): `DSLGeneratorIterator` keeps a frame stack holding each clause's iterator and binding snapshot, so each `next()` advances only to the next matching element

### DSLSlice — Slice Type

Corresponds to Python `slice`, describing the interval `start:stop:step`. It can be saved and reused for `lst[slice(...)]` / `"str"[slice(...)]`.

```python
s = slice(1, 4)             # slice(1, 4, None)
s.start / s.stop / s.step   # 1 / 4 / None (unset bounds are None)
isinstance(s, slice)        # True
lst[slice(1, 4)]            # equivalent to lst[1:4]
lst[slice(0, 6, 2)]         # equivalent to lst[0:6:2]
lst[slice(4, 0, -1)]        # negative step reverses

```

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

### DSLGeneratorIterator

Generator-expression iterator: each `next()` lazily advances the comprehension loop once (evaluate source → bind loop variable → test condition → yield an element). A **prefetch buffer** keeps `has_next()` accurate; loop state lives in the iterator fields.

### DSLInfiniteIterator

Infinite Iterators. The `itertools` `repeat`/`cycle`/`count` return infinite objects whose `_dsl_iter()` yields infinite iterators (`DSLRepeatIterator`/`DSLCycleIterator`/`DSLCountIterator`) with `has_next()` always `true`; consume them lazily with `islice`/`takewhile`.

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

#### `str.format(*args, **kwargs)` → `str`

```python
# Python: str.format(*args, **kwargs)
"{} {}".format("a", 1)          # "a 1"
"{0} {1}".format("a", 1)        # "a 1"
"{name}".format(name="Alice")   # "Alice"
```

**Format specifiers**: supports positional/keyword arguments as well as alignment, fill, sign, zero-padding, width, thousands separator, precision and type (same specifier syntax as f-strings)

```python
"{:.2f}".format(3.14159)        # 3.14
"{0:04d}".format(42)            # 0042
"{:x}".format(255)              # ff
"{:>8}".format("hi")            # "      hi"
"{:*^6}".format("ab")           # **ab**
"{:,}".format(12345)            # 12,345
"{0!r:>10}".format("hi")        # "      'hi'"
```

**Conversion flags**: `!r` (repr), `!s` (str), `!a` (ascii); escaped braces `{{` / `}}`

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

### set Methods

#### `set.add(x)` → `None`

```python
# Python: set.add(x)
s = {1, 2}; s.add(3)          # {1, 2, 3}
```

#### `set.remove(x)` → `None`

```python
# Python: set.remove(x)
s = {1, 2, 3}; s.remove(2)    # {1, 3}; raises KeyError if missing
```

#### `set.discard(x)` → `None`

```python
# Python: set.discard(x)
s = {1, 2, 3}; s.discard(9)   # no error if missing
```

#### `set.pop()` → `object`

```python
# Python: set.pop()
s = {1, 2, 3}; s.pop()        # pops an arbitrary element, raises KeyError on empty
```

#### `set.clear()` → `None`

```python
# Python: set.clear()
s = {1, 2}; s.clear()         # set()
```

#### `set.copy()` → `set`

```python
# Python: set.copy()
s = {1, 2}; s.copy()          # {1, 2} (shallow copy)
```

#### `set.union(other)` → `set`

```python
# Python: set.union(other)
{1, 2}.union({2, 3})          # {1, 2, 3} (same as a | b)
```

#### `set.intersection(other)` → `set`

```python
# Python: set.intersection(other)
{1, 2}.intersection({2, 3})   # {2} (same as a & b)
```

#### `set.difference(other)` → `set`

```python
# Python: set.difference(other)
{1, 2, 3}.difference({2})     # {1, 3} (same as a - b)
```

#### `set.symmetric_difference(other)` → `set`

```python
# Python: set.symmetric_difference(other)
{1, 2}.symmetric_difference({2, 3})   # {1, 3} (same as a ^ b)
```

#### `set.isdisjoint(other)` → `bool`

```python
# Python: set.isdisjoint(other)
{1, 2}.isdisjoint({3, 4})     # True
```

#### `set.issubset(other)` → `bool`

```python
# Python: set.issubset(other)
{1, 2}.issubset({1, 2, 3})    # True (same as a <= b)
```

#### `set.issuperset(other)` → `bool`

```python
# Python: set.issuperset(other)
{1, 2, 3}.issuperset({1})     # True (same as a >= b)
```

### frozenset Methods

`frozenset` is read-only; the operation methods all return a new `frozenset` and behave like the corresponding `set` methods (see above):

| Method | Description |
| :--- | :--- |
| `copy()` | Shallow copy |
| `union(other)` | Union (same as `a \| b`) |
| `intersection(other)` | Intersection (same as `a & b`) |
| `difference(other)` | Difference (same as `a - b`) |
| `symmetric_difference(other)` | Symmetric difference (same as `a ^ b`) |
| `isdisjoint(other)` | Whether disjoint |
| `issubset(other)` | Subset (same as `a <= b`) |
| `issuperset(other)` | Superset (same as `a >= b`) |

---
