# PyGDS 架构详解

## 概述

PyGDS 是一个嵌入 Godot 引擎的类 Python 脚本语言解释器（DSL），实现了完整的词法分析、语法分析和解释执行流程。它采用经典的递归下降解析器 + 树遍历解释器架构，对标 CPython 在函数/方法类型系统、类/实例系统和描述符协议方面的设计

PyGDS 的全部核心代码位于单个文件 `pygds.gd` 中，无外部依赖

---

## 执行流程

```txt
源码（类 Python 文本）
   ↓ 词法分析 (Lexer.scan)
Token 流 (TokenType + lexeme + literal)
   ↓ 语法分析 (Parser.parse)
AST (抽象语法树) — Stmt/Expr 节点树
   ↓ 解释执行 (Interpreter.interpret)
ExecBlock → execute → evaluate
```

### 完整生命周期

1. **用户调用 `write_dsl_script(source)`** —— 依次执行词法分析和语法分析
2. **用户调用 `run()`** —— 首次执行时（IDLE 状态）创建 `Interpreter` 实例并注册内置函数和异常类型，然后执行内置类定义和用户的顶层语句。挂起恢复时复用同一实例
3. 执行过程中，整个环境在 `DSLEnvironment` 作用域链中逐层管理

---

## 第一部分 - Lexer 词法分析器

`PyGDS.Lexer` 类负责将源代码字符串转换为 Token 列表，它采用逐字符扫描的方式，在处理每个字符时根据当前上下文（如是否在行首）生成对应的 Token

### Token 类型枚举

Token 类型枚举 `PyGDS.TokenType` 的枚举值如下

| 类别 | Token 类型 |
| :--- | :--- |
| 运算符 | `PLUS`, `MINUS`, `STAR`, `SLASH`, `DOUBLESLASH`, `STARSTAR`, `PERCENT`, `DOT` |
| 比较符 | `EQUAL`, `GREATER`, `LESS`, `BANG`, `PIPE`, `BITAND` |
| 分隔符 | `LPAREN`, `RPAREN`, `LBRACKET`, `RBRACKET`, `LBRACE`, `RBRACE`, `COMMA`, `COLON`, `NEWLINE` |
| 比较（双字符） | `EQUAL_EQUAL`, `NOT_EQUAL`, `GREATER_EQUAL`, `LESS_EQUAL` |
| 增强赋值 | `PLUS_EQ`, `MINUS_EQ`, `STAR_EQ`, `SLASH_EQ`, `DOUBLESLASH_EQ`, `STARSTAR_EQ`, `PERCENT_EQ` |
| 关键字 | `IF`, `ELIF`, `ELSE`, `WHILE`, `FOR`, `IN`, `AND`, `OR`, `NOT`, `TRUE`, `FALSE`, `DEF`, `CLASS`, `RETURN`, `BREAK`, `CONTINUE`, `GLOBAL`, `NONLOCAL`, `TRY`, `EXCEPT`, `FINALLY`, `RAISE`, `AS`, `IS`, `LAMBDA` |
| 字面量 | `IDENTIFIER`, `STRING`, `FSTRING`, `INTEGER`, `FLOAT` |
| 特殊 | `INDENT`, `DEDENT`, `EOF`, `AT`, `NULL`, `IS_NOT` |

### Token 结构体

结构体 **`PyGDS.Token`** 会记录 Token 类型，原始字符串，字面量值，行号与列号等基础属性值，以便于分析与调试

### 缩进处理

PyGDS 的 Lexer 使用 **缩进栈 (`indent_stack`)** 机制处理 Python 风格的缩进

- 初始栈为 `[0]`（零缩进为全局作用域）
- 每行开始时调用 `handle_indent()` —— 计算前导空格数并与栈顶比较
- 空格数 > 栈顶 → 压入新缩进深度，生成 `INDENT` Token
- 空格数 < 栈顶 → 弹出栈中大于该值的深度，生成相应的 `DEDENT` Token
- 空格数 == 栈顶 → 不产生 Token
- 文件末尾自动补全所有剩余的 `DEDENT` Token

### 关键字识别

关键字映射表 **`PyGDS.Lexer.keywords`** 将 Python 关键字映射到对应的 TokenType

