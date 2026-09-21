# Exception System

PyGDS implements an exception handling mechanism highly consistent with Python, including `raise`, `try/except`, exception inheritance hierarchy, and custom exception classes.

---

## DSLException — The Underlying Exception Object

`DSLException` is the primitive object used by PyGDS to represent exceptions at the low level, directly inheriting from `DSLObject`.

### Class Structure

```gdscript
class DSLException extends DSLObject:
    # Error message string
    var message: String
    # Exception type name
    var error_type: String
    # Additional exception arguments
    var args: Array[DSLObject] = []
```

### Core Methods

| Method | Behavior |
| :--- | :--- |
| `_type_name()` | Returns `error_type` (the exception type name) |
| `_dsl_str()` | If `message` is non-empty: `"ErrorType: message"`; otherwise: `"ErrorType"` |
| `_dsl_bool()` | Always returns `true` (the boolean value of an exception object is always true) |
| `_dsl_eq(other)` | Compares whether both `error_type` and `message` are the same |

### Construction Example

```gdscript
var exc = DSLException.new("division by zero", "ZeroDivisionError", [])
print(exc._dsl_str())    # ZeroDivisionError: division by zero
print(exc._type_name())  # ZeroDivisionError
print(exc._dsl_bool())   # true
```

---

## Exception Class Hierarchy

PyGDS defines exception types as **`DSLClass` instances**, not as separate constructor classes. All exception classes are uniformly registered through the `_define_exception` function.

### Built-in Exception Hierarchy

```python
Exception                          # Base class
├── TypeError                      # Type error
├── ValueError                     # Value error
│   └── StatisticsError            # Statistics error (raised by the statistics module)
├── RuntimeError                   # Runtime error
├── NameError                      # Name error
├── KeyError                       # Key error
├── IndexError                     # Index error
├── AttributeError                 # Attribute error
├── ArithmeticError                # Arithmetic error
│   └── ZeroDivisionError          # Division by zero error
├── StopIteration                  # Iteration stop
├── AssertionError                 # Assertion error
├── EOFError                       # End of input
└── ImportError                    # Import error
```

### Registration Mechanism — `_define_exception`

Located in `PyGDS.Interpreter._define_exception`

```gdscript
func _define_exception(type_name: String, base_name: String = "Exception"):
    var base_class = null
    if base_name != "":
        base_class = globals.get_val(base_name)

    var methods = {}
    # 1. Inject __new__ (created using _make_builtin)
    var obj_new = _make_builtin("__new__", Callable(self, "api_object_new"))
    if obj_new is DSLBuiltinFunction:
        methods["__new__"] = obj_new

    # 2. Inject __init__ (using _exception_init callback)
    var init_desc = DSLMethodDescriptor.new("__init__", Callable(self, "_exception_init"))
    methods["__init__"] = init_desc

    # 3. Inject __str__ (using _exception_str callback)
    var str_desc = DSLWrappedDescriptor.new("__str__", Callable(self, "_exception_str"))
    methods["__str__"] = str_desc

    # 4. Create DSLClass and register in global scope
    var class_obj = DSLClass.new(type_name, base_class, methods, self)
    globals.define(type_name, class_obj)
    exception_hierarchy[type_name] = base_name
```

***Parameter Description***

| Parameter | Description |
| :--- | :--- |
| `type_name` | The name of the exception type (e.g., `"TypeError"`) |
| `base_name` | The name of the parent exception type, defaults to `"Exception"`. Pass `""` to indicate no parent class (only used for the root Exception) |

**Built-in Exception Registration Order** (in `register_builtins`)

```gdscript
_define_exception("Exception", "")              # Root class, no parent
_define_exception("TypeError")                  # Defaults to inheriting from Exception
_define_exception("ValueError")
_define_exception("RuntimeError")
_define_exception("NameError")
_define_exception("KeyError")
_define_exception("IndexError")
_define_exception("AttributeError")
_define_exception("ArithmeticError")
_define_exception("ZeroDivisionError", "ArithmeticError")   # Specifies parent class
_define_exception("StopIteration")
_define_exception("AssertionError")
```

---

## `_exception_init` Callback — Exception Construction Process

Located in `PyGDS.Interpreter._exception_init`

