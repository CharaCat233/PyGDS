# PyGDS Architecture

## Overview

PyGDS is a Python-like scripting language interpreter (DSL) embedded in the Godot engine, implementing a complete lexing, parsing, and interpretation pipeline. It adopts a classic recursive descent parser + tree-walking interpreter architecture, modeled after CPython's design in the function/method type system, class/instance system, and descriptor protocol.

All core code of PyGDS resides in a single file `pygds.gd`, with no external dependencies.

---

## Execution Pipeline

```txt
Source Code (Python-like text)
   ↓ Lexing (Lexer.scan)
Token Stream (TokenType + lexeme + literal)
   ↓ Parsing (Parser.parse)
AST (Abstract Syntax Tree) — Stmt/Expr node tree
   ↓ Interpretation (Interpreter.interpret)
ExecBlock → execute → evaluate
```

### Full Lifecycle

1. **User calls `write_dsl_script(source)`** — Lexing and parsing are performed sequentially.
2. **User calls `run()`** — On first execution (IDLE state), an `Interpreter` instance is created, built-in functions and exception types are registered, then built-in class definitions and the user's top-level statements are executed. The same instance is reused when resuming from suspension.
3. During execution, the entire environment is managed layer by layer within the `DSLEnvironment` scope chain.

---

## Part 1 - Lexer

The `PyGDS.Lexer` class is responsible for converting source code strings into a list of Tokens. It scans character by character, generating the corresponding Token based on the current context (e.g., whether at the beginning of a line).

### Token Type Enumeration

The `PyGDS.TokenType` enumeration values are as follows:

| Category | Token Types |
| :--- | :--- |
| Operators | `PLUS`, `MINUS`, `STAR`, `SLASH`, `DOUBLESLASH`, `STARSTAR`, `PERCENT`, `DOT` |
| Comparison | `EQUAL`, `GREATER`, `LESS`, `BANG`, `PIPE`, `BITAND` |
| Delimiters | `LPAREN`, `RPAREN`, `LBRACKET`, `RBRACKET`, `LBRACE`, `RBRACE`, `COMMA`, `COLON`, `NEWLINE` |
| Comparison (two-char) | `EQUAL_EQUAL`, `NOT_EQUAL`, `GREATER_EQUAL`, `LESS_EQUAL` |
| Augmented Assignment | `PLUS_EQ`, `MINUS_EQ`, `STAR_EQ`, `SLASH_EQ`, `DOUBLESLASH_EQ`, `STARSTAR_EQ`, `PERCENT_EQ` |
| Keywords | `IF`, `ELIF`, `ELSE`, `WHILE`, `FOR`, `IN`, `AND`, `OR`, `NOT`, `TRUE`, `FALSE`, `DEF`, `CLASS`, `RETURN`, `BREAK`, `CONTINUE`, `GLOBAL`, `NONLOCAL`, `TRY`, `EXCEPT`, `FINALLY`, `RAISE`, `AS`, `IS`, `LAMBDA` |
| Literals | `IDENTIFIER`, `STRING`, `FSTRING`, `INTEGER`, `FLOAT` |
| Special | `INDENT`, `DEDENT`, `EOF`, `AT`, `NULL`, `IS_NOT` |

### Token Structure

The struct **`PyGDS.Token`** records basic attributes such as the token type, the original string, the literal value, line number, and column number, for analysis and debugging purposes.

### Indentation Handling

PyGDS's Lexer uses an **indent stack (`indent_stack`)** mechanism to handle Python-style indentation.

- The initial stack is `[0]` (zero indentation is the global scope).
- At the beginning of each line, `handle_indent()` is called — it calculates the leading whitespace count and compares it with the top of the stack.
- Whitespace count > stack top → push the new indentation depth and generate an `INDENT` Token.
- Whitespace count < stack top → pop all depths greater than the current count from the stack and generate the corresponding `DEDENT` Tokens.
- Whitespace count == stack top → no Token is produced.
- At the end of the file, all remaining `DEDENT` Tokens are automatically completed.

### Keyword Recognition

The keyword mapping table **`PyGDS.Lexer.keywords`** maps Python keywords to the corresponding TokenType.

After recognition, `True`/`False`/`None` directly set `literal` to the corresponding literal value (`true`/`false`/`null`), rather than merely marking the Token type.

### Main Scanning Methods