`True`/`False`/`None` 在识别后会直接设置 `literal` 为对应的字面量值（`true`/`false`/`null`），而不只是标记 Token 类型

### 主要扫描方法

| 方法 | 功能 |
| :--- | :--- |
| `PyGDS.Lexer.scan()` | 主循环，逐 Token 扫描直到 EOF |
| `PyGDS.Lexer.scan_token()` | 根据首字符分发到具体处理逻辑 |
| `PyGDS.Lexer.string(quote_char)` | 处理单引号/双引号/三引号字符串 |
| `PyGDS.Lexer.number()` | 处理整数和浮点数 |
| `PyGDS.Lexer.identifier()` | 处理标识符，查关键字表确定类型 |
| `PyGDS.Lexer.handle_indent()` | 处理行首缩进 |
| `PyGDS.Lexer.match_char(expected)` | 前瞻匹配并消费字符（用于多字符 Token） |

---

## 第二部分 - Parser 语法分析器

`PyGDS.Parser` 类是一个**递归下降解析器**，采用 **Pratt 解析器** 风格处理表达式优先级，它将经过词法分析的 Token 列表转换为 AST（抽象语法树）

### 解析入口

其核心解析入口为 `PyGDS.Parser.parse` 方法，该方法返回由语句节点组成的数组

### 声明解析

方法 `PyGDS.Parser.declaration` 按顺序尝试匹配各类语句或声明

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
    其他 → expression_statement()
```

### 表达式解析优先级链

从低到高的优先级顺序

```txt
expression_statement （处理赋值、增强赋值、解包赋值）
  ↓ 若为类型注释 var: type [= value]
  ↓ 若为解包赋值则走 parse_assignment_statement()
  ↓ 否则走 tuple_expression()
      → conditional_expression()      三目运算符 a if cond else b
        → or_expr()                   or 运算
          → and_expr()                and 运算
            → not_expr()              not 一元运算
              → comparison()          比较运算（==, !=, <, >, <=, >=, is, is not）
                → addition()          加减运算（+, -）
                  → multiplication()  乘除取模（*, /, %, //）
                    → power()         幂运算（**）— 右结合
                      → unary()       一元运算（-, !）
                        → primary()   基本表达式（字面量、变量、括号、列表、字典）
                          → finish_call_or_index()  后缀链：调用( )、索引[ ]、属性.attr
