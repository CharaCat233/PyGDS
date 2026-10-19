# Built-in Types and Built-in Functions

PyGDS registers several built-in types and built-in functions in the global scope, modeled after the Python 3.x standard library.

## Built-in Types (as Constructors)

The following built-in types are registered via DSLClass, triggering the two-phase `__new__` → `__init__` construction flow when called.

### `str(obj="")`

Corresponds to the Python `str` type constructor, converting an object to its string representation.

- Returns an empty string `""` when called with no arguments.
- Return type: `str` (DSLString)

```python
str()                    # ""
str(42)                  # "42"
str(3.14)                # "3.14"
str(True)                # "True"
```

### `int(obj=0)`

Corresponds to the Python `int` type constructor, converting an object to an integer.

- Returns `0` when called with no arguments.
- Supported inputs: `int`, `float` (truncated), `str` (parsed), `bool`
- Return type: `int` (DSLInteger)

```python
int()                    # 0
int(3.14)                # 3
int("42")                # 42
int(True)                # 1
```

### `float(obj=0.0)`

Corresponds to the Python `float` type constructor, converting an object to a floating-point number.

- Returns `0.0` when called with no arguments.
- Supported inputs: `float`, `int` (promoted), `str` (parsed)
- Return type: `float` (DSLFloat)

```python
float()                  # 0.0
float(42)                # 42.0
float("3.14")            # 3.14
```

### `bool(obj=False)`

Corresponds to the Python `bool` type constructor, converting an object to a boolean value.

- Returns `False` when called with no arguments.
- Return type: `bool` (DSLBool)

```python
bool()                   # False
bool(0)                  # False
bool(1)                  # True
bool("")                 # False
bool("hello")            # True
bool([1, 2])             # True
```

### `list(iterable=[])`

Corresponds to the Python `list` type constructor, constructing a list.

- Returns `[]` when called with no arguments.
- The argument must be an iterable object.
- Return type: `list` (DSLList)

```python
list()                   # []
list("abc")              # ["a", "b", "c"]
list(range(3))           # [0, 1, 2]
```

### `dict(iterable=None, **kwargs)`

Corresponds to the Python `dict` type constructor, supporting the following calling conventions:

1. **Iterator form**: Pass an iterable where each element is a `(key, value)` pair.
2. **Keyword argument form**: Pass keyword arguments, with keys as strings and values as corresponding DSL objects.

- Returns `{}` when called with no arguments.
- Return type: `dict` (DSLDict)

```python
dict()                   # {}
dict([("a", 1), ("b", 2)])    # {"a": 1, "b": 2}
dict(x=10, y=20)         # {"x": 10, "y": 20}
```

### `tuple(iterable=[])`

Corresponds to the Python `tuple` type constructor.

- Returns `()` when called with no arguments.
- Return type: `tuple` (DSLTuple)

### `bytes(obj=0)`

Corresponds to the Python `bytes` type constructor, the way to build byte strings beyond `b"..."` literals.

- `bytes(3)`: three zero bytes.
- `bytes([104, 105])`: an iterable of integers in 0-255 (out-of-range raises `ValueError`).
- `bytes("hi", "utf-8")`: encodes a string into bytes.
- `bytes(b"hi")`: copies an existing bytes.
- Return type: `bytes` (DSLBytes)

---

## Built-in Functions

### `print(*args, sep=" ", end="\n", file=None, flush=False)`

Corresponds to Python `print()`, outputting arguments to the console; with `file=` bound to a file object the output is written to that file instead (text write, accepts objects returned by `open()`), and `flush=` is accepted but is a no-op (output is already flushed).

- `sep`: Separator between objects, defaults to a space `" "`.
- `end`: End string appended after the output, defaults to newline `"\n"`.
- `file`: Output target, defaults to `None` (console); when a file object is given, the text is written through its `write` (CPython semantics).
- `flush`: Whether to force flushing; `True` / `False` accepted (writes are already flushed in the current implementation, so this is a no-op).

```python
print("Hello", "World")              # Hello World
print("Hello", "World", sep=", ")    # Hello, World
print("Hello", end="!")              # Hello!
f = open("out.txt", "w")
print("to file", file=f)             # writes to out.txt (with newline)
f.close()
```

### `len(obj)`

Corresponds to Python `len()`, returning the length of a sequence or collection.

- Supported types: `str`, `list`, `dict`, `tuple`
- Return type: `int` (DSLInteger)

```python
len("hello")             # 5
len([1, 2, 3])           # 3
len({"a": 1, "b": 2})    # 2
```

### `range(stop)` / `range(start, stop)` / `range(start, stop, step)`

Mimics Python `range()`, returning a lazy integer sequence object.

- Return type: `range` (DSLRange), storing only `start` / `stop` / `step` and evaluating on demand (large ranges are not materialised)
- Supports `len` / indexing (including negative) / slicing (returns a new range) / containment / iteration / `reversed()`
- Immutable: item assignment and deletion both raise `TypeError`
- A `step` of 0 raises `ValueError`; non-integer arguments raise `TypeError`

```python
range(5)                 # range(0, 5)
list(range(5))           # [0, 1, 2, 3, 4]
range(0, 10, 2)          # range(0, 10, 2)
range(10)[2:5]           # range(2, 5)
len(range(1000000))      # 1000000 (not materialised)
```

### `type(obj)`

Corresponds to Python `type()`, returning the type object of the given object.

- For built-in value objects, returns the corresponding type class (looked up from the built-in type table).
- For user classes (the class object itself), returns the `type` type class.
- The three-argument form `type(name, bases, dict)` creates a class dynamically.

The `type` name is bound to the type class itself (`print(type)` prints `<class 'type'>`)

```python
type(42)                 # <class 'int'>
type("hello")            # <class 'str'>
class C:
    pass
type(C)                  # <class 'type'>
type(C()).__name__       # "C"
```

### `id(obj)`

Corresponds to Python `id()`, returning the unique integer identifier of an object.

