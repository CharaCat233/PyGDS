# PyGDS Usage Guide

PyGDS is a Python-like scripting interpreter (DSL) embedded in the Godot Engine. It implements a core subset of the Python language, allowing developers to write script logic using Python-style syntax within Godot projects, while seamlessly interacting with Godot's native API.

---

## Quick Start

### Minimal Example

```gdscript
var dsl = PyGDS.new()
dsl.write_dsl_script("""
print("Hello, PyGDS!")
a = 1 + 2
print(a)
""")
dsl.run()
```

**Output:**

```txt
Hello, PyGDS!
3
```

### Workflow

```txt
  PyGDS Instance
      │
      ├── write_dsl_script(source)
      │   ├── Lexer:  Source Code → Token List
      │   ├── Parser: Token List → AST Statement List
      │   └── Stored in self.statements
      │
      └── run()
          ├── Creates an Interpreter instance on first execution (IDLE), reuses it on subsequent resumes
          ├── interpret(statements) — iterates through and executes all AST statements
          ├── Saves the execution stack on suspension, returns the corresponding suspension state
          ├── Collects print_output / console_output
          └── Returns a State enum value reflecting the current state
```

---

## Debug Mode

### Enabling Debug Output

```gdscript
var dsl = PyGDS.new()
dsl.set_debug_mode(true)    # Enable debug mode
```

When debug mode is enabled, `print()` output is displayed directly in the Godot console.

### Disabling Debug Output

```gdscript
dsl.set_debug_mode(false)
```

When debug mode is disabled, output is not printed to the console in real time, but is still accumulated through the `print_output` and `console_output` properties for later reading.

---

## Log Level Control

PyGDS provides built-in logging functions whose output is controlled by log levels.

```gdscript
dsl.set_log_level(PyGDS.ConsoleReport.Level.WARN)
```

### Available Levels

| Level Constant | Description |
| :--- | :--- |
| `ConsoleReport.Level.DEBUG` | Show all logs (most verbose) |
| `ConsoleReport.Level.INFO` | Show info and above |
| `ConsoleReport.Level.WARN` | Show warning and above |
| `ConsoleReport.Level.ERROR` | Show only error and fatal |
| `ConsoleReport.Level.FATAL` | Show only fatal (least verbose) |

### DSL Built-in Logging Functions

```python
info("this is info log")       # Corresponds to ConsoleReport.Level.INFO
warn("this is warning log")    # Corresponds to ConsoleReport.Level.WARN
error("this is error log")     # Corresponds to ConsoleReport.Level.ERROR
```

---

## Getting Output

After executing a DSL script, you can retrieve all output through the following properties:

```gdscript
dsl.run()
print("=== Print Output ===")
print(dsl.print_output)      # Accumulated output of all print() calls

print("=== Console Output ===")
print(dsl.console_output)    # Accumulated output of all logs and errors
```

- `print_output`: Contains only the output from the `print()` function.
- `console_output`: Contains all console output, including logs (`info`/`warn`/`error`), error reports, etc.

---

## Registering External APIs

One of PyGDS's most powerful features is the ability to call Godot native functions from DSL code by registering external functions via `register_api`.

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
        # Call Godot logic here: instantiate scene, create nodes, etc.
        # var enemy = enemy_scene.instantiate()
        # enemy.position = Vector2(x, y)
        # get_tree().current_scene.add_child(enemy)
        return PyGDS.DSLNone.new(),

    "get_health": func(args, kwargs):
        # Can also receive kwargs
        var target = "self"
        if kwargs.has("target"):
            target = kwargs["target"]._dsl_str()
        # Simulate getting health
        return PyGDS.DSLInteger.new(100),
})
```

### API Function Signature

Each registered API function receives two parameters and must return a `DSLObject`.

```gdscript
func my_api(args: Array[DSLObject], kwargs: Dictionary[String, DSLObject]) -> DSLObject:
    # Process arguments...
    return PyGDS.DSLString.new("result")