```

### 语句解析详情

| 方法 | 解析的语句 | 返回 AST 节点 |
| :--- | :--- | :--- |
| `function_declaration()` | `def name(params): body` | `FunctionStmt` |
| `class_declaration()` | `class Name(Super): body` | `ClassStmt` |
| `if_statement()` | `if/elif/else` 块 | `IfStmt` |
| `while_statement()` | `while cond: body` | `WhileStmt` |
| `for_statement()` | `for vars in iterable: body` | `ForStmt` |
| `try_statement()` | `try/except/finally` 块 | `TryStmt` |
| `return_statement()` | `return [expr]` | `ReturnStmt` |
| `raise_statement()` | `raise [expr]` | `RaiseStmt` |
| `global_statement()` | `global name` | `GlobalStmt` |
| `nonlocal_statement()` | `nonlocal name` | `NonlocalStmt` |
| `expression_statement()` | 表达式、赋值、增强赋值、解包赋值 | `ExpressionStmt` |
| `decorated_declaration()` | `@classmethod` / `@staticmethod` | `FunctionStmt`（含 method_type） |

### 代码块解析

方法 `PyGDS.Parser.block` 能够解析冒号后的代码块，支持两种格式

- 缩进块：冒号后换行 + INDENT → 多行语句 → DEDENT
- 单行块：冒号后紧跟一条简单语句（不用换行）

### 类型注释处理

方法 `PyGDS.Parser.skip_type_annotation` 将跳过类型注释部分，遇到 `=`、`,`、`:`、`)`、换行时停止，支持嵌套泛型括号

该解析过程会将类型注释进行擦除，而 Python 则是将其保存在 `__annotations__`  字典之内

> 如果您对 Python 类型注释感兴趣，可以查阅 PEP 563 和 PEP 649

### 解包赋值检测

方法 `PyGDS.Parser.is_unpack_assignment` 能够前瞻扫描 Token 流，判断是否为解包赋值模式。若是，则调用 `PyGDS.Parser.parse_assignment_statement` 生成 `UnpackAssign` 节点

### 同步恢复

当发生解析错误时，可调用 `PyGDS.Parser.skip_until_balanced` 方法跳过当前行直到遇到安全恢复点（`NEWLINE` 等），使解析器能从下一个语句继续

---

## 第三部分 - AST 节点体系

AST 分为 **`PyGDS.Stmt`**（语句）和 **`PyGDS.Expr`**（表达式）两大基类

### Stmt 节点（语句）

| 节点类 | 关键字段 | 说明 |
| :--- | :--- | :--- |
| `PyGDS.ExpressionStmt` | `expression: Expr` | 表达式语句 |
| `PyGDS.IfStmt` | `condition`, `then_branch`, `elif_branches`, `else_branch` | if/elif/else 语句 |
| `PyGDS.WhileStmt` | `condition: Expr`, `body: Array` | while 循环 |
| `PyGDS.ForStmt` | `variables: Array[String]`, `iterable: Expr`, `body: Array` | for 循环（支持多变量解包） |
| `PyGDS.FunctionStmt` | `name`, `params: Array[Param]`, `body: Array`, `method_type: int` | 函数定义 |
| `PyGDS.ClassStmt` | `name`, `superclass: Expr`, `body: Array[Stmt]` | 类定义 |
| `PyGDS.ReturnStmt` | `value: Expr` | return 语句 |
| `PyGDS.BreakStmt` | （无字段） | break 语句 |
| `PyGDS.ContinueStmt` | （无字段） | continue 语句 |
| `PyGDS.GlobalStmt` | `name: String` | global 声明 |
| `PyGDS.NonlocalStmt` | `name: String` | nonlocal 声明 |
| `PyGDS.TryStmt` | `try_body`, `except_clauses: Array[ExceptClause]`, `finally_body` | try 语句 |
| `PyGDS.RaiseStmt` | `expression: Expr` | raise 语句 |

### Expr 节点（表达式）

| 节点类 | 关键字段 | 说明 |
| :--- | :--- | :--- |
| `PyGDS.Literal` | `value` | 字面量 |
| `PyGDS.Variable` | `name: String` | 变量引用 |
| `PyGDS.Assign` | `name: String`, `value: Expr` | 变量赋值 |
| `PyGDS.AugAssign` | `name`, `operator: Token`, `value` | 增强赋值（`x += 1`） |
| `PyGDS.AugAssignAttr` | `object`, `name`, `operator`, `value` | 属性增强赋值（`obj.x += 1`） |
| `PyGDS.AugAssignItem` | `object`, `index`, `operator`, `value` | 索引增强赋值（`arr[i] += 1`） |
| `PyGDS.Binary` | `left: Expr`, `operator: Token`, `right: Expr` | 二元运算 |
| `PyGDS.Unary` | `operator: Token`, `right: Expr` | 一元运算（`-`, `not`） |
| `PyGDS.GetAttr` | `object: Expr`, `name: String` | 属性访问（`obj.attr`） |
| `PyGDS.SetAttr` | `object`, `name`, `value` | 属性赋值（`obj.attr = val`） |
| `PyGDS.GetItem` | `object`, `index` | 索引访问（`arr[idx]`） |
| `PyGDS.SetItem` | `object`, `index`, `value` | 索引赋值（`arr[idx] = val`） |
| `PyGDS.Call` | `callee_expr`, `arguments: Array[Expr]`, `keyword_args: Array[KeywordArg]` | 函数调用 |
| `PyGDS.ListLiteral` | `elements: Array[Expr]` | 列表字面量 |
| `PyGDS.TupleLiteral` | `elements: Array[Expr]` | 元组字面量 |
| `PyGDS.DictLiteral` | `keys: Array[Expr]`, `values: Array[Expr]` | 字典字面量 |
| `PyGDS.ListComp` | `elt_expr`, `var_name`, `iterable`, `condition` | 列表推导式 |
| `PyGDS.DictComp` | `key_expr`, `value_expr`, `k_var`, `v_var`, `iterable`, `condition` | 字典推导式 |
| `PyGDS.ConditionalExpr` | `condition`, `true_expr`, `false_expr` | 三目条件表达式 |
| `PyGDS.UnpackAssign` | `targets: Array`, `value: Expr` | 解包赋值 |
| `PyGDS.StarredTarget` | `target: Variable` | 星号解包目标 |
| `PyGDS.UnpackTarget` | `targets: Array` | 嵌套解包目标 |

### 辅助类

| 类 | 字段 | 说明 |
| :--- | :--- | :--- |
| `PyGDS.Param` | `name`, `default_value`, `is_args`, `is_kwargs`, `is_positional_only`, `is_keyword_only` | 函数参数 |
| `PyGDS.KeywordArg` | `name: String`, `value: Expr` | 关键字实参 |
| `PyGDS.ExceptClause` | `exception_type: Expr`, `as_name: String`, `body: Array` | except 子句 |

---

## 第四部分 - Interpreter 解释器

`PyGDS.Interpreter` 类是一个**树遍历解释器**，通过递归遍历 AST 节点来执行代码

### 执行模型

```txt
interpret(statements)
  → exec_block(statements, environment)
    → execute(stmt)     [对每条语句]
      → evaluate(expr)  [对每个表达式]