When `DSLClass`'s `magic_call` is invoked (i.e., `TypeError("some message")`), `__new__` first creates a `DSLObject` wrapper, then `__init__` triggers the `_exception_init` callback:

```gdscript
func _exception_init(exc_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
    var wrapper = exc_args[0]               # DSLObject (created by __new__)
    var pos_args: Array[DSLObject] = []
    for i in range(1, exc_args.size()):
        pos_args.append(exc_args[i])        # Collect positional arguments
    var msg = ""
    if pos_args.size() > 0:
        msg = pos_args[0]._dsl_str()        # First argument = message
    var exc = DSLException.new(msg, wrapper.klass.name, pos_args)
    wrapper._wrapped = exc                  # Store DSLException in _wrapped
    wrapper.fields["args"] = DSLTuple.new(pos_args)  # Store arguments in args
    return DSLNone.new()
```

### Execution Flow

```txt
TypeError("bad type")
    │
    ▼
1. DSLClass("TypeError").magic_call([DSLString.new("bad type")])
    │
    ▼
2. __new__ creates a DSLObject wrapper
    │  wrapper.klass = TypeError_class
    │
    ▼
3. __init__ → _exception_init(wrapper, pos_args)
    │  Creates DSLException(msg="bad type", error_type="TypeError", args=[DSLString("bad type")])
    │  Stores in wrapper._wrapped
    │  Stores in wrapper.fields["args"]
    │
    ▼
4. Returns DSLObject (wrapper)
```

This means that:

- `e.args` returns a `DSLTuple` containing the arguments passed to the exception constructor
- `e._wrapped` stores the underlying `DSLException` object
- `str(e)` obtains the string representation via the `_exception_str` callback

---

## `_exception_str` Callback — String Representation of Exceptions

Located in `PyGDS.Interpreter._exception_str`

```gdscript
func _exception_str(exc_args: Array[DSLObject], _kwargs: Dictionary[String, DSLObject]) -> DSLObject:
    var wrapper = exc_args[0]
    var raw = wrapper._wrapped
    if raw and raw is DSLException:
        return DSLString.new(raw._dsl_str())
    return DSLString.new(wrapper._type_name())
```

When `str(e)` is called, the interpreter looks up `__str__` on the exception class, ultimately calling this callback. It retrieves the underlying `DSLException` from `wrapper._wrapped` and returns its string representation.

***Example***

```python
e = TypeError("bad type")
print(str(e))     # TypeError: bad type
print(e.args)     # ("bad type",)
```

---

## `raise` Statement Execution Flow

When the interpreter executes a `raise` statement, it goes through the following process:

```gdscript
if stmt is RaiseStmt:
    if stmt.expression != null:
        var exc = evaluate(stmt.expression)       # 1. Evaluate the raise expression
        if exc == null:
            return ExecResult.RAISE                # Evaluation failed, propagate upward

        var is_valid = false
        var err_type = ""
        var err_msg = ""

        if exc is DSLException:
            is_valid = true                        # 2a. Raw DSLException
            err_type = exc.error_type
            err_msg = exc.message
        elif exc.fields != null:
            var exc_type = globals.get_val("Exception")
            if exc_type is DSLClass and exc._is_subclass_of_klass(exc_type):
                is_valid = true                    # 2b. DSLObject that inherits from Exception
                err_type = exc._type_name()
                if exc._wrapped is DSLException:
                    err_msg = exc._wrapped.message
                elif exc.fields.has("args") and exc.fields["args"] is DSLTuple \
                    and exc.fields["args"].items.size() > 0:
                    err_msg = exc.fields["args"].items[0]._dsl_str()

        if is_valid:
            last_exception = exc                   # 3. Set last_exception
            report.error(err_type + ": " + err_msg) # 4. Report the error
        else:
            raise_exception("TypeError", "exceptions must derive from Exception")
        return ExecResult.RAISE                    # 5. Return RAISE status
```

### Flow Diagram