| Method | Function |
| :--- | :--- |
| `PyGDS.Lexer.scan()` | Main loop, scans token by token until EOF |
| `PyGDS.Lexer.scan_token()` | Dispatches to specific processing logic based on the first character |
| `PyGDS.Lexer.string(quote_char)` | Handles single-quoted/double-quoted/triple-quoted strings |
| `PyGDS.Lexer.number()` | Handles integers and floating-point numbers |
| `PyGDS.Lexer.identifier()` | Handles identifiers, looks up the keyword table to determine the type |
| `PyGDS.Lexer.handle_indent()` | Handles leading indentation |
| `PyGDS.Lexer.match_char(expected)` | Looks ahead and consumes a character if matched (used for multi-character Tokens) |

---

## Part 2 - Parser

The `PyGDS.Parser` class is a **recursive descent parser** that uses a **Pratt parser** style to handle expression precedence. It converts the lexed Token list into an AST (Abstract Syntax Tree).

### Parsing Entry Point

The core parsing entry point is the `PyGDS.Parser.parse` method, which returns an array of statement nodes.

### Declaration Parsing

The method `PyGDS.Parser.declaration` attempts to match various statement or declaration types in order:

```txt
declaration() →
    @ → decorated_declaration()
    def → function_declaration()
    class → class_declaration()
    return → return_statement()
    break → BreakStmt
    continue → ContinueStmt
    global → global_statement()
    nonlocal → nonlocal_statement()
    if → if_statement()
    while → while_statement()
    for → for_statement()
    try → try_statement()
    raise → raise_statement()
    other → expression_statement()
```

### Expression Parsing Precedence Chain

From lowest to highest precedence:

```txt
expression_statement (handles assignment, augmented assignment, unpacking assignment)
  ↓ If type annotation var: type [= value]
  ↓ If unpacking assignment → parse_assignment_statement()
  ↓ Otherwise → tuple_expression()
      → conditional_expression()      ternary operator a if cond else b
        → or_expr()                   or operation
          → and_expr()                and operation
            → not_expr()              not unary operation
              → comparison()          comparison operations (==, !=, <, >, <=, >=, is, is not)
                → addition()          addition and subtraction (+, -)
                  → multiplication()  multiplication, division, modulo (*, /, %, //)
                    → power()         exponentiation (**) — right-associative
                      → unary()       unary operations (-, !)
                        → primary()   primary expressions (literals, variables, parentheses, lists, dicts)
                          → finish_call_or_index()  suffix chain: call( ), index[ ], attribute .attr
```

### Statement Parsing Details

| Method | Statement Parsed | Returns AST Node |
| :--- | :--- | :--- |
| `function_declaration()` | `def name(params): body` | `FunctionStmt` |
| `class_declaration()` | `class Name(Super): body` | `ClassStmt` |
| `if_statement()` | `if/elif/else` block | `IfStmt` |
| `while_statement()` | `while cond: body` | `WhileStmt` |
| `for_statement()` | `for vars in iterable: body` | `ForStmt` |
| `try_statement()` | `try/except/finally` block | `TryStmt` |
| `return_statement()` | `return [expr]` | `ReturnStmt` |
| `raise_statement()` | `raise [expr]` | `RaiseStmt` |
| `global_statement()` | `global name` | `GlobalStmt` |
| `nonlocal_statement()` | `nonlocal name` | `NonlocalStmt` |
| `expression_statement()` | Expression, assignment, augmented assignment, unpacking assignment | `ExpressionStmt` |
| `decorated_declaration()` | `@classmethod` / `@staticmethod` | `FunctionStmt` (with `method_type`) |

### Code Block Parsing

The method `PyGDS.Parser.block` can parse code blocks after a colon, supporting two formats:

- Indented block: colon followed by newline + INDENT → multi-line statements → DEDENT
- Single-line block: colon followed immediately by a single simple statement (no newline)

### Type Annotation Handling

The method `PyGDS.Parser.skip_type_annotation` skips the type annotation portion, stopping when it encounters `=`, `,`, `:`, `)`, or newline, and supports nested generic brackets.

This parsing process erases type annotations, whereas Python stores them in the `__annotations__` dictionary.

> If you are interested in Python type annotations, refer to PEP 563 and PEP 649.

### Unpacking Assignment Detection