- Each DSLObject instance is assigned a unique `_object_id` upon creation.
- Accepts exactly 1 argument; otherwise raises `TypeError`.
- Return type: `int` (DSLInteger)

```python
id(x)                    # some unique integer
```

### `repr(obj)`

Corresponds to Python `repr()`, returning the "official" string representation of an object.

- Accepts exactly 1 argument.
- Return type: `str` (DSLString)

```python
repr(42)                 # "42"
repr([1, 2, 3])          # "[1, 2, 3]"
```

### `ascii(obj)`

Corresponds to Python `ascii()`; returns the object's `repr` string with non-ASCII characters escaped as `\x` / `\u` / `\U`

```python
ascii("abc")        # "'abc'"
ascii("é")          # "'\xe9'"
ascii("中")         # "'\u4e2d'"
ascii([1, "é"])     # "[1, '\xe9']"
```

### `hash(obj)`

Corresponds to Python `hash()`, returning the hash value of an object.

- Accepts exactly 1 argument.
- Supports user-defined `__hash__` methods.
- Return type: `int` (DSLInteger)

### `round(number, ndigits=0)`

Corresponds to Python `round()`, performing banker's rounding (half to even) on the exact binary value; the direction for mid-point values matches CPython.

```python
round(3.14)              # 3
round(3.14, 1)           # 3.1
round(2.675, 2)          # 2.67 (exact binary value is below the decimal mid-point)
round(2.5)               # 2
round(0.5)               # 0
round(1234, -2)          # 1200
```

### `abs(x)`

Corresponds to Python `abs()`, returning the absolute value of a number.

```python
abs(-42)                 # 42
abs(-3.14)               # 3.14
```

### `min(iterable, key=None, default=...)` / `min(a, b, ...)`

Equivalent to Python `min()`; returns the smallest value. `key` extracts the comparison key, `default` is returned when the iterable is empty

```python
min([3, 1, 4, 1, 5])     # 1
min(3, 1, 4)             # 1
min(["bb", "a"], key=len)  # "a"
min([], default="empty")   # empty
```

### `max(iterable, key=None, default=...)` / `max(a, b, ...)`

Equivalent to Python `max()`; returns the largest value. `key` extracts the comparison key, `default` is returned when the iterable is empty

```python
max([3, 1, 4, 1, 5])     # 5
max(3, 1, 4)             # 4
max(["bb", "a"], key=len)  # "bb"
max([], default=0)         # 0
```

### `sum(iterable, start=0)`

Corresponds to Python `sum()`, summing the elements of an iterable.

```python
sum([1, 2, 3])           # 6
sum([1, 2, 3], 10)       # 16
```

### `pow(base, exp, mod=None)`

Corresponds to Python `pow()`, computing exponentiation, with support for the three-argument modulo form.

```python
pow(2, 3)                # 8
pow(2, 3, 5)             # 3
```

### `divmod(a, b)`

Corresponds to Python `divmod()`, returning a tuple of quotient and remainder.

```python
divmod(10, 3)            # (3, 1)
```

### `sorted(iterable, key=None, reverse=False)`

Corresponds to Python `sorted()`, returning a new sorted list. `key` extracts the sort key, `reverse` switches to descending order

```python
sorted([3, 1, 2])        # [1, 2, 3]
sorted([3, 1, 2], reverse=True)  # [3, 2, 1]
sorted(["bb", "a"], key=len)     # ["a", "bb"]
```

### `reversed(seq)`

Corresponds to Python `reversed()`, returning a reverse iterator.

```python
list(reversed([1, 2, 3]))  # [3, 2, 1]
```

### `enumerate(iterable, start=0)`

Corresponds to Python `enumerate()`, returning a sequence of `(index, value)` pairs.

- Returns a lazy `enumerate` iterator object (matching CPython): one-shot consumption, `iter(e) is e`, empty once exhausted
- Elements are pulled lazily and compose with generators and infinite sequences; the source may suspend mid-consumption

```python
list(enumerate(["a", "b"]))  # [(0, "a"), (1, "b")]
print(type(enumerate([])).__name__)  # enumerate
```

### `iter(iterable)` / `iter(callable, sentinel)`

Corresponds to Python `iter()`, returning an iterator for the object. For `list` / `tuple` / `str` / `range` / `dict` / `set` it returns a true first-class iterator object (with type names `list_iterator` / `tuple_iterator` / `str_ascii_iterator` (pure-ASCII strings) / `str_iterator` / `range_iterator` / `dict_keyiterator` / `dict_valueiterator` / `dict_itemiterator` / `set_iterator`), holding a reference to the original container (a live view: elements appended during iteration are visible), empty on re-iteration after exhaustion, and `iter(it)` returns itself; `iter(generator)` returns the generator itself (it cannot be consumed again once exhausted); adding or removing keys on a dictionary while `iter(d)` is iterating raises `RuntimeError: dictionary changed size during iteration` (replacing the value of an existing key does not). These type names are not built-in names (consistent with CPython; inspect them via `type(x).__name__`)

The two-argument form `iter(callable, sentinel)` calls `callable` with no arguments on each step and stops when the result equals `sentinel` (type name `callable_iterator`); the callable must not initiate a program suspension (such as `time.sleep`)

```python
it = iter([1, 2, 3])
lst = [1, 2]
it2 = iter(lst)
lst.append(3)
print(list(it2))                # [1, 2, 3] (live view)

def g():
    yield 1
it3 = iter(g())
print(list(it3), list(it3))     # [1] [] (a generator cannot be consumed again once exhausted)
```

### `next(iterator[, default])`

Corresponds to Python `next()`; returns the next item of an iterator. When exhausted, returns `default` if supplied, otherwise raises `StopIteration`; a non-iterator argument (no `__next__`) raises `TypeError: '<t>' object is not an iterator`

```python
it = iter([1, 2])
next(it)            # 1
next(it, 99)        # 2
next(it, 99)        # 99 (exhausted, default returned)
```

### `zip(*iterables, strict=False)`

Corresponds to Python `zip()`, iterating over multiple iterables in parallel; with `strict=True`, if one iterable is exhausted while others still have items left, a `ValueError` is raised.