```

**Naming Convention**: Methods on DSLObject follow a three-tier naming convention:

| Prefix | Tier | Description | Example |
| :--- | :--- | :--- | :--- |
| `_*` | Internal helper methods | Low-level methods called from the GDScript side, not used directly in DSL code | `_dsl_str()` |
| `magic_*` | DSL magic methods | Correspond to Python's dunder methods, used in DSL code | `__init__`, `__str__` |
| `builtin_*` | DSL built-in methods | DSL-level built-in functions, used in DSL code | `print()`, `len()`, `range()` |

### Calling from DSL Scripts

```python
name = get_player_name()
print(name)                         # Alice

spawn_enemy(100, 200)               # Spawn enemy at coordinates (100, 200)
spawn_enemy(300)                    # Spawn at x=300, y=0

hp = get_health(target="enemy")
print(hp)                           # 100
```

### Creating Return Values

All API functions must return a `DSLObject` instance. PyGDS provides the following factory classes:

| Factory | Created Value |
| :--- | :--- |
| `PyGDS.DSLInteger.new(42)` | Integer 42 |
| `PyGDS.DSLFloat.new(3.14)` | Float 3.14 |
| `PyGDS.DSLBool.new(true)` | Boolean True |
| `PyGDS.DSLString.new("hello")` | String "hello" |
| `PyGDS.DSLNone.new()` | None |
| `PyGDS.DSLList.new([...])` | List |
| `PyGDS.DSLTuple.new([...])` | Tuple |
| `PyGDS.DSLDict.new({...})` | Dictionary |

> **Note**: Keys of a `DSLDict` must be GDScript `Variant` types (`String`/`int`/`float`/`bool`), not `DSLObject`.

---

## DSL Syntax Reference

### Variables and Assignment

```python
x = 42
y = 3.14
name = "Alice"
flag = True
nothing = None

# Multi-variable unpacking
a, b, c = [1, 2, 3]
first, *rest = [10, 20, 30, 40]    # first=10, rest=[20, 30, 40]
```

### Number Literals

Hexadecimal, octal, binary, underscore-separated and scientific notation are supported:

```python
0x1F          # 31
0o17          # 15
0b101         # 5
1_000_000     # 1000000
0xFF_FF       # 65535
1_000.5       # 1000.5
1e3           # 1000.0
2.5e-2        # 0.025
```

**Base conversion**: `int(str, base)` parses a string in the given base; `base=0` auto-detects the `0x`/`0o`/`0b` prefix:

```python
int("ff", 16)       # 255
int("101", 2)       # 5
int("0x1f", 0)      # 31 (auto-detects the hex prefix)
int("-ff", 16)      # -255 (signs are supported)
```

### Dictionary Merge and Unpacking (Python 3.9+)

`dict` supports the `|` / `|=` merge operators and `{**a, **b}` literal unpacking; the right side overrides the left on duplicate keys:

```python
d1 = {"a": 1, "b": 2}
d2 = {"b": 3, "c": 4}

d1 | d2              # {'a': 1, 'b': 3, 'c': 4} (returns a new dict, does not modify the operands)
d3 = {"a": 1}
d3 |= d2             # in-place merge, d3 → {'a': 1, 'b': 3, 'c': 4}

{**d1, **d2}         # {'a': 1, 'b': 3, 'c': 4}
{**d1, "z": 9}       # {'a': 1, 'b': 2, 'z': 9} (an explicit key overrides the unpacked value)

dict.fromkeys(["a", "b"], 0)    # {'a': 0, 'b': 0} (builds a dict from an iterable of keys)
```

### Literal `*` Unpacking (Python 3.5+)

Inside list, tuple and set literals, `*iterable` expands the elements of that iterable in place, exactly as if they had been written out one by one:

```python
a = [1, 2, 3]
b = [4, 5]

[*a, 6]              # [1, 2, 3, 6]
[0, *a, *b]          # [0, 1, 2, 3, 4, 5]
[*"ab", "c"]         # ['a', 'b', 'c'] (any iterable)
[*range(3)]          # [0, 1, 2]
[*{"x": 1}]          # ['x'] (dict iteration yields keys)