The method `PyGDS.Parser.is_unpack_assignment` looks ahead in the Token stream to determine whether it is an unpacking assignment pattern. If so, it calls `PyGDS.Parser.parse_assignment_statement` to generate an `UnpackAssign` node.

### Synchronization Recovery

When a parse error occurs, the `PyGDS.Parser.skip_until_balanced` method can be called to skip the current line until a safe recovery point is encountered (`NEWLINE`, etc.), allowing the parser to continue from the next statement.

---

## Part 3 - AST Node System

The AST is divided into two base classes: **`PyGDS.Stmt`** (statements) and **`PyGDS.Expr`** (expressions).

### Stmt Nodes (Statements)

| Node Class | Key Fields | Description |
| :--- | :--- | :--- |
| `PyGDS.ExpressionStmt` | `expression: Expr` | Expression statement |
| `PyGDS.IfStmt` | `condition`, `then_branch`, `elif_branches`, `else_branch` | if/elif/else statement |
| `PyGDS.WhileStmt` | `condition: Expr`, `body: Array` | while loop |
| `PyGDS.ForStmt` | `variables: Array[String]`, `iterable: Expr`, `body: Array` | for loop (supports multi-variable unpacking) |
| `PyGDS.FunctionStmt` | `name`, `params: Array[Param]`, `body: Array`, `method_type: int` | Function definition |
| `PyGDS.ClassStmt` | `name`, `superclass: Expr`, `body: Array[Stmt]` | Class definition |
| `PyGDS.ReturnStmt` | `value: Expr` | return statement |
| `PyGDS.BreakStmt` | (no fields) | break statement |
| `PyGDS.ContinueStmt` | (no fields) | continue statement |
| `PyGDS.GlobalStmt` | `name: String` | global declaration |
| `PyGDS.NonlocalStmt` | `name: String` | nonlocal declaration |
| `PyGDS.TryStmt` | `try_body`, `except_clauses: Array[ExceptClause]`, `finally_body` | try statement |
| `PyGDS.RaiseStmt` | `expression: Expr` | raise statement |

### Expr Nodes (Expressions)

| Node Class | Key Fields | Description |
| :--- | :--- | :--- |
| `PyGDS.Literal` | `value` | Literal |
| `PyGDS.Variable` | `name: String` | Variable reference |
| `PyGDS.Assign` | `name: String`, `value: Expr` | Variable assignment |
| `PyGDS.AugAssign` | `name`, `operator: Token`, `value` | Augmented assignment (`x += 1`) |
| `PyGDS.AugAssignAttr` | `object`, `name`, `operator`, `value` | Attribute augmented assignment (`obj.x += 1`) |
| `PyGDS.AugAssignItem` | `object`, `index`, `operator`, `value` | Index augmented assignment (`arr[i] += 1`) |
| `PyGDS.Binary` | `left: Expr`, `operator: Token`, `right: Expr` | Binary operation |
| `PyGDS.Unary` | `operator: Token`, `right: Expr` | Unary operation (`-`, `not`) |
| `PyGDS.GetAttr` | `object: Expr`, `name: String` | Attribute access (`obj.attr`) |
| `PyGDS.SetAttr` | `object`, `name`, `value` | Attribute assignment (`obj.attr = val`) |
| `PyGDS.GetItem` | `object`, `index` | Index access (`arr[idx]`) |
| `PyGDS.SetItem` | `object`, `index`, `value` | Index assignment (`arr[idx] = val`) |
| `PyGDS.Call` | `callee_expr`, `arguments: Array[Expr]`, `keyword_args: Array[KeywordArg]` | Function call |
| `PyGDS.ListLiteral` | `elements: Array[Expr]` | List literal |
| `PyGDS.TupleLiteral` | `elements: Array[Expr]` | Tuple literal |
| `PyGDS.DictLiteral` | `keys: Array[Expr]`, `values: Array[Expr]` | Dictionary literal |
| `PyGDS.ListComp` | `elt_expr`, `var_name`, `iterable`, `condition` | List comprehension |
| `PyGDS.DictComp` | `key_expr`, `value_expr`, `k_var`, `v_var`, `iterable`, `condition` | Dictionary comprehension |
| `PyGDS.ConditionalExpr` | `condition`, `true_expr`, `false_expr` | Ternary conditional expression |
| `PyGDS.UnpackAssign` | `targets: Array`, `value: Expr` | Unpacking assignment |
| `PyGDS.StarredTarget` | `target: Variable` | Starred unpacking target |
| `PyGDS.UnpackTarget` | `targets: Array` | Nested unpacking target |