```

### ExecResult 枚举

控制执行流程的返回状态 `PyGDS.Interpreter.ExecResult` 如下

| 枚举值 | 含义 | 触发条件 |
| :--- | :--- | :--- |
| `NORMAL` | 正常执行 | 默认 |
| `RETURN` | 函数返回 | `return` 语句 |
| `BREAK` | 跳出循环 | `break` 语句 |
| `CONTINUE` | 继续下一次循环 | `continue` 语句 |
| `ERROR` | 执行错误 | 运算错误、类型错误等 |
| `RAISE` | 抛出异常 | `raise` 语句或运行时异常 |
| `SUSPENDED` | 执行挂起 | 挂起请求 |

### `evaluate()` —— 最大的分发函数

`PyGDS.Interpreter.evaluate()` 根据表达式类型进行分发，是解释器的核心，以下是各类型的处理逻辑

| 表达式类型 | 处理逻辑 |
| :--- | :--- |
| `Literal` | 将值包装为 DSLObject 返回（`_wrap(value)`） |
| `Variable` | 在作用域环境链中查找变量 |
| `Assign` | 求值右侧，存储到环境 |
| `AugAssign` | 获取当前值 + 求值右侧 → `_aug_assign_compute()` → 更新 |
| `AugAssignAttr` | 获取 `obj.attr` → 计算 → `_dsl_setattr` |
| `AugAssignItem` | 获取 `obj[idx]` → 计算 → `_dsl_setitem` |
| `UnpackAssign` | 求值右侧迭代器 → 按目标模式分发 |
| `SetItem` | 求值对象、索引、值 → `_dsl_setitem(obj, idx, val)` |
| `GetItem` | 求值对象、索引 → `_dsl_getitem(obj, idx)` |
| `GetAttr` | 求值对象 → `_dsl_getattribute(obj, name)` |
| `SetAttr` | 求值对象、值 → `_dsl_setattr(obj, name, val)` |
| `Binary` | 求值左右操作数 → 按运算符分发 |
| `Unary` | 求值操作数 → 按运算符分发（`-`, `not`） |
| `ConditionalExpr` | 求值条件 → 选择 true/false 分支 |
| `Call` | 求值 callee 和实参 → 调用 `callee.magic_call()` 或 `call_user_function()` |
| `ListLiteral` | 逐元素求值 → 构建 DSLList |
| `TupleLiteral` | 逐元素求值 → 构建 DSLTuple |
| `DictLiteral` | 逐键值求值 → 构建 DSLDict |
| `ListComp` | 迭代 → 设变量 → 求值条件 → 求值元素 → 收集 |
| `DictComp` | 迭代 → 设键值变量 → 求值条件 → 求值键值 → 收集 |

### Binary 运算分发详情

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
    AND:  → left._dsl_bool() ? right : left    （短路求值，返回操作数本身）
    OR:   → left._dsl_bool() ? left : right    （短路求值，返回操作数本身）
    IS:   → left._object_id == right._object_id
    IS_NOT: → left._object_id != right._object_id
```