- Returns a lazy `zip` iterator object (matching CPython): one-shot consumption, `iter(z) is z`, empty once exhausted
- Members are pulled lazily and compose with generators and infinite sequences (e.g. `islice(zip(count(), "ab"), 2)`); member consumption may suspend mid-stream
- The `strict` check raises at the first exhausted member with CPython's exact messages (including the plural form `argument 3 is shorter than arguments 1-2` for 3+ arguments)

```python
list(zip([1, 2], ["a", "b"]))  # [(1, "a"), (2, "b")]
try:
    list(zip([1, 2], [3], strict=True))
except ValueError as e:
    print(e)                     # zip() argument 2 is shorter than argument 1
print(type(zip()).__name__)      # zip
```

### `any(iterable)`

Corresponds to Python `any()`, returning `True` if any element is truthy.

```python
any([False, True, False])  # True
any([False, False])        # False
```

### `all(iterable)`

Corresponds to Python `all()`, returning `True` if all elements are truthy.

```python
all([True, True])        # True
all([True, False])       # False
```

### `ord(c)`

Corresponds to Python `ord()`, returning the Unicode code point of a single character.

```python
ord("A")                 # 65
```

### `chr(i)`

Corresponds to Python `chr()`, returning the character for a Unicode code point.

```python
chr(65)                  # "A"
```

### `hex(x)`

Corresponds to Python `hex()`, converting an integer to a hexadecimal string.

```python
hex(255)                 # "0xff"
```

### `oct(x)`

Corresponds to Python `oct()`, converting an integer to an octal string.

```python
oct(8)                   # "0o10"
```

### `bin(x)`

Corresponds to Python `bin()`, converting an integer to a binary string.

```python
bin(3)                   # "0b11"
```

### `format(value, spec="")`

Corresponds to Python `format()`, converting a value to a string according to a format specifier, using the same specifier syntax as f-strings and `str.format`.

```python
format(255, "x")         # "ff"
format(1234567, ",")     # "1,234,567" (thousands separator)
format(3.14, ".1f")      # "3.1"
format(42)               # "42" (no specifier is equivalent to str)
```

### `isinstance(obj, classinfo)`

Corresponds to Python `isinstance()`, checking whether an object is an instance of a specified type or its subclass.

```python
isinstance(42, int)      # True
isinstance(True, int)    # True
```

### `issubclass(cls, classinfo)`

Corresponds to Python `issubclass()`, checking whether a class is a subclass of a specified class.

```python
issubclass(bool, int)    # True
```

### `callable(obj)`

Corresponds to Python `callable()`, checking whether an object is callable.

```python
callable(print)          # True
callable(42)             # False
```

### `input(prompt="")`

Corresponds to Python `input()`, displaying a prompt and reading user input.

```python
name = input("Enter name: ")
```

> [!WARNING]
> This method always raises an `EOFError` exception.

### `getattr(obj, name, default=None)`

Corresponds to Python `getattr()`, getting an attribute of an object

- Returns the attribute value if it exists
- Returns `default` if the attribute is missing and `default` is provided
- Raises `AttributeError` if the attribute is missing and `default` is not provided
- Return type: any DSLObject

```python
class Point:
    def __init__(self):
        self.x = 42

p = Point()
getattr(p, "x")                 # 42
getattr(p, "missing", "N/A")    # "N/A"
getattr(p, "missing")           # AttributeError
getattr([], "append")           # gets a bound method (callable)
```

### `hasattr(obj, name)`

Python `hasattr()`: returns whether the object has the given attribute (`False` when missing; non-`AttributeError` exceptions raised inside `__getattr__` propagate unchanged)

```python
class Point:
    pass

p = Point()
p.x = 1
print(hasattr(p, "x"))          # True
print(hasattr(p, "y"))          # False
print(hasattr(int, "nope"))     # False
```

### `setattr(obj, name, value)`

Corresponds to Python `setattr()`, setting an attribute of an object

```python
class Point:
    pass

p = Point()
setattr(p, "x", 10)
print(p.x)                      # 10
```

### `delattr(obj, name)`

Corresponds to Python `delattr()`, deleting an attribute of an object; raises `AttributeError` if the attribute does not exist

```python
p = Point()
setattr(p, "y", 5)
delattr(p, "y")
getattr(p, "y", "gone")         # "gone"
```

### `dir(obj)`

Corresponds to Python `dir()`, listing the accessible attribute and method names of an object in alphabetical order.

- User class instances: instance attributes + class methods + class attributes (including the inheritance chain).
- Class objects: class methods and class attributes; modules: module members.
- Built-in type instances (such as `[]`, `5`, `{}`): collect method names by type (including implemented magic methods).
- No-arg call: returns user-defined names of the current scope (sorted).

Built-in type instances (such as `[]`) list the type method names; a no-arg call returns user-defined names of the current scope

```python
class C:
    def greet(self):
        return "hi"

dir(C)                   # ["greet", ...] (sorted name list)
```

### `map(func, iterable, ...)`

Corresponds to Python `map()`, applying a function to every element of an iterable

- Supports multiple iterables (elements passed to the function in parallel)
- Returns a lazy `map` iterator object (matching CPython): one-shot consumption, `iter(m) is m`, empty once exhausted; arguments must be iterable at the `map()` call site
- Elements are pulled lazily and compose with generators and infinite sequences (e.g. `islice(map(f, count()), 3)`); consumption can suspend mid-stream

```python
list(map(lambda x: x * 2, [1, 2, 3]))          # [2, 4, 6]
list(map(str, [1, 2, 3]))                      # ["1", "2", "3"]
list(map(lambda a, b: a + b, [1, 2], [10, 20])) # [11, 22]
m = map(str, [1])
print(type(m).__name__)                        # map
print(list(m), list(m))                        # ['1'] [] (one-shot)
```

### `filter(func, iterable)`

Corresponds to Python `filter()`, keeping only the elements that satisfy the condition

