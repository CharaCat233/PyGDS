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

Corresponds to the Python `dict` type constructor, supporting two calling conventions:

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

---

## Built-in Functions

### `print(*args, sep=" ", end="\n")`

Corresponds to Python `print()`, outputting arguments to the console.

- `sep`: Separator between objects, defaults to a space `" "`.
- `end`: End string appended after the output, defaults to newline `"\n"`.

```python
print("Hello", "World")              # Hello World
print("Hello", "World", sep=", ")    # Hello, World
print("Hello", end="!")              # Hello!
```

### `info(msg)`

Mimics Python `logging.info()`, outputting an INFO-level log message.

```python
info("Application started successfully")
```

### `warn(msg)`

Mimics Python `logging.warn()`, outputting a WARN-level log message.

`warn()` is an alias for `warning()`; both are equivalent.

```python
warn("Configuration item missing, using default")
warning("Deprecated API, please migrate")
```

### `warning(msg)`

Mimics Python `logging.warning()`, outputting a WARN-level log message.

```python
warning("It is recommended to use the new API")
```

### `error(msg)`

Mimics Python `logging.error()`, outputting an ERROR-level log message.

```python
error("Database connection failed")
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

Mimics Python `range()`, generating a sequence of integers (as a list).

- Return type: `list` (DSLList)

```python
range(5)                 # [0, 1, 2, 3, 4]
range(2, 5)              # [2, 3, 4]
range(0, 10, 2)          # [0, 2, 4, 6, 8]
```

### `type(obj)`

Corresponds to Python `type()`, returning the type object of the given object.

- When called with no arguments, returns the string `"<class 'NoneType'>"`.
- For objects that have a klass, returns their associated DSLClass (type object).
- For built-in value objects, attempts to look up the type class from the global scope.

```python
type(42)                 # <class 'int'> (returns DSLClass)
type("hello")            # <class 'str'> (returns DSLClass)
type(type)               # <class 'type'> (returns DSLClass)
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

### `hash(obj)`

Corresponds to Python `hash()`, returning the hash value of an object.

- Accepts exactly 1 argument.
- Supports user-defined `__hash__` methods.
- Return type: `int` (DSLInteger)

### `round(number, ndigits=0)`

Corresponds to Python `round()`, rounding a number to a given precision.

```python
round(3.14)              # 3
round(3.14, 1)           # 3.1
```

### `abs(x)`

Corresponds to Python `abs()`, returning the absolute value of a number.

```python
abs(-42)                 # 42
abs(-3.14)               # 3.14
```

### `min(iterable)` / `min(a, b, ...)`

Corresponds to Python `min()`, returning the minimum value.

```python
min([3, 1, 4, 1, 5])     # 1
min(3, 1, 4)             # 1
```

### `max(iterable)` / `max(a, b, ...)`

Corresponds to Python `max()`, returning the maximum value.

```python
max([3, 1, 4, 1, 5])     # 5
max(3, 1, 4)             # 4
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

### `sorted(iterable, reverse=False)`

Corresponds to Python `sorted()`, returning a new sorted list.

```python
sorted([3, 1, 2])        # [1, 2, 3]
sorted([3, 1, 2], reverse=True)  # [3, 2, 1]
```

### `reversed(seq)`

Corresponds to Python `reversed()`, returning a reverse iterator.

```python
list(reversed([1, 2, 3]))  # [3, 2, 1]
```

### `enumerate(iterable, start=0)`

Corresponds to Python `enumerate()`, returning a sequence of `(index, value)` pairs.

```python
list(enumerate(["a", "b"]))  # [(0, "a"), (1, "b")]
```

### `iter(iterable)`

Corresponds to Python `iter()`, returning an iterator for the object.

```python
it = iter([1, 2, 3])
```

### `zip(*iterables)`

Corresponds to Python `zip()`, iterating over multiple iterables in parallel.

```python
list(zip([1, 2], ["a", "b"]))  # [(1, "a"), (2, "b")]
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

### `sleep(seconds)`

Mimics Python `time.sleep()`, suspends the current DSL script execution for the specified number of seconds, then automatically resumes

- `seconds`: suspension duration (in seconds), must be a non-negative number

```python
sleep(1.5)  # Suspend for 1.5 seconds, then automatically resume
sleep(0.0)  # Resume immediately (no delay)
```

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

### `map(func, iterable, ...)`

Corresponds to Python `map()`, applying a function to every element of an iterable