### 类与实例系统

PyGDS 的实例系统分为三条路径：

| 类型 | `__new__` 返回类型 | 说明 |
| :--- | :--- | :--- |
| 内置类型 (`int(5)`) | `DSLObject` | 直接返回 `DSLInteger`/`DSLFloat`/`DSLString`/`DSLList`/`DSLTuple`/`DSLDict`/`DSLBool`，`klass` 指向对应内置类型 |
| 继承内置类型 (`MyInt(5)`) | `DSLObject` | 返回 `DSLInteger`，但 `klass` 指向子类（`MyInt_class`），通过 MRO 正确查找父类方法 |
| 纯用户自定义类 (`Foo()`) | `DSLObject` | `fields = {}` 存储实例属性（对应 Python `__dict__`），`klass` 指向类定义 |
| 异常类型 | `DSLObject` | `_wrapped` 存储 `DSLException` 原始对象 |

- 所有 DSLObject 均有 `klass` 字段（对标 CPython `PyObject.ob_type`），实现统一类型查找
- 内置类型构造函数（如 `int(5)`、`str("hello")`）通过各自的 `api_*_new` 函数直接返回原始 `DSLObject`，`klass` 指向内置类型
- 继承内置类型的用户子类（如 `class MyInt(int)`）实例化后返回原始 DSLObject，`klass` 指向子类
- `DSLObject` 直接作为纯用户自定义类实例（`fields = {}`）和异常实例（`_wrapped` 存 DSLException）

```txt
实例体系：
  内置类型构造:  int(5) → DSLInteger { klass → int_class }
  子类构造:      MyInt(5) → DSLInteger { klass → MyInt_class }
  纯用户类构造:  Foo() → DSLObject { fields={}, klass → Foo_class }
  异常构造:      Exception() → DSLObject { _wrapped → DSLException, klass → Exception_class }
```

### 魔法方法查找优先

以 a + b 为例，当 PyGDS 执行 a + b 这样的表达式时，发生以下调用链

```txt
evaluate(Binary: a + b)
  → _call_magic_or_fallback(a, "__add__", [b], fallback)
       → a.klass._lookup_method("__add__")
            → 沿 MRO 链查找方法
       → 找到 → 描述符绑定 → magic_call
       → 未找到 → fallback.call()
```

第一步：`PyGDS.DSLClass._lookup_method` — MRO 继承链查找

先在当前类的 methods 字典中查找 `__add__`，找不到则沿着 superclass 指针一路向上走（MRO 线性链），一直找到最顶层（object 基类），还没找到则返回 null

这本质上是个简化版的 MRO（Method Resolution Order），只是线性单链而非完整的 C3 线性化

第二步：`PyGDS.Interpreter._call_magic_or_fallback` — 两阶段分派核心

该方法先进行检查类型指针（`obj.klass != null`），只有 DSLObject 才有 klass 字段，如果对象不是 DSLObject（比如是 GDS 原生的 null），直接走 fallback

随后在类上查找方法（`obj.klass._lookup_method("__add__")`），这一步调用了上面说的 MRO 查找。关键在于其返回的是一段原始方法（如 DSLWrappedDescriptor、DSLMethodDescriptor、DSLBuiltinFunction），它们尚未与具体实例绑定

最后进行描述符协议绑定（`method.has_method("__get__")`），如果找到的方法实现了描述符协议（有 `PyGDS.DSLFunction.__get__` 方法），就调用它完成绑定

***描述符类型对比***

| 描述符类型 | `__get__(obj, klass)` 返回 | 用途 | 含义 |
| :--- | :--- | :--- | :--- |
| DSLMethodDescriptor | BoundMethod | 用于普通方法 (`upper`、`append` 等)，内部包装为 `Callable` | 将方法绑定到实例，使得调用时 self 指向 obj |
| DSLWrappedDescriptor | MethodWrapper | 用于魔术方法 (`__add__`、`__str__` 等) | 将 magic 方法包装为可调用对象 |

这一步对标 CPython 中的 `PyMethod_New` + 描述符调用