### Auxiliary Classes

| Class | Fields | Description |
| :--- | :--- | :--- |
| `PyGDS.Param` | `name`, `default_value`, `is_args`, `is_kwargs`, `is_positional_only`, `is_keyword_only` | Function parameter |
| `PyGDS.KeywordArg` | `name: String`, `value: Expr` | Keyword argument |
| `PyGDS.ExceptClause` | `exception_type: Expr`, `as_name: String`, `body: Array` | except clause |

---

## Part 4 - Interpreter

The `PyGDS.Interpreter` class is a **tree-walking interpreter** that executes code by recursively traversing AST nodes.

### Execution Model

```txt
interpret(statements)
  → exec_block(statements, environment)
    → execute(stmt)     [for each statement]
      → evaluate(expr)  [for each expression]
```

### ExecResult Enumeration

The return status `PyGDS.Interpreter.ExecResult` that controls execution flow is as follows:

| Enum Value | Meaning | Trigger Condition |
| :--- | :--- | :--- |
| `NORMAL` | Normal execution | Default |
| `RETURN` | Function return | `return` statement |
| `BREAK` | Break out of loop | `break` statement |
| `CONTINUE` | Continue to next iteration | `continue` statement |
| `ERROR` | Execution error | Arithmetic error, type error, etc. |
| `RAISE` | Exception raised | `raise` statement or runtime exception |
| `SUSPENDED` | Execution suspended | Suspension request |

### `evaluate()` — The Largest Dispatch Function

`PyGDS.Interpreter.evaluate()` dispatches based on the expression type and is the core of the interpreter. The processing logic for each type is as follows:

| Expression Type | Processing Logic |
| :--- | :--- |
| `Literal` | Wraps the value as a DSLObject and returns it (`_wrap(value)`) |
| `Variable` | Looks up the variable in the scope environment chain |
| `Assign` | Evaluates the right-hand side, stores in the environment |
| `AugAssign` | Gets the current value + evaluates the right-hand side → `_aug_assign_compute()` → updates |
| `AugAssignAttr` | Gets `obj.attr` → computes → `_dsl_setattr` |
| `AugAssignItem` | Gets `obj[idx]` → computes → `_dsl_setitem` |
| `UnpackAssign` | Evaluates the right-hand side iterator → distributes by target pattern |
| `SetItem` | Evaluates object, index, value → `_dsl_setitem(obj, idx, val)` |
| `GetItem` | Evaluates object, index → `_dsl_getitem(obj, idx)` |
| `GetAttr` | Evaluates object → `_dsl_getattribute(obj, name)` |
| `SetAttr` | Evaluates object, value → `_dsl_setattr(obj, name, val)` |
| `Binary` | Evaluates left and right operands → dispatches by operator |
| `Unary` | Evaluates operand → dispatches by operator (`-`, `not`) |
| `ConditionalExpr` | Evaluates condition → selects true/false branch |
| `Call` | Evaluates callee and arguments → calls `callee.magic_call()` or `call_user_function()` |
| `ListLiteral` | Evaluates each element → builds DSLList |
| `TupleLiteral` | Evaluates each element → builds DSLTuple |
| `DictLiteral` | Evaluates each key-value pair → builds DSLDict |
| `ListComp` | Iterates → sets variable → evaluates condition → evaluates element → collects |
| `DictComp` | Iterates → sets key/value variables → evaluates condition → evaluates key/value → collects |

### Binary Operation Dispatch Details