- Supports multiple iterables (elements passed to the function in parallel)
- **Note**: this implementation eagerly evaluates and returns a list (unlike CPython's lazy map object), but it composes with `list()` / `for` loops etc. in the same way

```python
list(map(lambda x: x * 2, [1, 2, 3]))          # [2, 4, 6]
list(map(str, [1, 2, 3]))                      # ["1", "2", "3"]
list(map(lambda a, b: a + b, [1, 2], [10, 20])) # [11, 22]
```

### `filter(func, iterable)`

Corresponds to Python `filter()`, keeping only the elements that satisfy the condition

- If `func` is `None`, filters by the truthiness of each element
- **Note**: this implementation eagerly evaluates and returns a list

```python
list(filter(lambda x: x > 1, [0, 1, 2, 3]))   # [2, 3]
list(filter(None, [0, 1, "", "a", []]))        # [1, "a"]
```

---

## Built-in Modules (import)

PyGDS supports `import` / `from-import` statements for built-in modules. Currently provides two pure-logic modules, `math` and `random` (engine-related capabilities are better exposed through `register_api()` from the GDScript side).

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
| Constants | `pi` `e` `tau` |
| Basics | `sqrt` `isqrt` `floor` `ceil` `trunc` `fabs` `fmod` `pow` |
| Exponential/log | `exp` `log` `log2` `log10` |
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
```

### `random` Module

| Function | Description |
| :--- | :--- |
| `seed(n)` | Set the random seed (reproducible sequences) |
| `random()` | Float in `[0, 1)` |
| `uniform(a, b)` | Float in `[a, b]` |
| `randint(a, b)` | Integer in `[a, b]` (inclusive) |
| `randrange(start, stop, step)` | Random integer from the range |
| `choice(seq)` | A random element from a sequence |
| `shuffle(seq)` | Shuffle a list in place |
| `sample(population, k)` | k distinct random elements |

```python
import random
random.seed(42)
random.random()        # in [0, 1)
random.randint(1, 6)   # in 1..6
```

> **Note**: PyGDS uses a built-in xorshift32 PRNG, whose value sequence differs from CPython's Mersenne Twister; however `seed()` guarantees reproducible sequences within PyGDS.

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

```python
import statistics
statistics.mean([1, 2, 3, 4])        # 2.5
statistics.median([1, 2, 3, 4])      # 2.5
statistics.mode([1, 2, 2, 3])        # 2
round(statistics.stdev([1, 2, 3]), 6)  # 1.0
```

### `functools` Module

| Function | Description |
| :--- | :--- |
| `reduce(func, iterable[, initial])` | Left-to-right accumulation |
| `partial(func, *args, **kwargs)` | Partial function (pre-binds some arguments) |

```python
from functools import reduce, partial
reduce(lambda a, b: a + b, [1, 2, 3, 4])   # 10
add5 = partial(lambda a, b: a + b, 5)
add5(3)                                    # 8
```

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

```python
from itertools import chain, product, combinations, permutations, islice, repeat, cycle, count, zip_longest, takewhile, dropwhile
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
```

> **Note**: These functions currently return a full `list` (`list(chain(...))` directly gives the result; no extra `list()` wrap is needed). The infinite objects (`repeat`/`cycle`/`count`) must be consumed lazily via `islice`/`takewhile`; do not call `list()` directly on them.

### `collections` Module

| Member | Description |
| :--- | :--- |
| `Counter(iterable)` | Element counting; missing keys return 0 (backed by defaultdict(int)) |
| `Counter.most_common(n=None)` | Returns `[(element, count)]` sorted by count descending (ties by insertion order) |
| `defaultdict(default_factory[, init_dict])` | Missing keys automatically call the factory to create a default value |

```python
from collections import Counter, defaultdict
Counter("abca")              # Counter({'a': 2, 'b': 1, 'c': 1})
c = Counter("abc"); c["z"]   # 0
c.most_common()              # [('a', 1), ('b', 1), ('c', 1)]
c.most_common(1)             # [('a', 1)]
dd = defaultdict(list); dd["a"].append(1)   # dd["a"] → [1]
```

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
| `printable` | `digits + ascii_letters + punctuation + whitespace` |

```python
import string
string.ascii_letters   # 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
string.digits          # '0123456789'
```

---

## Built-in Type Methods

In addition to global built-in functions, each built-in type (`str`, `list`, `tuple`, `dict`) also provides methods modeled after Python.

See [Built-in Types builtin_types.md](./builtin_types.md) for details.