在绑定完成后，通过 `PyGDS.DSLObject.magic_call` 统一接口执行，`extra_args` 中只包含另一操作数，因为 `self` 已经在绑定时确定

如果类上没找到 `__add__`（比如内置类型 int 没有在 DSLClass 上注册魔法方法），就执行 `fallback`

`fallback` 直接调用 left 对象自身的 `magic_add` 通道（即 GDS 内部的多态分发）

第三步：调用方的完整视图

在 `PyGDS.Interpreter.evaluate()` 的 `Binary` 处

```gdscript
match expr.operator.type:
    TokenType.PLUS:
        result = _call_magic_or_fallback(left, "__add__", [right],
            func(): return left.magic_add([left, right] as Array[DSLObject], {}))
```

**三种情况的实际路径：**

情况 A - 用户自定义类重载了 `__add__`

```python
class MyNumber:
    def __init__(self, v): self.v = v
    def __add__(self, other): return MyNumber(self.v + other.v)

a = MyNumber(5)
b = MyNumber(3)
print(a + b)  # MyNumber(8)
```

1. `a.klass` → `MyNumber_class`
2. `_lookup_method("__add__")` → 在 `MyNumber_class.methods` 中找到
3. `__get__` 绑定 → `BoundMethod`
4. `magic_call([b])` → 执行用户定义的函数体

情况 B - 内置类型 `int`

```python
print(1 + 2)  # 3
```

1. `left = DSLInteger(1)`，但 `left.klass` 可能为 null（或内置 `int_class` 上未注册 `__add__`）
2. `_lookup_method("__add__")` → 返回 null
3. 走 fallback → `left.magic_add([left, right], {})`
4. `DSLInteger.magic_add` → 直接做整数加法

情况 C - 继承内置类型的子类重载 `__add__`

```python
class MyInt(int):
    def __add__(self, other):
        return MyInt(int(self) + int(other) + 100)
```

1. `a.klass` → `MyInt_class`（指向子类）
2. `_lookup_method("__add__")` → 在 `MyInt_class.methods` 中找到
3. `__get__` 绑定 → `BoundMethod`
4. 执行用户定义的 `__add__` 逻辑，内部调用父类 `int` 的加法

***关键设计思想总结***

```txt
         _call_magic_or_fallback
                │
    ┌───────────┴───────────┐
    │  先找类上的 magic 方法    │  ← _lookup_method (MRO)
    │  (支持用户重载运算符)     │
    ├───────────────────────┤
    │  找不到则回退到         │  ← fallback
    │  原生 magic_* 快速通道  │  (直接多态分发)
    └───────────────────────┘
```

这种先查类方法表，再回退到原生方法的两阶段分派，使得

- **用户自定义类** 可以通过定义 `__add__` 等方法自由重载运算符
- **内置类型** 走 fallback 的 `magic_*` 快速通道，不受类查找开销影响
- **继承内置类型的子类** 可以部分重载运算符，未重载的自动继承父类行为

这个设计直接对标的 CPython 中的 `PyObject_GetAttr` → `type.tp_getattro` → `MRO` 查找 → 描述符绑定的完整流程

### 函数调用

`PyGDS.Interpreter.call_user_function` 处理用户定义函数的参数绑定：

1. **参数分类**：positional-only、普通、keyword-only、`*args`、`**kwargs`
2. **位置参数绑定**：逐个匹配到普通参数，`*args` 收集剩余
3. **关键字参数绑定**：匹配非 `is_positional_only` 的参数，不匹配的收集到 `**kwargs`
4. **默认值填充**：在闭包环境中求值默认表达式
5. **缺失检查**：检查必选位置参数和必选关键字参数是否缺失
6. **执行函数体**：在新建的局部环境中 `exec_block`，捕获 `RETURN` 信号

### 内置类与内置函数

在 `PyGDS.Interpreter.register_builtins` 中注册到全局作用域

所有 DSLClass 实例的 `klass` 指向 `type_class`，实现完整的类型元编程闭环

内置类型的 `__new__` 使用 `Interpreter.api_*_new` 函数直接返回原始 DSLObject，`object` 基类仍使用 `api_object_new` + `_object_init` 的传统流程