```gdscript
match expr.operator.type:
    PLUS:    → _call_magic_or_fallback(left, "__add__", [right], ...)
    MINUS:   → _call_magic_or_fallback(left, "__sub__", [right], ...)
    STAR:    → _call_magic_or_fallback(left, "__mul__", [right], ...)
    SLASH:   → _call_magic_or_fallback(left, "__truediv__", [right], ...)
    DOUBLESLASH: → _call_magic_or_fallback(left, "__floordiv__", [right], ...)
    STARSTAR:    → _call_magic_or_fallback(left, "__pow__", [right], ...)
    PERCENT:     → _call_magic_or_fallback(left, "__mod__", [right], ...)
    EQUAL_EQUAL: → _call_magic_or_fallback(left, "__eq__", [right], ...)
    NOT_EQUAL:   → _call_magic_or_fallback(left, "__ne__", [right], ...)
    GREATER:     → _call_magic_or_fallback(left, "__gt__", [right], ...)
    GREATER_EQUAL: → _call_magic_or_fallback(left, "__ge__", [right], ...)
    LESS:        → _call_magic_or_fallback(left, "__lt__", [right], ...)
    LESS_EQUAL:  → _call_magic_or_fallback(left, "__le__", [right], ...)
    AND:  → left._dsl_bool() ? right : left    (short-circuit evaluation, returns the operand itself)
    OR:   → left._dsl_bool() ? left : right    (short-circuit evaluation, returns the operand itself)
    IS:   → left._object_id == right._object_id
    IS_NOT: → left._object_id != right._object_id
```

### Class and Instance System

PyGDS's instance system has three paths:

| Type | `__new__` Return Type | Description |
| :--- | :--- | :--- |
| Built-in types (`int(5)`) | `DSLObject` | Directly returns `DSLInteger`/`DSLFloat`/`DSLString`/`DSLList`/`DSLTuple`/`DSLDict`/`DSLBool`, `klass` points to the corresponding built-in type |
| Subclassing built-in types (`MyInt(5)`) | `DSLObject` | Returns `DSLInteger`, but `klass` points to the subclass (`MyInt_class`), correctly finds parent methods via MRO |
| Pure user-defined classes (`Foo()`) | `DSLObject` | `fields = {}` stores instance attributes (corresponding to Python `__dict__`), `klass` points to the class definition |
| Exception types | `DSLObject` | `_wrapped` stores the raw `DSLException` object |

- All DSLObjects have a `klass` field (modeled after CPython `PyObject.ob_type`), enabling unified type lookup.
- Built-in type constructors (e.g., `int(5)`, `str("hello")`) directly return the raw `DSLObject` via their respective `api_*_new` functions, with `klass` pointing to the built-in type.
- User subclasses that inherit from built-in types (e.g., `class MyInt(int)`) return the raw DSLObject after instantiation, with `klass` pointing to the subclass.
- `DSLObject` directly serves as pure user-defined class instances (`fields = {}`) and exception instances (`_wrapped` stores DSLException).

```txt
Instance System:
  Built-in type construction:  int(5) → DSLInteger { klass → int_class }
  Subclass construction:       MyInt(5) → DSLInteger { klass → MyInt_class }
  Pure user class construction: Foo() → DSLObject { fields={}, klass → Foo_class }
  Exception construction:      Exception() → DSLObject { _wrapped → DSLException, klass → Exception_class }
```

### Magic Method Lookup Priority

Taking `a + b` as an example, when PyGDS executes an expression like `a + b`, the following call chain occurs:

```txt
evaluate(Binary: a + b)
  → _call_magic_or_fallback(a, "__add__", [b], fallback)
       → a.klass._lookup_method("__add__")
            → Searches along the MRO chain for the method
       → Found → descriptor binding → magic_call
       → Not found → fallback.call()
```

Step 1: `PyGDS.DSLClass._lookup_method` — MRO inheritance chain lookup

First searches for `__add__` in the current class's methods dictionary. If not found, follows the superclass pointer upward (MRO linear chain), all the way to the top (the `object` base class). Returns null if still not found.

This is essentially a simplified MRO (Method Resolution Order), just a linear single chain rather than the full C3 linearization.

Step 2: `PyGDS.Interpreter._call_magic_or_fallback` — The core of two-phase dispatch

This method first checks the type pointer (`obj.klass != null`). Only DSLObjects have the `klass` field. If the object is not a DSLObject (e.g., a GDS native `null`), it goes directly to the fallback.

Then it looks up the method on the class (`obj.klass._lookup_method("__add__")`). This step invokes the MRO lookup described above. The key point is that it returns a raw method (such as DSLWrappedDescriptor, DSLMethodDescriptor, DSLBuiltinFunction), which has not yet been bound to a specific instance.

Finally, descriptor protocol binding is performed (`method.has_method("__get__")`). If the found method implements the descriptor protocol (has the `PyGDS.DSLFunction.__get__` method), it is called to complete the binding.

***Descriptor Type Comparison***