```txt
raise SomeError("msg")
        │
        ▼
1. evaluate(SomeError("msg"))
   → DSLClass("SomeError").magic_call → DSLObject
        │
        ▼
2. Validate exception type legality
   ├── Is it a DSLObject that inherits from Exception? → Valid
   └── No → raise TypeError("exceptions must derive from Exception")
        │
        ▼
3. Set Interpreter.last_exception = exc
        │
        ▼
4. report.error(error_type + ": " + message)
        │
        ▼
5. Return ExecResult.RAISE
   → exec_block detects RAISE → propagates upward through the call stack
```

### `raise` Re-raising

```python
try:
    1 / 0
except ZeroDivisionError:
    print("caught")
    raise  # Re-raise the current exception
```

When `raise` is used without an expression, the interpreter checks whether `last_exception` has been set and uses it for re-raising.

---

## `try/except` Exception Matching

### `_is_exception_match` — Matching Core

Located in `PyGDS.Interpreter._is_exception_match`

```gdscript
func _is_exception_match(exc, type_expr) -> bool:
    if type_expr == null:
        return true                              # No type restriction → match all

    var saved_has_error = report.has_error
    report.has_error = false
    var type_obj = evaluate(type_expr)           # Evaluate the except type expression
    report.has_error = saved_has_error

    if type_obj == null:
        return false

    if type_obj is DSLTuple:                     # Tuple form: except (TypeError, ValueError)
        for item in type_obj.items:
            if item is DSLClass and exc.fields != null:
                if exc._is_subclass_of_klass(item):
                    return true
        return false

    if not type_obj is DSLClass:                 # Must be a DSLClass
        return false

    if exc.fields != null:
        return exc._is_subclass_of_klass(type_obj)  # Check inheritance relationship

    return false
```

### Matching Rules

1. **Single type match**: `except TypeError` — only `TypeError` and its subclasses match
2. **Tuple match**: `except (TypeError, ValueError)` — any of the types or their subclasses match
3. **Untyped match**: `except` — matches all exceptions
4. **Inheritance-aware**: Uses `_is_subclass_of_klass` to traverse the class inheritance chain

### `_is_subclass_of_klass` — Inheritance Chain Check

Located in `PyGDS.DSLObject._is_subclass_of_klass`

```gdscript
func _is_subclass_of_klass(target: DSLClass) -> bool:
    var current = klass
    while current != null:
        if current == target:
            return true
        current = current.superclass
    return false
```

Starting from the current instance's class, traverses upward along the `superclass` chain to check whether it reaches the target class.

---

## Custom Exception Classes

Since exception types are implemented using standard `DSLClass`, users can define their own exception classes just like defining ordinary classes.

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

### Custom Exception Execution Flow

```txt
class MyError(Exception):
    ↓
DSLClass("MyError", superclass=Exception_class, methods={...})
    ↓
raise MyError("failed", 404)
    ↓
1. MyError_class.magic_call([DSLString("failed"), DSLInteger(404)])
    │
2. __new__ creates DSLObject wrapper
    │  wrapper.fields = {}
    │
3. __init__ → user-defined __init__
    │  wrapper.fields["code"] = DSLInteger(404)   ← user-defined attribute
    │  (_exception_init is also called, setting _wrapped and args)
    │
4. Returns DSLObject (containing code, _wrapped, args fields)
    ↓
except MyError as e:
    ↓
_is_exception_match(exc, MyError_class)
    → exc._is_subclass_of_klass(MyError_class)
    → klass = MyError_class → superclass = Exception_class → null() → false
    → But matches successfully at the current class!
```

### Multi-level Inheritance Support

```python
class AppBaseError(Exception):
    def __init__(self, msg):
        pass

class NetworkError(AppBaseError):
    def __init__(self, msg, status_code):
        self.status_code = status_code

try:
    raise NetworkError("timeout", 503)
except AppBaseError as e:        # Parent class catches child class
    print("caught by base")
except NetworkError as e:        # Exact match
    print("caught by network")
```

Since `_is_subclass_of_klass` traverses the entire inheritance chain, `except AppBaseError` can catch `NetworkError`.

---

## `raise_exception` — Built-in Exception Raising Utility

Located in `PyGDS.Interpreter.raise_exception`

The interpreter internally uses the `raise_exception` method to quickly create and raise exceptions:

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

***Usage Example (inside the interpreter)***