(*a,)                # (1, 2, 3) (a tuple literal needs the trailing comma)
(0, *a, 6)           # (0, 1, 2, 3, 6)
sorted({*a, 10})     # [1, 2, 3, 10] (set literal; sets are unordered, so inspect with sorted)
```

> A one-element tuple must keep its comma: `(*a,)` is valid while `(*a)` raises `SyntaxError`
> (matching Python); a comprehension element cannot be starred (`[*x for x in it]` fails);
> whatever follows `*` must be iterable, otherwise a `TypeError` is raised.

### Assignment Expressions (walrus, Python 3.8+)

`x := 1` is an **expression**: it assigns to the variable and then yields that value, which makes it handy for assigning and testing in one step:

```python
if (n := 10) > 5:
    print(n)                     # 10
if m := 20:                      # no parentheses needed in a condition
    print(m)                     # 20

while (cur := data[i]) != 0:     # read and test at once
    i += 1

print(x := 7)                    # 7 (as a call argument)
print([(k := 2), k * 3])         # [2, 6]
print({(q := 1): q + 1})         # {1: 2}
print((a := (b := 3)) + a + b)   # 9 (nesting needs parentheses)
```

Inside a comprehension the assignment binds to the **enclosing scope**, exactly as in Python:

```python
vals = [y := v * 2 for v in range(4)]
print(vals)                      # [0, 2, 4, 6]
print(y)                         # 6 (leaks to the enclosing scope, like Python)
print([z for v in range(6) if (z := v * v) > 4])   # [9, 16, 25]
```

> The target must be a plain variable name: `(obj.attr := 1)` and `(lst[0] := 1)` raise `cannot use assignment expressions with attribute` / `with subscript`; a bare `x := 1` statement
> raises `SyntaxError` (write `(x := 1)` instead) and `del (x := 1)` raises `cannot delete named expression` — all matching Python.

### Operators

| Category | Operators |
| :--- | :--- |
| Arithmetic | `+`, `-`, `*`, `/`, `//`, `%`, `**` |
| Comparison | `==`, `!=`, `<`, `>`, `<=`, `>=` |
| Logical | `and`, `or`, `not` |
| Assignment | `=`, `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `**=` |
| Assignment expression | `:=` (walrus) |
| Membership | `in`, `not in` |

The `%` operator performs printf-style formatting on strings:

```python
"%s is %d years old" % ("Alice", 30)   # "Alice is 30 years old"
"%5.2f" % 3.14159                      # " 3.14"
"%x" % 255                             # "ff"
"%05d" % 42                            # "00042"
"%d%%" % 50                            # "50%"
```

Supported conversions: `%s` `%r` `%d` `%i` `%u` `%f` `%F` `%e` `%E` `%g` `%G` `%x` `%X` `%o` `%c` `%%`, plus flags (`-` `+` space `0`), width and precision.

**`str.format`**: supports positional/keyword arguments and format specifiers (alignment, fill, sign, zero padding, width, thousands separator, precision, type)

```python
"{} and {}".format(1, 2)            # "1 and 2"
"{name} = {value:.2f}".format(name="pi", value=3.14159)   # "pi = 3.14"
"{:>8}".format("hi")                # "      hi"
"{0:04d}".format(42)                # "0042"
"{{{}}}".format(5)                  # "{5}"
```

### String Interpolation (f-string)

Supports Python 3.6+ f-string syntax, embedding expressions directly in strings

```python
name = "Alice"
age = 30
print(f"Hello, {name}!")            # Hello, Alice!
print(f"Age: {age}")                # Age: 30
print(f"Sum: {1 + 2}")              # Sum: 3
print(f"Upper: {'hello'.upper()}")  # Upper: HELLO
print(f"literal {{braces}}")        # literal {braces}
```

**Format specifiers**: alignment (`<` `>` `^` `=`), fill character, sign (`+` `-` space), zero padding, width, thousands separator, precision and type (`d` `f` `e` `g` `s` `x` `X` `o` `b` `c` `%`)

```python
print(f"{42:05d}")                  # 00042
print(f"{3.14159:.2f}")             # 3.14
print(f"|{42:>6}|")                 # |    42|
print(f"|{'hi':*^8}|")              # |***hi***|
print(f"{255:x} {5:b} {8:o}")       # ff 101 10
print(f"{1000000:,}")               # 1,000,000
print(f"{0.25:.1%}")                # 25.0%
```

**Conversion flags**: `!s` (str), `!r` (repr), `!a` (ascii)

```python
print(f"{[1, 2, 3]!r}")             # [1, 2, 3]
```

**Nested expressions**: dict/list subscription, function calls, conditional expressions, etc.

```python
d = {"k": "v"}
print(f"d = {d['k']}")              # d = v
lst = [10, 20, 30]
print(f"lst[1] = {lst[1]}")         # lst[1] = 20
```

**`=` debug specifier** (Python 3.8+): prints `expression-source=value`, handy for debugging; defaults to `repr`, and can be combined with conversion flags and format specifiers

```python
x = 42
s = "hi"
print(f"{x=}")              # x=42
print(f"{s=}")              # s='hi'
print(f"{x=:05d}")          # x=00042
print(f"{x + y=}")          # x + y=47
```

**Nested format width/precision**: width and precision can be decided at runtime (`f"{x:{w}d}"`)

```python
w = 8
print(f"{123:0{w}d}")       # 00000123
print(f"{'abc':>{w}}")      #      abc
p = 2
print(f"{3.14159:.{p}f}")   # 3.14
```

### Conditional Statements

```python
if x > 0:
    print("positive")