相关内容请查阅 [builtin 文档](./builtin.md)

其中，内置异常的继承层级如下

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

每个异常类型都是一个 `DSLClass`，具有 `__new__`、`__init__`、`__str__` 方法

异常实例为 `DSLObject`，内部 `_wrapped` 字段存储 `DSLException` 原始对象

---

## 第五部分 - DSLEnvironment 作用域

`PyGDS.DSLEnvironment` 是嵌套作用域的实现，类似于 Python 的 LEGB 规则

### 核心字段

| 字段 | 说明 |
| :--- | :--- |
| `values: Dictionary` | 变量名 → DSLObject 映射 |
| `enclosing: DSLEnvironment` | 外层作用域引用（null 表示全局） |
| `global_vars: Array[String]` | global 声明的变量列表 |
| `nonlocal_bindings: Dictionary` | nonlocal 绑定（变量名 → 目标 Environment） |
| `report: ConsoleReport` | 日志报告器 |

### 核心方法

| 方法 | 行为 |
| :--- | :--- |
| `define(name, value)` | 在当前作用域定义变量 |
| `get_val(name)` | 先在 nonlocal 绑定中查找，再在当前层查找，最后沿 enclosing 链向上 |
| `set_val(name, value)` | 先查 nonlocal，再查 global（写全局），再在当前层查找或创建 |
| `has_val(name)` | 同上查找逻辑，返回 bool |
| `mark_global(name)` | 标记为 global，从当前环境删除同名本地变量 |
| `mark_nonlocal(name, target_env)` | 标记为 nonlocal，指向指定外层环境 |

### global 语义

`global x` 声明后，`set_val("x", ...)` 会沿着 enclosing 链一直走到最顶层（全局环境）写入，而 `get_val("x")` 同样直接读取全局环境

### nonlocal 语义

`nonlocal x` 声明后，解释器在 `execute()` 中查找第一个定义了 `x` 的非全局外层环境，然后 `mark_nonlocal("x", target_env)` 创建绑定。后续 `get_val("x")` 和 `set_val("x", ...)` 都会直接重定向到该目标环境，从而修改外层作用域的变量

---

## 第六部分 - PyGDS 主类

`PyGDS` 类是 `Node` 的子类，作为整个 DSL 系统的控制器，采用 Singleton-like 模式管理完整生命周期

### 属性

| 属性 | 类型 | 说明 |
| :--- | :--- | :--- |
| `debug` | `bool` | 调试模式开关 |
| `dsl_script` | `String` | DSL 源代码文本 |
| `_preset_script` | `String` | 预设代码源文本 |
| `print_output` | `String` | 累积的 print 输出 |
| `console_output` | `String` | 控制台日志输出 |
| `statements` | `Array` | 解析后的 AST 语句列表 |
| `_preset_statements` | `Array` | 预设代码解析后的 AST 语句 |
| `interpreter` | `Interpreter` | 解释器实例 |
| `report` | `ConsoleReport` | 控制台报告器 |
| `log_level` | `Level` | 日志级别 |
| `api_functions` | `Dictionary` | 外部 API 注册表 |
| `state` | `State` | 当前状态（IDLE / RUNNING / SUSPENDED_SLEEPING / SUSPENDED_WAITING / FINISHED / ERROR） |
| `_sleeping_resume_callback` | `Callable` | SLEEPING 恢复前回调，在 run() 恢复执行前调用 |
| `_waiting_resume_callback` | `Callable` | WAITING 恢复回调 |

| 静态属性 | 类型 | 说明 |
| :--- | :--- | :--- |
| `_dsl_next_object_id` | `int` | 下一个 Object 的 ID |

### 关键方法

| 方法 | 功能 |
| :--- | :--- |
| `set_debug_mode(bool)` | 设置调试模式 |
| `set_log_level(Level)` | 设置日志级别 |
| `register_api(Dictionary)` | 注册外部 API 函数 |
| `register_api_pair(name, callable)` | 注册单个外部 API 函数 |
| `write_dsl_script(String)` | 源码 → Lexer → Parser → AST |
| `set_preset_script(String)` | 设置预设代码，在用户代码之前执行 |
| `run() -> State` | 创建 Interpreter → 注册内置函数和异常 → 执行，返回当前状态 |
| `reset()` | 重置所有运行时状态 |
| `request_suspend_sleeping(value: float, on_resume: Callable)` | 请求 SLEEPING 挂起，Timer 超时后自动调用 run()，可选 on_resume 回调 |
| `request_suspend_waiting(on_resume: Callable)` | 请求 WAITING 挂起，可选恢复回调 |