- If `func` is `None`, filters by the truthiness of each element
- Returns a lazy `filter` iterator object (matching CPython): one-shot consumption, `iter(f) is f`, empty once exhausted
- The predicate is called lazily and composes with generators and infinite sequences; the predicate body may suspend

```python
list(filter(lambda x: x > 1, [0, 1, 2, 3]))   # [2, 3]
list(filter(None, [0, 1, "", "a", []]))        # [1, "a"]
f = filter(None, [1])
print(type(f).__name__)                        # filter
```

---

### Dynamic Evaluation and Scope Dictionaries

The functions below (`eval` / `exec` / `compile` / `globals` / `locals` / `vars`) follow CPython; deviations are noted inline

#### `eval(source[, globals])`

Evaluates a string as a single expression and returns the result; multiple statements or an assignment raise `SyntaxError` (`invalid syntax (<string>, line 1)`); a `dict` second argument builds an isolated environment for it (deviation: CPython uses a live dict view, PyGDS snapshots and writes back); builtins are visible in that environment

#### `exec(source[, globals])`

Executes a string as a statement set and returns `None`; a `dict` `globals` argument builds an isolated environment and writes top-level bindings back (including keys removed by `del`). Dynamic code cannot suspend at the top level (hitting `time.sleep` etc. raises `RuntimeError: dynamic code top-level cannot be suspended`); functions / generators defined inside `exec` suspend normally when called from the main script

#### `compile(source, filename, mode)`

Returns a code object (`mode` limited to `"exec"` / `"eval"` / `"single"`, anything else raises `ValueError`); the code object carries `co_name` / `co_filename` / `co_firstlineno` metadata and can be passed to `eval` / `exec`; `co_code` bytecode is not implemented (PyGDS holds the AST)

#### `globals()` / `locals()` / `vars(obj)`

- `globals()`: live view of the global environment (dict form; reads and writes take effect immediately, `del` removes names)
- `locals()`: snapshot of local bindings inside a function; equivalent to `globals()` at module level
- `vars(obj)`: the instance dictionary; objects without `__dict__` (e.g. `5`) raise `TypeError: vars() argument must have __dict__ attribute`

```python
eval("1 + 2")                                # 3
exec("y = 7")                                # y bound in the current scope
g = {}
exec("q = 9", g)
print(g["q"])                                # 9 (written back to the globals argument)

eval(compile("3+4", "<s>", "eval"))          # 7
c = compile("1", "<x>", "eval")
print(c.co_name, c.co_filename)              # <module> <x>

globals()["gv"] = 42
print(gv)                                    # 42 (live-view read/write)
```

## Built-in Modules (import)

PyGDS supports `import` / `from-import` statements for built-in modules. Currently provides the built-in modules `math`, `random`, `statistics`, `functools`, `itertools`, `collections`, `string`, `operator`, `time`, `sys`, `contextlib`, `bisect`, `heapq`, `base64`, `json` and `logging` (other engine-related capabilities are better exposed through `register_api()` from the GDScript side).

### import Syntax

```python
import math                       # import the whole module
import math as m                  # alias
from math import sqrt             # import a single member
from math import sqrt as s, pi    # alias and multiple members
from math import *                # import all public members (non-underscore)
```

### `math` Module

| Category | Members |
| :--- | :--- |
| Constants | `pi` `e` `tau` `inf` `nan` |
| Basics | `sqrt` `isqrt` `cbrt` `floor` `ceil` `trunc` `fabs` `fmod` `pow` `remainder` |
| Exponential/log | `exp` `log` `log1p` `expm1` `log2` `log10` |
| Geometry | `dist` |
| Trigonometry | `sin` `cos` `tan` `asin` `acos` `atan` `atan2` `hypot` |
| Angles | `degrees` `radians` |
| Integer | `factorial` `gcd` `comb` `perm` `prod` `lcm` |
| Sign | `copysign` |
| Predicates | `isnan` `isinf` `isfinite` |

```python
import math
math.sqrt(16)        # 4.0
math.floor(3.7)      # 3
math.gcd(12, 18)     # 6
math.factorial(5)    # 120
math.comb(5, 2)      # 10   (combinations)
math.perm(5, 2)      # 20   (permutations)
math.prod([2, 3, 4]) # 24   (product; start is a keyword argument)
math.lcm(4, 6)       # 12   (least common multiple)
math.cbrt(-8)        # -2.0 (cube root, negative inputs supported)
math.remainder(7, 3) # 1.0  (IEEE 754 remainder, quotient rounded to nearest even)
math.remainder(1.5, 1)  # -0.5
math.log1p(0.5)      # 0.4054651081081644 (ln(1+x), accurate for small x)
math.expm1(0.5)      # 0.6487212707001282 (e**x - 1, accurate for small x)
math.dist([1, 2], [4, 6])   # 5.0 (Euclidean distance; lengths must match)
```

> `math.remainder(x, y)` returns `x - n*y` where `n` is `x/y` rounded to the nearest even integer. a zero divisor or an infinite `x` raises `ValueError`.
> `math.gcd()` / `math.lcm()` with no arguments return `0` / `1`; `math.hypot(x)` with a single argument returns `abs(x)`; `math.dist` raises `ValueError` for sequences of unequal length

### `random` Module

| Function | Description |
| :--- | :--- |
| `seed(n)` | Set the random seed (reproducible sequences) |
| `random()` | Float in `[0, 1)` |
| `uniform(a, b)` | Float in `[a, b]` |
| `randint(a, b)` | Integer in `[a, b]` (inclusive) |
| `randrange(start, stop, step)` | Random integer from the range |
| `choice(seq)` | A random element from a sequence |
| `choices(population, weights=None, k=1)` | Sampling with replacement, optionally weighted; returns a list of length k |
| `shuffle(seq)` | Shuffle a list in place |
| `sample(population, k)` | k distinct random elements |
| `gauss(mu=0.0, sigma=1.0)` | Normal-distribution sample (Box-Muller transform) |
| `triangular(low=0.0, high=1.0, mode=None)` | Triangular-distribution sample |
| `randbytes(n)` | Returns n random `bytes` |
| `getrandbits(k)` | Random integer with k random bits |
| `getstate()` / `setstate(state)` | Save and restore the generator's internal state |