elif x < 0:
    print("negative")
else:
    print("zero")
```

### Loop Statements

```python
# while loop
i = 0
while i < 5:
    print(i)
    i = i + 1

# for loop (list)
for item in [1, 2, 3]:
    print(item)

# for loop (dictionary keys)
for key in {"a": 1, "b": 2}:
    print(key, d[key])

# for loop (string characters)
for ch in "ABC":
    print(ch)

# range loop
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

### Function Definitions

```python
# Basic function
def greet(name):
    return "Hello, " + name

print(greet("World"))   # Hello, World

# Default parameters
def power(x, n=2):
    return x ** n

print(power(5))         # 25
print(power(5, 3))      # 125

# Positional parameters (before /)
def f(a, b, /, c, d=0):
    print(a, b, c, d)

f(1, 2, 3)              # 1 2 3 0
f(1, 2, c=3)            # 1 2 3 0

# *args variadic parameters
def sum_all(a, b, *args):
    total = a + b
    for x in args:
        total = total + x
    return total

print(sum_all(1, 2, 3, 4, 5))   # 15

# Keyword-only parameters and **kwargs
def config(host, *, port=80, **kwargs):
    print(host, port, kwargs)

config("localhost", port=8080, debug=True, timeout=30)
# localhost 8080 {"debug": True, "timeout": 30}
```

### lambda Anonymous Functions

Supports Python `lambda` expressions; they behave like ordinary functions (callable, usable as `key`/function arguments for `sort`/`map`/`filter`)

```python
# Basic usage
f = lambda x: x * 2
print(f(21))                        # 42

# Immediately invoked
print((lambda x: x + 1)(9))         # 10

# Default parameters
g = lambda a, b=10: a + b
print(g(5))                         # 15
print(g(5, 100))                    # 105

# No arguments
h = lambda: "no args"
print(h())                          # no args

# As sort / sorted key
lst = [3, 1, 2]
lst.sort(key=lambda x: -x)
print(lst)                          # [3, 2, 1]

# Combined with map / filter
print(list(map(lambda x: x ** 2, [1, 2, 3])))               # [1, 4, 9]
print(list(filter(lambda x: x % 2 == 0, [1, 2, 3, 4])))     # [2, 4]

# Capturing outer variables (closure)
base = 100
add_base = lambda x: x + base
print(add_base(1))                  # 101
```

### Call-site `*`/`**` Unpacking

When calling a function, `*iterable` unpacks an iterable into positional arguments, and `**mapping` unpacks a dict into keyword arguments:

```python
def add(a, b, c=0):
    return a + b + c

add(*[1, 2])                # 3        (*list unpacking)
add(*[1, 2, 3])             # 6
add(1, *[2])                # 3        (mixed positional and *)
add(1, **{"b": 2, "c": 3})  # 6        (**dict unpacking)
add(*[1], **{"b": 2})       # 3        (* and ** together)
print(*[1, 2, 3], sep="-")  # 1-2-3    (with built-ins)
```

### import and Built-in Modules

Supports `import` / `from-import` of built-in modules (`math` / `random` / `statistics` / `functools` / `itertools` / `collections` / `string` / `operator`):