---

## 第七部分 - 挂起系统

挂起系统允许 DSL 脚本在执行过程中暂停，等待外部条件满足后恢复。它通过在解释器层引入 `_suspended` 旁路通道，在 PyGDS 层引入状态机，实现了两层分离的挂起架构

### 架构分层

```txt
DSL 层
  sleep(n)                     — DSL 内置函数
GDScript 层
  request_suspend_waiting()    — GDScript API 函数
     ↓
解释器层 (Interpreter)
  ExecResult.SUSPENDED  — 控制流信号（不区分挂起类型）
  _suspended: bool     — 旁路通道，传递挂起事实
  _is_waiting: bool    — 旁路通道，传递挂起类型 (false=SLEEPING, true=WAITING)
     ↓
PyGDS 层
  State.SUSPENDED_SLEEPING / SUSPENDED_WAITING  — 对外状态
  _sleeping_resume_callback  — SLEEPING 恢复前回调 (在 run() 恢复执行前调用)
  _waiting_resume_callback  — WAITING 恢复回调 (on_resume)
```

### SLEEPING 挂起流程

```txt
DSL: sleep(1.5)
  → Interpreter._suspended = true, _is_waiting = false
  → PyGDS.request_suspend_sleeping(1.5)
     → state = SUSPENDED_SLEEPING
     → SceneTree.create_timer(1.5).timeout.connect(run)
  → run() 返回 SUSPENDED_SLEEPING
  → ... Timer 超时 ...
  → run() 被调用 → _sleeping_resume_callback.call() → _suspended 清除 → 解释器从挂起点继续
```

### WAITING 挂起流程

```txt
GDScript API: request_suspend_waiting(on_resume)
  → Interpreter._suspended = true, _is_waiting = true
  → PyGDS.request_suspend_waiting(on_resume)
     → state = SUSPENDED_WAITING
     → _waiting_resume_callback = on_resume
  → run() 返回 SUSPENDED_WAITING
  → 外部代码: state = RUNNING
  → run() 被调用 → _waiting_resume_callback.call() → 解释器从挂起点继续
```

### 恢复执行机制

解释器从挂起中恢复的关键在于 `_exec_stack` 和 `_call_stack`。当 `interpret()` 遇到 `SUSPENDED` 时，解释器的执行栈（包含 `exec_block` 的递归层级和恢复点）和调用栈（函数调用返回点）完整保留。下次调用 `run()` 时，`interpret()` 从栈中恢复状态，从挂起点继续执行

`resume_info` 字典用于避免 `IfStmt`/`WhileStmt`/`ForStmt` 恢复时重新求值条件表达式

---

## 附录 - ConsoleReport 控制台报告器

`PyGDS.ConsoleReport` 是统一的错误报告和日志输出管理器

### 日志级别

```gdscript
enum Level {
    # DSL print 输出, 不受日志级别过滤
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

### 两类错误处理

- **`error(msg)`**：静默记录错误（设置 `has_error = true`），不立即输出，用于 try-except 可能捕获的异常
- **`fatal_error(msg)`**：确认未捕获异常，输出到控制台和 Godot 日志，由解释器顶层 `interpret()` 调用

### 方法列表

| 方法 | 用途 |
| :--- | :--- |
| `print_msg(msg)` | DSL 脚本中 `print()` 函数的输出 |
| `info(msg)` | 普通信息输出 |
| `warn(msg)` | 警告输出 |
| `err(msg)` | 错误输出 |
| `error(msg)` | 静默错误记录 |
| `fatal_error(msg)` | 未捕获异常输出 |
| `clear_error()` | 清除错误状态（异常被 except 捕获后） |
| `reset()` | 重置全部状态（每次运行新脚本前） |
| `refresh_output()` | 刷新累积的消息到 print_output / console_output |