```python
import random
random.seed(42)
random.random()        # in [0, 1)
random.choices(["a", "b"], weights=[1, 0], k=3)   # ['a', 'a', 'a'] (zero-weight entries are never drawn)
random.gauss(0, 1)     # a float drawn from N(0, 1)
```

> **Note**: PyGDS's `random` module implements the same MT19937 (Mersenne Twister) as CPython: integer seeds follow CPython's `init_by_array` seeding path and the value sequence matches CPython (guarded by the `random_mt` case); string seeds are expanded through PyGDS's own hash and their sequence differs from CPython (a documented difference). `seed()` guarantees reproducible sequences within PyGDS.
> **Note**: the sampling functions follow CPython. `choice` / `shuffle` take `len(seq)` and index/assign by integer, so a generator raises `TypeError: object of type`generator`has no len()`, a set raises `not subscriptable`, and `shuffle` raises `does not support item assignment` for tuples/strings/`range`; `choice` accepts strings and `range`, and a dict is indexed by key (raising `KeyError` when the key is not in `0..n-1`). `sample` accepts only lists/tuples/strings. The `weights` argument of `choices` only needs to be iterable, so a generator is accepted.
> **`Random` class**: `random.Random(seed)` creates an instance holding its own MT state (`r.random()` / `r.randint()` etc. match the module-level names), which isolates random sequences; two instances with the same seed produce identical sequences

### `statistics` Module

| Function | Description |
| :--- | :--- |
| `mean(data)` | Arithmetic mean |
| `median(data)` | Median (average of the two middle values for even counts) |
| `mode(data)` | Most frequent element (any hashable type) |
| `stdev(data)` | Sample standard deviation (n-1) |
| `pstdev(data)` | Population standard deviation (n) |
| `variance(data)` | Sample variance (n-1) |
| `pvariance(data)` | Population variance (n) |
| `fmean(data)` | Floating-point arithmetic mean (always returns a float) |
| `geometric_mean(data)` | Geometric mean (data must be positive) |
| `harmonic_mean(data)` | Harmonic mean (data must be non-negative) |
| `quantiles(data, n=4)` | Quantile cut points (exclusive method, returns n-1 values; fewer than 2 data points raises `StatisticsError`) |

```python
import statistics
statistics.mean([1, 2, 3, 4])        # 2.5
statistics.median([1, 2, 3, 4])      # 2.5
statistics.mode([1, 2, 2, 3])        # 2
round(statistics.stdev([1, 2, 3]), 6)  # 1.0
statistics.quantiles([1, 2, 3, 4])   # [1.25, 2.5, 3.75] (quartiles)
statistics.quantiles([1, 2, 3, 4], n=2)  # [2.5] (median cut point)
```

> `statistics.StatisticsError` derives from `ValueError` (matching CPython), so it can be caught either as `except statistics.StatisticsError` or as `except ValueError`.

### `functools` Module

| Function | Description |
| :--- | :--- |
| `reduce(func, iterable[, initial])` | Left-to-right accumulation |
| `partial(func, *args, **kwargs)` | Partial function (pre-binds some arguments) |
| `wraps(wrapped)` | Decorator: copies `__name__` / `__doc__` and other metadata from the wrapped function onto the wrapper |
| `lru_cache(maxsize=128, typed=False)` | LRU-caching decorator; the bare `@lru_cache` form uses the default `maxsize=128`; the wrapper exposes `cache_info()` / `cache_clear()` |
| `singledispatch(func)` | Single-dispatch generic function; register implementations with `@f.register(type)`; unmatched calls use the default implementation |
| `cmp_to_key(func)` | Turns an old-style `cmp(a, b)` function into a key factory usable with `key=` |

```python
from functools import reduce, partial, cmp_to_key
reduce(lambda a, b: a + b, [1, 2, 3, 4])   # 10
add5 = partial(lambda a, b: a + b, 5)
add5(3)                                    # 8
sorted([3, 1, 2], key=cmp_to_key(lambda a, b: b - a))   # [3, 2, 1]
```

> `cmp_to_key(func)` returns a key factory; wrapping an element with it makes
> `sorted(key=...)` / `list.sort(key=...)` order by the sign of `func(a, b)`
> (negative sorts first, zero means equal, positive sorts last).
> `partial` objects are introspectable: `.func` (the original function) / `.args` (positional-argument tuple) / `.keywords` (keyword-argument dict)
> `maxsize=None` means an unbounded cache; with `typed=True` arguments of different types are cached separately

### `itertools` Module (Common Subset)

| Function | Description |
| :--- | :--- |
| `chain(*iterables)` | Concatenate multiple iterables |
| `product(*iterables)` | Cartesian product, yields tuples |
| `combinations(iterable, r)` | r-length combinations |
| `permutations(iterable[, r])` | r-length permutations |
| `islice(iterable, start, stop[, step])` | Lazy slice (equivalent to `iterable[start:stop:step]`) |
| `repeat(obj[, times])` | Repeat an object; with `times` returns a list, otherwise an infinite object |
| `cycle(iterable)` | Infinite cycling over a sequence (returns an infinite object) |
| `count(start=0, step=1)` | Infinite counter (returns an infinite object) |
| `zip_longest(*iterables, fillvalue=None)` | Pair by the longest iterable, filling missing slots with `fillvalue` |
| `takewhile(predicate, iterable)` | Take elements while the predicate holds, stop at the first failure |
| `dropwhile(predicate, iterable)` | Drop elements while the predicate holds, then return the rest |
| `accumulate(iterable[, func][, initial])` | Prefix accumulation (addition by default; `func` and `initial` supported) |
| `pairwise(iterable)` | Adjacent pairs; returns n-1 tuples |
| `groupby(iterable, key=None)` | Adjacent grouping; yields `(key, grouper)` pairs where each grouper is a lazy one-shot iterator sharing a cursor with the outer iteration, and a grouper is exhausted as soon as the outer iteration advances |
| `starmap(func, iterable)` | Calls `func` with each row unpacked as arguments; returns a list of results |
| `filterfalse(predicate, iterable)` | Keeps elements for which the predicate is false (`predicate` of `None` keeps falsy elements); returns a lazy iterator |
| `batched(iterable, n)` | Splits into a stream of tuples of length n (lazy); `n < 1` raises `ValueError` |
| `tee(iterable, n=2)` | Derives n independent cursors from one iterable (returns an n-tuple) |
| `chain.from_iterable(iterable)` | Concatenates the sub-iterables inside one iterable |