```python
import math
math.sqrt(16)                 # 4.0

import math as m
m.floor(3.7)                  # 3

from math import sqrt, pi as p
sqrt(9)                       # 3.0

from math import *
gcd(12, 18)                   # 6

import operator
sorted([(2, "b"), (1, "a")], key=operator.itemgetter(0))   # [(1, 'a'), (2, 'b')]
```

> **Note**: only built-in modules are currently supported; importing user-authored `.py` files is not. See [Built-in Modules](./builtin.md) for details.

### global / nonlocal

```python
x = 1

def outer():
    y = 2

    def inner():
        nonlocal y
        y = 3       # Modify outer variable

    inner()
    print(y)        # 3

def change_global():
    global x
    x = 100         # Modify global variable

print(x)            # 1
outer()             # 3
print(x)            # 1
change_global()
print(x)            # 100
```

### Comprehensions and Generator Expressions

**List / dict / set comprehensions**:

```python
[x * x for x in range(5) if x % 2 == 0]       # [0, 4, 16]
{k: v for k, v in [("a", 1), ("b", 2)]}       # {'a': 1, 'b': 2}
{x * x for x in [1, 2, 2, 3]}                 # {1, 4, 9} (auto-deduplicated)
```

**Multiple `for` clauses**: a comprehension may contain several `for` clauses (nested in the order
written, inner clauses can reference outer loop variables), and each `for` may carry several `if` clauses; list / dict / set comprehensions and generator expressions all support this:

```python
[x * y for x in [1, 2] for y in [10, 20]]     # [10, 20, 20, 40]
[x + y for x in range(3) for y in range(x)]   # [1, 2, 3] (inner depends on outer)

[x for x in range(10) if x % 2 == 0 if x > 4] # [6, 8] (several ifs on one for)
[x * y for x in range(5) if x % 2 == 1 for y in range(3) if y != 1]

{k: v for k, v in [("a", 1), ("b", 2)] if v > 1}   # {'b': 2}
sorted({x * y for x in [1, 2] for y in [2, 3]})    # [2, 3, 4, 6]

list(x * y for x in [1, 2] for y in [10, 20])      # [10, 20, 20, 40] (generator)
```

**Tuple targets**: loop variables may be written as `k, v`, unpacking each element positionally:

```python
[k for k, v in [("a", 1), ("b", 2)]]          # ['a', 'b']
{v * 10 for k, v in [("a", 1), ("b", 2)]}     # {10, 20}
```

**Generator expressions**: `(expr for var in iterable [if cond])` evaluates to a lazy generator object that yields one item per `next()` / iteration step — ideal for large or infinite sequences; it can also be passed as a function argument without extra parentheses:

```python
g = (x * x for x in range(5))
type(g)                 # <class 'generator'>
list(g)                 # [0, 1, 4, 9, 16]

next(g2)                # advance one step (one-shot iterator; stops when exhausted)
sum(x * x for x in range(4))     # 14 (bare form)
list(x for x in range(6) if x % 2 == 0)    # [0, 2, 4]

from itertools import islice
list(islice((x * x for x in count()), 5))   # [0, 1, 4, 9, 16] (with infinite sequences)
```

> **⚠️ Breaking Change (v0.3.0)**: Previously `(x for x in it)` was treated as a list comprehension and **eagerly evaluated to a list**; it is now a **lazy generator object**.
> Old code that directly subscripts / `len()`s / calls list methods on the result will fail — convert with `list(g)` / `tuple(g)` first
> generators are **one-shot iterators** (re-iterating does not restart).

### `slice` Object

`slice(start, stop[, step])` builds a reusable slice object for `lst[slice(...)]` / `"str"[slice(...)]`:

```python
s = slice(1, 4)
s.start / s.stop / s.step   # 1 / 4 / None (unset bounds are None)
lst[slice(1, 4)]            # equivalent to lst[1:4]
lst[slice(0, 6, 2)]         # equivalent to lst[0:6:2]
lst[slice(4, 0, -1)]        # negative step reverses
"abcdef"[slice(1, 4)]       # "bcd"
isinstance(s, slice)        # True
```

### List / Tuple / Dictionary Operations