| Descriptor Type | `__get__(obj, klass)` Returns | Usage | Meaning |
| :--- | :--- | :--- | :--- |
| DSLMethodDescriptor | BoundMethod | Used for ordinary methods (`upper`, `append`, etc.), internally wrapped as `Callable` | Binds the method to the instance so that `self` points to `obj` when called |
| DSLWrappedDescriptor | MethodWrapper | Used for magic methods (`__add__`, `__str__`, etc.) | Wraps the magic method as a callable object |

This step is modeled after `PyMethod_New` + descriptor invocation in CPython.

After binding is complete, execution proceeds through the `PyGDS.DSLObject.magic_call` unified interface. `extra_args` only contains the other operand, since `self` has already been determined during binding.

If `__add__` is not found on the class (e.g., the built-in type `int` does not register magic methods on DSLClass), the `fallback` is executed.

`fallback` directly calls the `magic_add` channel of the `left` object itself (i.e., GDS's internal polymorphic dispatch).

Step 3: The caller's full view

In `PyGDS.Interpreter.evaluate()` at the `Binary` case:

```gdscript
match expr.operator.type:
    TokenType.PLUS:
        result = _call_magic_or_fallback(left, "__add__", [right],
            func(): return left.magic_add([left, right] as Array[DSLObject], {}))
```

**Actual paths for three cases:**

Case A - User-defined class overloads `__add__`

```python
class MyNumber:
    def __init__(self, v): self.v = v
    def __add__(self, other): return MyNumber(self.v + other.v)

a = MyNumber(5)
b = MyNumber(3)
print(a + b)  # MyNumber(8)
```

1. `a.klass` → `MyNumber_class`
2. `_lookup_method("__add__")` → found in `MyNumber_class.methods`
3. `__get__` binding → `BoundMethod`
4. `magic_call([b])` → executes the user-defined function body

Case B - Built-in type `int`

```python
print(1 + 2)  # 3
```

1. `left = DSLInteger(1)`, but `left.klass` may be null (or `__add__` is not registered on the built-in `int_class`)
2. `_lookup_method("__add__")` → returns null
3. Goes to fallback → `left.magic_add([left, right], {})`
4. `DSLInteger.magic_add` → directly performs integer addition

Case C - Subclass inheriting from a built-in type overloads `__add__`

```python
class MyInt(int):
    def __add__(self, other):
        return MyInt(int(self) + int(other) + 100)
```

1. `a.klass` → `MyInt_class` (points to the subclass)
2. `_lookup_method("__add__")` → found in `MyInt_class.methods`
3. `__get__` binding → `BoundMethod`
4. Executes the user-defined `__add__` logic, internally calling the parent class `int`'s addition

***Key Design Philosophy Summary***

```txt
         _call_magic_or_fallback
                │
    ┌───────────┴───────────┐
    │  First look up magic   │  ← _lookup_method (MRO)
    │  method on the class   │  (supports user operator overloading)
    ├───────────────────────┤
    │  If not found, fall    │  ← fallback
    │  back to native        │  (direct polymorphic dispatch)
    │  magic_* fast path     │
    └───────────────────────┘
```

This two-phase dispatch — first checking the class method table, then falling back to native methods — enables:

- **User-defined classes** to freely overload operators by defining methods like `__add__`.
- **Built-in types** to go through the fallback `magic_*` fast path, unaffected by class lookup overhead.
- **Subclasses inheriting from built-in types** to partially overload operators, with non-overloaded ones automatically inheriting parent behavior.

This design directly mirrors the complete flow in CPython: `PyObject_GetAttr` → `type.tp_getattro` → `MRO` lookup → descriptor binding.

### Function Calls

`PyGDS.Interpreter.call_user_function` handles argument binding for user-defined functions:

1. **Argument classification**: positional-only, regular, keyword-only, `*args`, `**kwargs`
2. **Positional argument binding**: matches each to regular parameters one by one, `*args` collects the remainder
3. **Keyword argument binding**: matches non-`is_positional_only` parameters, unmatched ones are collected into `**kwargs`
4. **Default value filling**: evaluates default expressions in the closure environment
5. **Missing check**: checks whether required positional and keyword-only parameters are missing
6. **Execute function body**: `exec_block` in a newly created local environment, captures the `RETURN` signal

### Built-in Classes and Built-in Functions

Registered into the global scope in `PyGDS.Interpreter.register_builtins`.

The `klass` of all DSLClass instances points to `type_class`, achieving a complete metatype programming closed loop.

The `__new__` of built-in types uses `Interpreter.api_*_new` functions to directly return the raw DSLObject, while the `object` base class still uses the traditional flow of `api_object_new` + `_object_init`.

For related content, please refer to the [builtin documentation](./builtin.md).

The inheritance hierarchy of built-in exceptions is as follows:

```txt
Exception
├── TypeError
├── ValueError
├── RuntimeError
├── NameError
├── KeyError
├── IndexError
├── AttributeError
├── ArithmeticError
│   └── ZeroDivisionError
├── StopIteration
└── AssertionError
```

Each exception type is a `DSLClass` with `__new__`, `__init__`, and `__str__` methods.

Exception instances are `DSLObject`, with the internal `_wrapped` field storing the raw `DSLException` object.

---

## Part 5 - DSLEnvironment Scope

`PyGDS.DSLEnvironment` is the implementation of nested scopes, similar to Python's LEGB rule.

### Core Fields

| Field | Description |
| :--- | :--- |
| `values: Dictionary` | Variable name → DSLObject mapping |
| `enclosing: DSLEnvironment` | Reference to the outer scope (null indicates global) |
| `global_vars: Array[String]` | List of variables declared as global |
| `nonlocal_bindings: Dictionary` | Nonlocal bindings (variable name → target Environment) |
| `report: ConsoleReport` | Log reporter |

### Core Methods

| Method | Behavior |
| :--- | :--- |
| `define(name, value)` | Defines a variable in the current scope |
| `get_val(name)` | First looks in nonlocal bindings, then in the current layer, and finally follows the enclosing chain upward |
| `set_val(name, value)` | First checks nonlocal, then checks global (writes to global), then looks up or creates in the current layer |
| `has_val(name)` | Same lookup logic as above, returns bool |
| `mark_global(name)` | Marks as global, removes the local variable of the same name from the current environment |
| `mark_nonlocal(name, target_env)` | Marks as nonlocal, pointing to the specified outer environment |

### global Semantics

After `global x` is declared, `set_val("x", ...)` follows the enclosing chain all the way to the topmost (global) environment to write, and `get_val("x")` similarly reads directly from the global environment.

### nonlocal Semantics

After `nonlocal x` is declared, the interpreter finds the first non-global outer environment that defines `x` in `execute()`, then `mark_nonlocal("x", target_env)` creates the binding. Subsequent `get_val("x")` and `set_val("x", ...)` are redirected directly to that target environment, thereby modifying the variable in the outer scope.

---

## Part 6 - PyGDS Main Class

The `PyGDS` class is a subclass of `Node` and serves as the controller of the entire DSL system, managing the complete lifecycle in a Singleton-like pattern.

### Properties

| Property | Type | Description |
| :--- | :--- | :--- |
| `debug` | `bool` | Debug mode toggle |
| `dsl_script` | `String` | DSL source code text |
| `_preset_script` | `String` | Preset code source text |
| `print_output` | `String` | Accumulated print output |
| `console_output` | `String` | Console log output |
| `statements` | `Array` | Parsed AST statement list |
| `_preset_statements` | `Array` | Parsed AST statements of preset code |
| `interpreter` | `Interpreter` | Interpreter instance |
| `report` | `ConsoleReport` | Console reporter |
| `log_level` | `Level` | Log level |
| `api_functions` | `Dictionary` | External API registry |
| `state` | `State` | Current state (IDLE / RUNNING / SUSPENDED_SLEEPING / SUSPENDED_WAITING / FINISHED / ERROR) |
| `_sleeping_resume_callback` | `Callable` | SLEEPING resume callback, called before resuming execution in run() |
| `_waiting_resume_callback` | `Callable` | WAITING resume callback |

| Static Property | Type | Description |
| :--- | :--- | :--- |
| `_dsl_next_object_id` | `int` | Next Object ID |

### Key Methods

| Method | Function |
| :--- | :--- |
| `set_debug_mode(bool)` | Sets debug mode |
| `set_log_level(Level)` | Sets log level |
| `register_api(Dictionary)` | Registers external API functions |
| `register_api_pair(name, callable)` | Registers a single external API function |
| `write_dsl_script(String)` | Source code → Lexer → Parser → AST |
| `set_preset_script(String)` | Sets preset code, executed before user code |
| `run() -> State` | Creates Interpreter → registers built-in functions and exceptions → executes, returns current state |
| `reset()` | Resets all runtime state |
| `request_suspend_sleeping(value: float, on_resume: Callable)` | Requests SLEEPING suspension, automatically calls run() after Timer timeout, optional on_resume callback |
| `request_suspend_waiting(on_resume: Callable)` | Requests WAITING suspension, optional resume callback |

---

## Part 7 - Suspension System

The suspension system allows DSL scripts to pause during execution and resume after external conditions are met. It achieves a two-layer separated suspension architecture by introducing a `_suspended` bypass channel at the interpreter layer and a state machine at the PyGDS layer.

### Architecture Layers

```txt
DSL Layer
  sleep(n)                     — DSL built-in function
GDScript Layer
  request_suspend_waiting()    — GDScript API function
     ↓
Interpreter Layer
  ExecResult.SUSPENDED  — Control flow signal (does not distinguish suspension type)
  _suspended: bool     — Bypass channel, conveys the fact of suspension
  _is_waiting: bool    — Bypass channel, conveys the suspension type (false=SLEEPING, true=WAITING)
     ↓
PyGDS Layer
  State.SUSPENDED_SLEEPING / SUSPENDED_WAITING  — External state
  _sleeping_resume_callback  — SLEEPING resume callback (called before run() resumes execution)
  _waiting_resume_callback  — WAITING resume callback (on_resume)
```

### SLEEPING Suspension Flow

```txt
DSL: sleep(1.5)
  → Interpreter._suspended = true, _is_waiting = false
  → PyGDS.request_suspend_sleeping(1.5)
     → state = SUSPENDED_SLEEPING
     → SceneTree.create_timer(1.5).timeout.connect(run)
  → run() returns SUSPENDED_SLEEPING
  → ... Timer timeout ...
  → run() is called → _sleeping_resume_callback.call() → _suspended cleared → Interpreter continues from suspension point
```

### WAITING Suspension Flow

```txt
GDScript API: request_suspend_waiting(on_resume)
  → Interpreter._suspended = true, _is_waiting = true
  → PyGDS.request_suspend_waiting(on_resume)
     → state = SUSPENDED_WAITING
     → _waiting_resume_callback = on_resume
  → run() returns SUSPENDED_WAITING
  → External code: state = RUNNING
  → run() is called → _waiting_resume_callback.call() → Interpreter continues from suspension point
```

### Resume Execution Mechanism

The key to the interpreter resuming from suspension lies in `_exec_stack` and `_call_stack`. When `interpret()` encounters `SUSPENDED`, the interpreter's execution stack (containing the recursion levels and resume points of `exec_block`) and call stack (function call return points) are fully preserved. The next time `run()` is called, `interpret()` restores state from the stack and resumes execution from the suspension point.

The `resume_info` dictionary is used to avoid re-evaluating conditional expressions when `IfStmt`/`WhileStmt`/`ForStmt` resume.

---

## Appendix - ConsoleReport

`PyGDS.ConsoleReport` is the unified error reporting and log output manager.

### Log Levels

```gdscript
enum Level {
    # DSL print output, not filtered by log level
    PRINT = -1,
    ALL = 0,
    TRACE = 1,
    DEBUG = 2,
    INFO = 3,
    WARN = 4,
    ERROR = 5,
    FATAL = 6,
    OFF = 7,
}
```

### Two Types of Error Handling

- **`error(msg)`**: Silently records the error (sets `has_error = true`), does not output immediately, used for exceptions that may be caught by try-except.
- **`fatal_error(msg)`**: Confirms an uncaught exception, outputs to the console and Godot log, called by the interpreter's top-level `interpret()`.

### Method List

| Method | Purpose |
| :--- | :--- |
| `print_msg(msg)` | Output of the `print()` function in DSL scripts |
| `info(msg)` | General information output |
| `warn(msg)` | Warning output |
| `err(msg)` | Error output |
| `error(msg)` | Silent error recording |
| `fatal_error(msg)` | Uncaught exception output |
| `clear_error()` | Clears error state (after an exception is caught by except) |
| `reset()` | Resets all state (before each new script run) |
| `refresh_output()` | Flushes accumulated messages to print_output / console_output |