```gdscript
raise_exception("TypeError", "cannot add int and str")
raise_exception("ZeroDivisionError", "division by zero")
raise_exception("RuntimeError", "maximum step count exceeded")
```

### `raise_exception_from_last_error` — Error Propagation

Located in `PyGDS.Interpreter.raise_exception_from_last_error`

```gdscript
func raise_exception_from_last_error(last_err: String):
    var colon_idx = last_err.find(": ")
    if colon_idx != -1:
        raise_exception(last_err.substr(0, colon_idx), last_err.substr(colon_idx + 2))
    else:
        raise_exception("RuntimeError", last_err)
```

When the `last_error` string contains formatted error information (e.g., `"TypeError: bad operand"`), this function parses the exception type and calls `raise_exception`.

---

## Exception Storage Structure

The following diagram illustrates the complete structure of a raised exception in memory:

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
    └── "code" → DSLInteger(404)  ← user-defined attribute
```

**Access Paths:**

| Python Expression | Actual Access Path |
| :--- | :--- |
| `str(e)` | `wrapper._wrapped._dsl_str()` |
| `e.args` | `wrapper.fields["args"]` |
| `e.code` | `wrapper.fields["code"]` |
| `type(e).__name__` | `wrapper.klass.name` |
| `isinstance(e, MyError)` | `wrapper._is_subclass_of_klass(MyError_class)` |

---

## `try/except/finally` Complete Execution Flow

```txt
try:
    # Statement block
except TypeError as e:
    # Handle TypeError
except (ValueError, RuntimeError):
    # Handle these two
except:
    # Catch-all
else:
    # Executed when no exception occurs
finally:
    # Always executed
```

1. Execute the statements in the `try` block
2. If execution completes normally (returns `ExecResult.NORMAL`), execute the `else` block (if present)
3. If it returns `ExecResult.RAISE`:
   - Try each `except` clause in order
   - For each clause, call `_is_exception_match(last_exception, type_expr)`
   - Once a match is found, bind `last_exception` to the `as` variable
   - Execute the statements in that `except` block
   - Clear `last_exception`
4. Regardless of whether an exception occurred, the `finally` block is always executed
5. If the `finally` block contains a `return`/`raise`/`break`/`continue`, it will override the previous state

---

## Error Reporting System — ConsoleReport

Located in `PyGDS.ConsoleReport`

`ConsoleReport` is responsible for collecting and reporting all errors and logs during DSL execution.

### Key Properties

```gdscript
class ConsoleReport:
    var has_error: bool = false        # Whether there is an unhandled error
    var last_error: String = ""        # The most recent error message
    var log_entries: Array = []        # List of log entries
```

### Log Levels

| Level | Value | Description |
| :--- | :--- | :--- |
| `PRINT` | -1 | Forced output (not filtered by log level) |
| `ALL` | 0 | All levels |
| `TRACE` | 1 | Tracing |
| `DEBUG` | 2 | Debug information |
| `INFO` | 3 | General information |
| `WARN` | 4 | Warnings |
| `ERROR` | 5 | Errors |
| `FATAL` | 6 | Fatal errors |
| `OFF` | 7 | Disable all output |

### Error Reporting Methods

| Method | Description |
| :--- | :--- |
| `error(msg)` | Reports an error, sets `has_error = true`, `last_error = msg` |
| `fatal_error(msg)` | Reports a fatal error and terminates execution |
| `info(msg)` | Logs an info-level message |
| `warn(msg)` | Logs a warning-level message |

---

## Debugging and Error Tracing

### Example: Complete Exception Handling Flow

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

### Propagation When Exceptions Do Not Match

If the exception raised in the `try` block is not matched by any `except` clause, the exception propagates upward to the outer call stack.

```python
def inner():
    raise ValueError("bad value")


def outer():
    try:
        inner()
    except TypeError:            # ValueError does not match TypeError
        print("type error")
    # ValueError continues to propagate upward

outer()  # ValueError: bad value → uncaught exception
```

### Multi-level Nested try/except

```python
try:
    try:
        raise ValueError("inner")
    except TypeError:
        print("inner type error")    # No match
    # ValueError propagates to the outer level
except ValueError as e:
    print("outer caught:", e)        # outer caught: ValueError: inner
```