```python
# List
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

# List unpacking
a, b, c = [10, 20, 30]

# Dictionary
d = {"name": "Alice", "age": 30}
print(d["name"])
print(d.get("city", "N/A"))
d["city"] = "Beijing"
print(d.keys())
print(d.values())
d["age"] = None
d.pop("age")
d.update({"x": 1})

# Dictionary iteration
for key in d:
    print(key, d[key])
```

### Exception Handling

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

### Custom Classes and Magic Methods

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

### Custom Exception Classes

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

# Exception inheritance
class NetworkError(AppError):
    def __init__(self, msg, code, url):
        self.url = url

try:
    raise NetworkError("timeout", 503, "/api/data")
except AppError as e:           # Parent class can catch child class
    print("caught:", str(e))
```

### Inheritance

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

#### `super()` Calling Parent Methods

Supports Python 3 style zero-argument `super()` to call parent methods or constructors from a subclass method; the two-argument form `super(Class, obj)` is also supported

```python
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return self.name + " makes a sound"

class Dog(Animal):
    def __init__(self, name):
        super().__init__(name)          # call parent constructor

    def speak(self):
        return super().speak() + " (from Dog)"   # call parent method

d = Dog("Buddy")
print(d.speak())                # Buddy makes a sound (from Dog)

# Multi-level inheritance: super() walks up the chain
class A:
    def val(self):
        return 1
class B(A):
    def val(self):
        return super().val() + 10
class C(B):
    def val(self):
        return super().val() + 100
print(C().val())                # 111

# Two-argument form super(Class, obj)
class Q(P):
    def greet(self):
        return "child"
q = Q()
print(super(Q, q).greet())      # parent
```

> **Note**: `super()` can only be used inside class methods (static methods have no self/cls and raise `RuntimeError: super(): no arguments`).

### assert Statement

```python
def divide(a, b):
    assert b != 0, "divisor cannot be zero"
    return a / b

divide(10, 0)   # AssertionError: divisor cannot be zero
```

---

## Error Handling

### Checking Execution State

```gdscript
var dsl = PyGDS.new()
dsl.write_dsl_script(source_code)
var state = dsl.run()

if state == PyGDS.State.ERROR:
    print("DSL execution failed!")
    print("Error: ", dsl.report.last_error)
elif state == PyGDS.State.FINISHED:
    print("DSL execution succeeded!")