```python
from itertools import chain, product, combinations, permutations, islice, repeat, cycle, count, zip_longest, takewhile, dropwhile
from itertools import accumulate, pairwise, groupby, starmap
list(chain([1, 2], [3], [4, 5]))       # [1, 2, 3, 4, 5]
list(product([1, 2], [3, 4]))          # [(1, 3), (1, 4), (2, 3), (2, 4)]
list(combinations([1, 2, 3], 2))       # [(1, 2), (1, 3), (2, 3)]
list(permutations([1, 2]))             # [(1, 2), (2, 1)]
list(islice([1, 2, 3, 4, 5], 1, 4))    # [2, 3, 4]
list(repeat(5, 3))                     # [5, 5, 5]
list(islice(cycle([1, 2]), 4))         # [1, 2, 1, 2]
list(islice(count(10, 5), 3))          # [10, 15, 20]
list(zip_longest([1, 2], [3], fillvalue=0))  # [(1, 3), (2, 0)]
list(takewhile(lambda x: x < 4, [1, 2, 5]))  # [1, 2]
list(dropwhile(lambda x: x < 3, [1, 2, 3, 4]))  # [3, 4]
list(accumulate([1, 2, 3, 4]))         # [1, 3, 6, 10]
list(accumulate([1, 2, 3], initial=10))  # [10, 11, 13, 16]
list(pairwise([1, 2, 3]))              # [(1, 2), (2, 3)]
[(k, list(g)) for k, g in groupby([1, 1, 2, 3, 3])]  # [(1, [1, 1]), (2, [2]), (3, [3, 3])]
list(starmap(lambda a, b: a + b, [(1, 2), (3, 4)]))   # [3, 7]
```

> **Note**: these functions return **lazy iterators** (same shape as CPython; `type(...).__name__` is the function name such as `'chain'` / `'product'`, and `iter` consistency holds). They can be consumed by `list()` / `for` / `islice` and advance lazily over infinite sources (`islice(chain(count(), [1, 2]), 5)` works)
> Calls with an empty pool such as `product([])` return an empty iterator (no error); `repeat` with an explicit `times` also returns an iterator (`list(repeat(5, 3))` gives `[5, 5, 5]`)
> `groupby` keeps adjacent-grouping semantics (the same key split by other keys yields several groups); each grouper is a lazy iterator consumed via `list(g)` and can be consumed only once.

### `collections` Module

| Member | Description |
| :--- | :--- |
| `Counter(iterable)` | Element counting; missing keys return 0 (backed by defaultdict(int)) |
| `Counter.most_common(n=None)` | Returns `[(element, count)]` sorted by count descending (ties by insertion order) |
| `defaultdict(default_factory[, init_dict])` | Missing keys automatically call the factory to create a default value |
| `namedtuple(typename, field_names)` | Generates an immutable tuple subclass with named fields; `field_names` is a whitespace/comma-separated string or an iterable of strings; instances support indexing, iteration, unpacking and field-name access, and the class provides `_fields` / `_make(iterable)` / `_replace(**kw)` plus the instance method `_asdict()` |
| `deque(iterable=[], maxlen=None)` | Double-ended queue, bounded deques silently discard from the opposite end on overflow, slicing unsupported |
| `OrderedDict([init_dict])` | Order-preserving dict, repr carries a prefix, comparisons are order-sensitive |

```python
from collections import Counter, defaultdict
Counter("abca")              # Counter({'a': 2, 'b': 1, 'c': 1})
c = Counter("abc"); c["z"]   # 0
c.most_common()              # [('a', 1), ('b', 1), ('c', 1)]
c.most_common(1)             # [('a', 1)]
dd = defaultdict(list); dd["a"].append(1)   # dd["a"] → [1]

Point = namedtuple("Point", "x y")
p = Point(1, 2)
print(p.x, p.y, p[0], len(p))               # 1 2 1 2
print(repr(p))                              # Point(x=1, y=2)
print(list(p), p == (1, 2))                 # [1, 2] True
print(Point._fields)                        # ('x', 'y')
q = Point._make([7, 8])._replace(y=9)
print(q)                                    # Point(x=7, y=9)
print(p._asdict()["x"])                     # 1
```

### `operator` Module

Exposes the built-in operators as ordinary functions, which pairs well with functional tools such as `sorted(key=)` and `map`. Every binary/unary function goes through the same dispatch path as the operator itself, so magic methods such as `__add__` on user classes still apply.

| Category | Members |
| :--- | :--- |
| Arithmetic | `add` `sub` `mul` `truediv` `floordiv` `mod` `pow` `neg` `pos` `abs` |
| Bitwise | `and_` `or_` `xor` `invert` `lshift` `rshift` |
| Comparison | `eq` `ne` `lt` `le` `gt` `ge` `is_` `is_not` |
| Logic | `not_` `truth` |
| Sequence | `concat` `contains` `getitem` `setitem` `delitem` `countOf` `indexOf` `length_hint` |
| Getters | `itemgetter` `attrgetter` |
| Call | `methodcaller(name, *args, **kwargs)` (calls a method on the target object) |
| Matrix multiply | `matmul` |
| Index | `index` (integer-protocol conversion, equivalent to `__index__`) |

```python
import operator
operator.add(1, 2)                  # 3
operator.floordiv(7, 2)             # 3
operator.invert(5)                  # -6
operator.contains([1, 2, 3], 2)     # True (note the order: container first)
operator.getitem([10, 20], 1)       # 20
operator.itemgetter(1)(["a", "b"])  # 'b'
operator.attrgetter("x")(obj)       # obj.x

# with sorted
pairs = [(2, "b"), (1, "a")]
sorted(pairs, key=operator.itemgetter(0))   # [(1, 'a'), (2, 'b')]

operator.methodcaller("upper")("abc")     # 'ABC' (calls the target's method)
operator.methodcaller("pop")([1, 2, 3])  # 3 (the target is not duplicated as a trailing argument)
```

> `itemgetter(k1, k2, ...)` / `attrgetter("a", "b")` return callables: a single argument returns one value, several arguments return a tuple of values; `attrgetter` accepts dotted `a.b` paths.
> `length_hint(obj)` returns 0 when the object has no length information (it never raises).

### `time` Module

Time-related functionality, matching CPython's `time` module. `sleep` is a **cooperative suspension** (the host keeps running while suspended; the game is not blocked).

```python
import time
from time import sleep

# Cooperative sleep: suspends for the given seconds, then resumes automatically.
# The return value is None, matching CPython.
time.sleep(1.5)
time.sleep(0)

# Timestamps and monotonic clocks
time.time()             # current Unix timestamp (seconds, float)
time.time_ns()          # current Unix timestamp (nanoseconds, int)
time.monotonic()        # monotonically increasing clock (seconds, unaffected by system clock changes)
time.monotonic_ns()     # monotonically increasing clock (nanoseconds)
time.perf_counter()     # performance counter (seconds)
time.perf_counter_ns()  # performance counter (nanoseconds)

time.process_time()     # process CPU time (seconds)
```

`time.sleep()` works inside comprehensions, generator expressions and generator function bodies (matching CPython):

```python
import time

[time.sleep(0) for x in range(3)]                       # [None, None, None]
[x for x in [1, 2, 3] if time.sleep(0)]                 # []
list(time.sleep(0) for x in range(2))                   # [None, None]
[v for v in (time.sleep(0) for x in range(2))]          # [None, None]

def counter():
    for i in range(3):
        time.sleep(0)
        yield i
print(list(counter()))                                  # [0, 1, 2]
```

- A non-numeric argument raises `TypeError`; a negative one raises `ValueError` (messages match CPython)
- Supported inside generator function bodies, comprehensions, and nested generators (a generator body iterating another generator), matching CPython

> **Unimplemented members**: `strftime` / `strptime` / `gmtime` / `localtime` / `mktime` / `ctime` / `asctime` are not provided (`from time import strftime` raises `ImportError`)

### `string` Module (String Constants)

| Constant | Value |
| :--- | :--- |
| `ascii_lowercase` | `'abcdefghijklmnopqrstuvwxyz'` |
| `ascii_uppercase` | `'ABCDEFGHIJKLMNOPQRSTUVWXYZ'` |
| `ascii_letters` | `ascii_lowercase + ascii_uppercase` |
| `digits` | `'0123456789'` |
| `hexdigits` | `'0123456789abcdefABCDEF'` |
| `octdigits` | `'01234567'` |
| `punctuation` | ASCII punctuation (32 characters) |
| `whitespace` | `' \t\n\r\v\f'` |
| `capwords(s, sep=None)` | Splits on the separator, capitalizes each word, then rejoins (`sep=None` splits on whitespace and joins with a single space) |
| `printable` | `digits + ascii_letters + punctuation + whitespace` |

```python
import string
string.ascii_letters   # 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
string.digits          # '0123456789'
string.capwords("the quick brown fox")   # 'The Quick Brown Fox'
string.capwords("a_b-c", "-")           # 'A_b-C' (split on '-')
```

### `sys` Module

Interpreter and runtime information

| Member | Description |
| :--- | :--- |
| `version` / `version_info` | Version string and version tuple (CPython 3.12 shape) |
| `maxsize` | Platform integer limit (`2**63 - 1`) |
| `byteorder` | Host byte order (`'little'` / `'big'`) |
| `platform` | Host platform (`win32` / `linux` / `darwin`) |
| `argv` | Command-line argument list (readable and writable from scripts) |
| `executable` | Interpreter executable path |
| `path` | User-module search directory list (initially `[""]`; see [usage.md](usage.md)) |
| `modules` | Live view of the module cache; `del sys.modules["x"]` evicts a module (a later `import` reloads it) |
| `intern(s)` | Interns a string (non-`str` raises `TypeError`) |
| `exc_info()` | Active-exception triple `(type, value, traceback)`; `(None, None, None)` when none is active |
| `exit([code])` | Raises `SystemExit` (uncaught, it enters the error terminal state with the code) |
| `set_int_max_str_digits(n)` / `get_int_max_str_digits()` | Decimal conversion limit (`0` disables it, non-zero must be ≥ 640) |

```python
import sys
sys.maxsize                        # 9223372036854775807
sys.platform                       # 'win32' / 'linux' / 'darwin'
type(sys.modules["sys"]).__name__  # 'module'
del sys.modules["string"]          # evict the cache (a later import reloads it)
sys.intern("a" + "bc")             # 'abc' (interned)
```

> `sys.exit` deviation: uncaught, PyGDS enters the interpreter error terminal state and reports; CPython silently ends the process (`SystemExit` is caught normally and `.args` holds the argument tuple)

### `contextlib` Module

| Member | Description |
| :--- | :--- |
| `contextmanager(func)` | Turns a generator function into a context-manager factory; the yielded value binds to the `as` target, body exceptions are thrown into the generator, suppression exits without an exception; the product is also a `ContextDecorator` |
| `closing(thing)` | Calls `thing.close()` on exit |
| `suppress(*exceptions)` | Suppresses the listed exceptions; others propagate |
| `nullcontext(enter_result=None)` | Empty context manager (`as` target is `enter_result`) |
| `ExitStack()` | Callback stack: `enter_context(cm)` / `callback(fn, *a, **kw)` (returns the callback itself, usable as a decorator) / `push(cm)` / `pop_all()` / `close()`; unwinds in reverse order |