```

### Common Error Examples

```python
# Syntax error (detected during write_dsl_script)
print("hello"                 # Missing closing parenthesis → parse error

# Runtime error
x = 1 + "hello"               # TypeError
lst = [1, 2, 3]
print(lst[5])                 # IndexError
d = {"key": "value"}
print(d["missing"])           # KeyError

# Division by zero
print(10 / 0)                 # ZeroDivisionError
print(10 // 0)                # ZeroDivisionError
print(10 % 0)                 # ZeroDivisionError
```

### Runtime Error Line Numbers

Uncaught runtime errors append the line number of the offending statement to the error message, making it easier to locate problems

```python
a = 1
b = 2
c = a + undefined_var         # NameError: name 'undefined_var' is not defined (line 3)
```

The error message is available via `dsl.report.last_error`, in the format `ErrorType: message (line N)`.

### Debugging Tips

```python
# Use print for debugging output
x = 42
print("DEBUG: x =", x)       # Output to print_output

# Use logging functions
info("entering function foo")
warn("potential issue detected")
error("unexpected state")
```

---

## Indentation Notes

> **Important**: PyGDS uses **space indentation**, consistent with Python, with 4 spaces per indentation level.
>
> GDScript natively requires **hard tabs (Tab)** as indentation. If you are writing DSL code directly as a string in the Godot editor, you don't need to worry about this issue — PyGDS's `write_dsl_script` passes the string as-is to the lexer.
>
> However, if you need to embed code copied from a Python file into a GDScript string, note that GDScript strings do not support real Tab indentation (Tabs are automatically replaced in the Godot editor). In this case, it is recommended to write DSL code using a script editor or external text editor, then load it as a file.

---

## Reusing PyGDS Instances

```gdscript
var dsl = PyGDS.new()
dsl.set_debug_mode(true)

# First execution
dsl.write_dsl_script("""
x = 10
print(x)
""")
dsl.run()

# Second execution — each write_dsl_script clears previous output
dsl.write_dsl_script("""
y = 20
print(y)
print(x)  # Error: x is not in scope!
""")
dsl.run()
```

> **Note**: Each call to `write_dsl_script` creates a completely new parsing environment (new AST statement list) and resets internal state. The first `run()` creates an `Interpreter` instance, which is reused on subsequent suspension resumes. Therefore, variables are not shared between two `write_dsl_script` calls, but variables are preserved across suspension resumes.

### Viewing Output from Two Rounds of Execution

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

## Suspension System

PyGDS provides a suspension mechanism that allows DSL scripts to pause during execution and wait for external conditions to be met before resuming. This is very useful in game development, for example, waiting for an animation to finish, waiting for player input, or implementing delay logic.

The suspension system classifies suspensions into two types:

| Type | State | Trigger Method | Resume Method |
| :--- | :--- | :--- | :--- |
| SLEEPING | `SUSPENDED_SLEEPING` | `sleep(n)` / `request_suspend_sleeping(n)` | Auto-resume after Timer timeout |
| WAITING | `SUSPENDED_WAITING` | `request_suspend_waiting()` (GDScript side) | Set `state = RUNNING` externally, then call `run()` |

### State Machine

The `PyGDS.State` enum defines the complete lifecycle of a DSL instance:

- `IDLE`: Initial state, not yet executed
- `RUNNING`: Currently executing
- `SUSPENDED_SLEEPING`: SLEEPING suspension, auto-resumes after Timer timeout
- `SUSPENDED_WAITING`: WAITING suspension, waits for external `state = RUNNING` then manual resume
- `FINISHED`: Execution completed
- `ERROR`: Execution error

The `run()` method returns the current state, and external code decides subsequent behavior based on the return value.

### SLEEPING Suspension

SLEEPING suspension is suitable for scenarios with known wait times, such as skill cooldowns in combat or text printing delays in dialogue. `request_suspend_sleeping` internally creates a Timer via `SceneTree.create_timer`, which automatically calls `run()` to resume after the timeout.

***DSL Built-in Function***

```python
sleep(1.5)  # Suspend for 1.5 seconds, then auto-resume
```

***Direct Call from GDScript Side***

```gdscript
dsl.request_suspend_sleeping(2.0)  # Suspend for 2 seconds, then auto-resume

# You can also pass an on_resume callback, called before run() resumes execution
dsl.request_suspend_sleeping(2.0, func():
    print("About to resume from SLEEPING")
)
```

***Custom Resume Callback***

If you need to execute additional logic after each Timer timeout (e.g., updating UI), you can set `_sleeping_resume_callback`. This callback is called **before** `run()` resumes execution (note: after Timer timeout, `run()` always auto-resumes; the callback is only for additional logic and should not call `run()`):

```gdscript
dsl._sleeping_resume_callback = func():
    print("Resumed from SLEEPING")
    # Update UI and other additional logic (do not call run() here)
```

> **Note**: `_sleeping_resume_callback` is cleared after each call. If you need it to fire on every SLEEPING resume, re-set it in the callback or in the state handler function.

### WAITING Suspension

WAITING suspension is suitable for scenarios with uncertain wait times, such as waiting for a player button click, waiting for an animation to finish, or waiting for a network request to return.

***Usage from GDScript Side***

WAITING suspension is not a DSL built-in function; it is triggered by calling `request_suspend_waiting()` on the GDScript side through a registered API function.

```gdscript
# Register an API to trigger WAITING suspension
dsl.register_api_pair("wait_for_confirm", func(_args, _kwargs):
    dsl.request_suspend_waiting()
    # Execute suspension, run() will return SUSPENDED_WAITING
)

dsl.write_dsl_script("""
print("Please confirm...")
wait_for_confirm()
print("Confirmed!")
""")

# First execution
var state = dsl.run()
# state == PyGDS.State.SUSPENDED_WAITING

# External resume
dsl.state = PyGDS.State.RUNNING
state = dsl.run()
# Continues execution, outputs "Confirmed!"
```

***Custom Resume Callback***

`request_suspend_waiting` supports an optional `on_resume` callback parameter, which is automatically called **before** resuming execution, suitable for cleanup or state switching logic.

```gdscript
dsl.register_api_pair("play_animation", func(args, _kwargs):
    var name = args[0].value
    print("Starting animation: " + name)
    dsl.request_suspend_waiting(func():
        print("Animation '%s' finished!" % name)
    )
)
```

When external resume occurs, the `on_resume` callback fires first, then the DSL continues from the suspension point.

### Suspension API Execution Order

Note that when calling suspension request functions (`request_suspend_sleeping` and `request_suspend_waiting`) on the API side, the function **always finishes executing before suspending**. For example:

```gdscript
func move():
    move_start()
    request_suspend_waiting()  # on_resume = Callable()
    move_end()
```

The execution order of this code is: `move_start -> request_suspend_waiting -> move_end -> suspend -(after resume)-> on_resume.call()`

If you need a code block to run after resuming, use the `on_resume` parameter. For example:

```gdscript
func move():
    move_start()
    request_suspend_waiting(move_end)  # on_resume = move_end
```

The execution order of this code is: `move_start -> request_suspend_waiting -> suspend -(after resume)-> move_end.call()`

### Event-Driven Execution Pattern

When using the suspension system in an actual game, the **event-driven** pattern is recommended over polling:

```gdscript
# Recommended: event-driven
func _step_execute():
    var state = dsl.run()
    match state:
        PyGDS.State.SUSPENDED_SLEEPING:
            pass  # Timer callback will automatically trigger _step_execute()
        PyGDS.State.SUSPENDED_WAITING:
            show_continue_button()  # Wait for user click
        PyGDS.State.FINISHED:
            on_script_finished()
        PyGDS.State.ERROR:
            on_script_error()

func _on_continue_button():
    dsl.state = PyGDS.State.RUNNING
    _step_execute()
```

### Preset Script

`set_preset_script` allows injecting preset code (such as constant definitions, utility functions) before user code. Preset code and user code are **independently parsed**, ensuring accurate error line numbers.

```gdscript
var dsl = PyGDS.new()

dsl.set_preset_script("""
MAX_HP = 100
def clamp(value, lo, hi):
    if value < lo:
        return lo
    if value > hi:
        return hi
    return value
""")

dsl.write_dsl_script("""
print(MAX_HP)         # 100
print(clamp(150, 0, 100))  # 100
""")
```

The ASTs of preset code and user code are concatenated after parsing and then executed together, so variables/functions/classes with the same name will be overridden by later definitions, consistent with Python semantics.

## Limitations and Notes

### Floating Point Precision

Since the underlying implementation uses GDScript's double-precision floating point numbers (`float` i.e. 64-bit IEEE 754), there may be subtle differences from Python's floating point calculations.

```python
# Godot's str() and Python's str() may produce different output formats
print(1.15)  # May output "1.15" in Godot, while Python outputs "1.15"
print(1.0 / 3.0)  # Floating point precision is consistent, but string representation may differ
```

### String Method Differences

| Method | Differences from Python |
| :--- | :--- |
| `strip()` | Uses Godot's `strip_edges()`, behavior has subtle differences from Python's `.strip()` |
| `split()` | Supports `maxsplit` parameter, consistent with Python |
| `find()` | Only supports single-parameter lookup, does not support `start`/`end` range parameters |

---

## Complete Usage Examples

### property in Game Scripts

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
print(sword.name)         # Read via getter
print(sword.price)        # 100
sword.price = 150         # Write via setter
print(sword.info)         # "Sword: 150 gold" — computed property
""")
    dsl.run()
```

### Game Scripting System

```gdscript
# Godot scene script
extends Node

var dsl: PyGDS

func _ready():
    dsl = PyGDS.new()
    dsl.set_debug_mode(true)

    # Register game APIs
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

    # Execute game script
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

### Configuration File Interpreter

```gdscript
func load_config(config_text: String) -> Dictionary:
    var dsl = PyGDS.new()
    dsl.set_debug_mode(false)

    # Register an API to return a Python dictionary to Godot
    var exported_config = {}
    dsl.register_api({
        "export_config": func(args, _kwargs):
            var raw_dict = args[0]
            # Convert DSLDict to Godot Dictionary
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

# Usage example
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