```python
from contextlib import contextmanager, suppress

@contextmanager
def cm(tag):
    print("enter", tag)
    try:
        yield tag
    finally:
        print("exit", tag)

with cm("a") as v:          # enter a / exit a
    print("body", v)

with suppress(ValueError):
    int("x")                 # not raised

@cm("deco")                 # contextmanager product as a decorator (ContextDecorator)
def f():
    return 1
f()                         # enter deco / exit deco
```

> `time.sleep` and the explicit suspension APIs work in every generator stage (before entry / at a yield point / during exit) and replay without duplicating side effects

### `bisect` Module

| Member | Description |
| :--- | :--- |
| `bisect_left(a, x[, lo[, hi]][, key=])` | Insertion point of x in a sorted sequence (equal values take the left boundary) |
| `bisect_right(a, x[, lo[, hi]][, key=])` / `bisect` | Right-side insertion point (`bisect` is the standard alias) |
| `insort_left(a, x[, lo[, hi]][, key=])` | Inserts at the left boundary, in place |
| `insort_right(a, x[, lo[, hi]][, key=])` / `insort` | Inserts at the right boundary (`insort` is the standard alias) |

```python
import bisect
a = [1, 3, 5, 7, 9]
bisect.bisect_left(a, 5)         # 2
bisect.bisect_right(a, 5)        # 3
bisect.bisect_left(a, 5, 0, 3)   # 2 (lo / hi bounds)
b = [1, 3, 5, 7]
bisect.insort_left(b, 5)         # b -> [1, 3, 5, 5, 7]
```

> `key=` applies to list elements only, never to the search value (CPython semantics); incomparable elements propagate `TypeError`; a non-callable `key` or invalid index arguments are validated as in CPython

### `heapq` Module

| Member | Description |
| :--- | :--- |
| `heappush(heap, item)` / `heappop(heap)` | Push / pop the smallest element (maintains a min-heap in place) |
| `heapify(heap)` | Builds a heap in place |
| `heapreplace(heap, item)` | Pops the smallest element and pushes the new one (`IndexError` on an empty heap) |
| `heappushpop(heap, item)` | Pushes and then pops the smallest element |
| `nsmallest(n, iterable[, key=])` / `nlargest(n, iterable[, key=])` | List of the n smallest / n largest elements |
| `merge(*iterables[, key=][, reverse=])` | Multi-way merge (inputs must be sorted), a lazy iterator |

```python
import heapq
h = []
heapq.heappush(h, 3)
heapq.heappush(h, 1)
heapq.heappop(h)                          # 1
heapq.nsmallest(3, [5, 1, 8, 2, 9, 3])    # [1, 2, 3]
list(heapq.merge([1, 3, 5], [2, 4, 6]))   # [1, 2, 3, 4, 5, 6]
```

### `base64` Module

| Member | Description |
| :--- | :--- |
| `b64encode(data[, altchars])` / `b64decode(s[, altchars[, validate]])` | Standard Base64 codec (`altchars` replaces `+/`, e.g. `b"-_"`) |
| `standard_b64encode` / `standard_b64decode` | Standard alphabet |
| `urlsafe_b64encode` / `urlsafe_b64decode` | URL-safe alphabet (`-` `_`) |
| `b16encode(data)` / `b16decode(s)` | Base16 codec |
| `encodebytes(data)` / `decodebytes(s)` | Base64 text form wrapped every 76 characters |

```python
import base64
base64.b64encode(b"hello")        # b'aGVsbG8='
base64.b64decode(b"aGVsbG8=")     # b'hello'
base64.b64encode(b"hi", b"-_")    # custom altchars
base64.b16encode(b"\x01\xab")     # b'01AB'
```

> The encoding side rejects `str` (`TypeError`) while the decoding side accepts ASCII `str`; invalid padding raises `ValueError` with CPython's messages (length mod 4 == 1 versus bad padding are distinguished)

### `json` Module

| Member | Description |
| :--- | :--- |
| `dumps(obj[, indent][, sort_keys][, separators][, ensure_ascii][, allow_nan][, default])` | Serializes to a JSON string |
| `loads(s)` | Deserializes (full parsing: string escapes / numbers / leading-zero validation / nesting) |
| `dump(obj, fp, ...)` / `load(fp)` | File-object forms |
| `JSONDecodeError` | Parse-error exception class (a `ValueError` subclass) |

```python
import json
json.dumps({"a": 1})                          # '{"a": 1}'
json.dumps({"a": 1}, indent=2)                # indented multi-line output
json.dumps({"a": 1}, sort_keys=True, separators=(",", ":"))
json.loads('{"a": [1, 2.5, true, null]}')     # {'a': [1, 2.5, True, None]}
json.dumps(10**40)                            # big integers printed exactly (arbitrary precision)
```

> `ensure_ascii=False` emits raw non-ASCII characters (the default escapes them as `\uXXXX`); `sort_keys` orders keys; `separators=(item_sep, key_sep)` customizes separators; `allow_nan=False` raises `ValueError` for `nan` / `inf`; non-string keys are escaped as JSON literals (`{1: 2}` becomes `{"1": 2}`, bool keys become `true` / `false`); unserializable objects raise `TypeError` (a `default=` hook can convert them)

### `logging` Module (Log Output)

| Function | Level |
| :--- | :--- |
| `info(msg)` | INFO |
| `warning(msg)` | WARN |
| `warn(msg)` | WARN (an alias of `warning`; both are equivalent) |
| `error(msg)` | ERROR |

Log output is written to `console_output` and filtered by the host log level (`set_log_level`); all return `None`.

```python
import logging

logging.info("Application started successfully")
logging.warn("Configuration item missing, using default")
logging.warning("Deprecated API, please migrate")
logging.error("Database connection failed")
```

---

## Built-in Type Methods

In addition to global built-in functions, each built-in type (`str`, `list`, `tuple`, `dict`) also provides methods modeled after Python.

See [Built-in Types builtin_types.md](./builtin_types.md) for details.
