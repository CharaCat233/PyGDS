# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)

## [Unreleased]

当前无待发布条目。其余已知问题与功能缺口见 README 的「已知问题与限制」章节，或在仓库 `tests/已知问题清单.md` 查看带复现脚本的完整清单

## [0.5.0-alpha.5] - 2026-09-23

本版修复 `[0.5.0-alpha.3]` 记录的 P0-2（最后一个 P0 级问题），并清理排查中发现的同族缺陷

### 修复

- **eager 推导式的元素表达式含副作用时重复执行（P0-2）**：列表/集合/字典推导式的元素表达式本身含副作用、且迭代源是含 `sleep` 的生成器时，语句重放会让元素表达式被重新求值（`seen=[]; print([seen.append(v) or v for v in a()])` 得到 `seen: [0, 0, 1]` 而非 `[0, 1]`）。根因是急切推导式由原生循环驱动，重放时整个循环从头再跑一遍。现在三类急切推导式改为驱动一个内部生成器（与生成器表达式共用同一套挂起感知机制），已产出的元素累积在生成器对象上，重放时只追加新元素；生成器本身按「节点 + 祖先推导式迭代进度」记忆，使「父级进入下一轮」能拿到新实例、而本轮重放始终复用同一个
- **同一语句内普通 `yield` 与 `yield from` 交替时重复产出**：`v = (yield 0) + (yield from inner())` 之类混合语句此前会重复产出已挂起过的 `yield` 值（得 `0 1 0 2` 而非 `0 1 2`）。根因是子表达式记忆仅按 `_pending_yield_index` 判定重放轮，而 `yield from` 的挂起不设该标记、被误判为「新一轮」而清空记忆。现在记忆在整个挂起周期内保持，并在语句真正执行完毕后才复位
- **多个内置类型的魔术方法缺失导致宿主侧崩溃**：未重写算术/一元/位运算的类型（如 `None`、`list`、`str`）此前会令宿主报 `Invalid call. Nonexistent function 'magic_div'` 并中止执行。DSLObject 补齐了 `magic_div` / `magic_lshift` / `magic_rshift` / `magic_and` / `magic_or` / `magic_xor` / `magic_neg` / `magic_pos` / `magic_invert` 等默认实现，统一给出与 CPython 一致的 `TypeError` 文案
- **`None` 参与运算时误报 `RuntimeError`**：`None + 1`、`None * 2`、`-None`、`~None` 等此前报 `RuntimeError: Unknown binary operation error`（或直接崩溃），现按 CPython 报 `unsupported operand type(s) for X: 'NoneType' and 'Y'` 与 `bad operand type for unary X`
- **一元 `+` 号不被解析**：`+x` 此前报 `Unexpected token '+'`，现支持（数值原样返回，其余类型报 CPython 文案），并补齐 `bool` 作为 `int` 子类的全部算术、位运算与比较语义
- **`int()` / `float()` 静默接受非法字面量**：`int("abc")`、`float("abc")` 此前直接调用宿主转换函数，分别静默返回 `0` 与 `0.0`。现在按 Python 规则严格解析：非法字面量报 `ValueError` / `TypeError`，支持 `1_0` 下划线分隔、`+` 号、首尾空白、`inf` / `infinity` / `nan`（大小写不敏感），`int(float("inf"))` 报 `OverflowError`、`int(float("nan"))` 报 `ValueError`
- **`float` 的 repr 丢失精度**：此前用宿主默认格式化，`1/3` 打印为 `0.33333333333333`（14 位）、`0.1 + 0.2` 打印为 `0.3`。现在取「能往返解析的最短十进制」并按 Python 规则在指数 `< -4` 或 `>= 16` 时切到科学计数法，与 CPython 逐位一致
- **字符串与序列拼接的静默错值**：`"s" + 2` 此前静默得到 `"s2"`、`[1] + (2,)` 静默得到 `[1, 2]`。现在按 CPython 类型规则报 `can only concatenate str (not "int") to str` / `can only concatenate list (not "tuple") to list`；序列重复的次数只接受整数，非整数报 `can't multiply sequence by non-int of type 'X'`
- **`None` 单例被污染**：`int()` / `float()` 抛错时返回的 `None` 占位会被类调用流程打上 `klass` 标记，由于 `None` 是全局单例，此后整段脚本的 `type(None).__name__`、`str(None)` 全部错乱（实测为 `int`）。现在类调用不再给 `DSLNone` 打标记
- **操作数的 `last_error` 残留**：被复用的对象（如 `None` 单例）上残留的上一次运算错误会让本次运算的错误文案取自上一次的操作数类型（`1 + None` 报成 `'NoneType' and 'int'`）。现每次运算前清除两侧操作数的错误状态
- **语句尾部的冗余 Token 被静默忽略（P2-2 残留）**：`1 + 2 3`、`x = 1 2`、`return 1 2` 等此前被静默接受并照常执行；现在按 CPython 报 `SyntaxError: invalid syntax`
- **内置异常缺少父类**：`OverflowError` 此前未注册（`except OverflowError` 报 `NameError`），`IndexError` / `KeyError` 也不继承 `LookupError`、`ZeroDivisionError` 不继承 `ArithmeticError`。现在补齐层次：`OverflowError` / `FloatingPointError` 继承 `ArithmeticError`，`IndexError` / `KeyError` 继承 `LookupError`，并新增 `UnboundLocalError` / `RecursionError` / `NotImplementedError` / `OSError` / `MemoryError` / `UnicodeError`
- **反射运算符缺失**：`1 * "ab"`、`2 * [1]` 这类「序列在右」的写法此前报 `TypeError`，现按 CPython 语义回退到右侧的 `__rmul__`（本轮实现重复运算）
- **`set` / `frozenset` 的 `repr` 错误**：`repr({1})` 此前返回 `<set object>`、`repr(frozenset({1}))` 返回 `<frozenset object>`（缺少 `__repr__` 而回退到默认对象表示），现与 `str` 一致分别返回 `{1}` 与 `frozenset({1})`
- **`"..." %` 的参数校验缺失**：`"s" % 1` 此前静默返回 `"s"`；现在按 CPython 校验参数个数（`"s" % ()` 报 `not enough arguments for format string`，`"s" % (1, 2)` 报 `not all arguments converted during string formatting`），并支持 `%(name)s` 命名字段与映射实参（`"%(a)s" % {"a": 1}`），可作映射的下标对象（`list` / `dict` / `bytes` / `range`）按 CPython 规则跳过个数校验
- **`b"..." %` 不支持**：`b"x" % 1` 此前报通用类型错误，现按 CPython 报 `not all arguments converted during bytes formatting`
- **`bool` 的运算结果类型**：`True & True` 等两个 bool 的位运算此前返回整数 `1`，现返回 `True`；`True // 1.5`、`True % 1.5` 等与浮点混合的运算此前返回整数，现返回浮点（与 CPython 一致）

### 变更

- **分号可作语句分隔符**：`x = 1; y = 2` 此前报 `Unexpected character ';'`，现按 CPython 视为换行等价
- **`str` / `list` / `tuple` / `bytes` 的拼接与重复更严格**：跨类型拼接不再隐式转换（此前 `"s" + 2`、`[1] + (2,)` 会静默给出结果），依赖该行为的脚本会开始报错
- **整数与浮点的除零文案区分**：`1 / 0` 报 `division by zero`，`1.0 / 0` 报 `float division by zero`，`1 // 0` 报 `integer division or modulo by zero`，`1.0 // 0` 报 `float floor division by zero`，`1 % 0` 报 `integer modulo by zero`，`1.0 % 0` 报 `float modulo`

### 测试

- 新增 5 个行为一致性测试：`lang_sleep_comp_effect`（eager 推导式副作用与取值）/ `lang_numeric_convert`（`int()` / `float()` 严格解析、float repr、真值算术、运算符文案）/ `lang_seq_concat`（序列拼接与重复类型规则）/ `lang_operators`（反射运算符与除零文案）/ `lang_exc_hierarchy`（异常继承与捕获后状态隔离），并入 `expected.json`（共 158 个用例全部通过），挂起测试 22 个用例通过

## [0.5.0-alpha.4] - 2026-09-23

本版修复 `[0.5.0-alpha.3]` 记录的 P1-16 / P1-17 / P1-18 与 P2-2 四项问题

### 修复

- **语句重放时实参被重新构造的调用会重复执行副作用（P1-18 连带）**：`f(C(1))`、`S(1) == S(1)` 这类在实参中构造新实例的调用，重放时会重新求值实参表达式产生新的实例，按对象身份比对的调用帧匹配必然失败，于是函数体被完整重跑一遍——副作用重复执行，返回值也取自新的那次执行。现在在重放轮追加一次按结构（列表/元组/字典逐元素、用户实例逐字段）的宽松匹配，使这类调用能恢复挂起中的那一帧，副作用只执行一次，与 CPython 一致。匹配不调用用户 `__eq__`，避免副作用与递归
- **`range` / `dict` 视图的空实例真值错误（P1-17 同族）**：`bool(range(0))`、`bool({}.keys())`、`bool({}.values())` 此前均为 `True`（空实例应为假），现按 `len != 0` 判定，与 CPython 一致
- **用户类 `__bool__` / `__len__` 不参与真值判断（P1-17）**：`DSLObject._dsl_bool()` 的基类实现此前无条件返回 `true`，定义 `__bool__`（或 `__len__`）的用户实例在 `bool()` / `if` / `while` / `not` / `and` / `or` / 三目 / `any` / `all` 等所有真值语境中恒为真。现在按 CPython 的判定优先级处理：先查用户 `__bool__`，无 `__bool__` 但定义了 `__len__` 时以 `len != 0` 为真，两者都无则保持默认真。相关 dunder 的挂起（内部含 `sleep`）同样会正确传播
- **用户 `__eq__` 内含 `sleep` 时直接比较结果错误（P1-18）**：`S(1) == S(1)` 此前返回 `False`（`in` 路径反而正确）。根因两处并已一并修复 —— `_call_magic_or_fallback` 在用户魔术方法因挂起返回 `null` 后继续回退到基类的引用比较 `magic_eq`，使两个不同实例被判为不等；`Binary` 求值路径也未在结果为空时先判挂起，而是直接报 `RuntimeError: Unknown binary operation error`。现在用户魔术方法内的挂起一律向上传播，交由语句重放机制续跑
- **`yield` 值表达式含嵌套调用时报迭代上限（P1-16）**：`yield s(1)`、`yield f(i) * (yield i)` 之类以用户函数调用作为 `yield` 值（或其子表达式）的生成器，此前会报 `RuntimeError: maximum step count exceeded`。根因是嵌套用户函数调用体内的语句会把当前生成器的 `_yield_pos` 归零，使外层 `yield` 记录到的挂起位置退化为 0（形同未记录）；该语句随即被反复当作「首次产出」重放直至耗尽步数上限。现在嵌套调用被视作相对当前生成器的原子求值，调用前后保存并还原 `_yield_pos`。同一根因也修掉了 `yield from` 与多个生成器交替使用时触达上限的组合（该现象自 alpha.2 起既有）
- **`async` / `await` 误用报 `NameError` 而非 `SyntaxError`（P2-2）**：`await x`、`async for`、`async with`、`async def` 等此前因 `async` / `await` 被当作普通标识符而报 `NameError: name 'async' is not defined`。现在两者为保留关键字，按 CPython 给出对应文案：`'await' outside function`、`'await' outside async function`、`'async for' outside async function`、`'async with' outside async function`、`asynchronous comprehension outside of an asynchronous function`，其余误用报 `invalid syntax`（`async def` 作为既定不实现项，给出明确的 `'async def' is not supported` 降级报错）
- **`return` / `break` / `continue` 出现在非法位置时被静默忽略（P2-2 同族）**：模块层 `return`、循环外 `break` / `continue` 此前不报错也不生效。现在按 CPython 报 `SyntaxError: 'return' outside function` / `'break' outside loop` / `'continue' not properly in loop`，且类体是独立作用域（外层循环不使其中的 `break` 合法）

### 变更

- **`async` / `await` 成为保留关键字**：两者不能再作变量名/函数名等标识符使用（此前可当普通标识符用）。与 v0.4.0 将 `yield` 设为保留关键字同理，若旧代码以 `async` / `await` 命名变量需改名

### 测试

- 新增 3 个行为一致性测试：`lang_object_truth`（`__bool__` / `__len__` 真值判定与内置类型回归护栏）/ `lang_sleep_dunder`（魔术方法内含 `sleep` 的比较与真值）/ `lang_yield_nested_call`（`yield` 值表达式含嵌套调用、`yield from` 与多生成器交替），并入 `expected.json`（共 153 个用例全部通过），挂起测试 22 个用例通过
- 新增 8 个解析期语法错误测试：`err_await_outside` / `err_await_async_fn` / `err_async_for` / `err_async_with` / `err_async_name` / `err_return_outside` / `err_break_outside` / `err_continue_outside`，逐一与 CPython 的 `SyntaxError` 文案比对一致

## [0.5.0-alpha.3] - 2026-09-23

本版实现 P1 系列问题（除 `with` / 用户文件 `import` / `async` 等既定范围外）的修复

### 新增

- **`bytes` 独立类型**：新增 `DSLBytes` 与 `b"..."` / `rb"..."` 字面量，`type(x).__name__` 为 `bytes`；索引与迭代产出整数（`b"xy"[0] == 120`）、`len` 为字节数、支持切片、`b"a" * 3` 重复、`in` 支持单个字节与子串；repr 形如 b'xy'（不可打印字节转义为 \xNN 形式）；与 `str` 严格区分（`b"a" == "a"` 为 `False`，拼接报 `can't concat str to bytes`）
- **`range` 为独立惰性类型**：新增 `DSLRange`，只保存 `start` / `stop` / `step` 按需求值，`len(range(1000000))` 等大范围无需展开；`type(x).__name__` 为 `range`；支持负索引、`[start:stop:step]` 切片（返回新 range）、成员判定（等差求解）、`reversed()` 与全部消费函数；不可变（赋值与删除分别报 CPython 原文，两处措辞不同）
- **用户类迭代协议**：定义 `__iter__` / `__next__` 的类现可被 `for` / `list()` / `sum()` / `sorted()` / `max()` / `enumerate()` / `in` 等全部消费路径迭代；`__iter__` 返回 `self`、返回生成器函数调用结果、或对象自身实现 `__next__` 三种写法均支持；`__next__` 抛 `StopIteration` 视为正常耗尽
- **多重赋值目标**：`a[0], a[2] = a[2], a[0]` 之类的下标目标与 `o.x, o.y = 1, 2` 之类的属性目标现可作赋值目标（此前报 `Invalid assignment target`）；支持链式后缀（如 `self.data[k] = v`）与单一目标退化路径

### 修复

- **用户类 `__eq__` 未参与容器操作**：`x in [a, b]`、`list.remove` / `index` / `count` 等此前直接按对象身份比较，未定义 `__ne__` 时还会因查找该魔术方法而报 `AttributeError`；现在容器的相等判定统一优先调用用户 `__eq__`，`!=` 按 CPython 语义回退为 `not __eq__`
- **用户类 `__hash__` 无法用于字典键 / 集合元素**：此前一律报 `TypeError: unhashable type`；现在定义了 `__hash__` 的实例可作键与集合元素（按「哈希 + 相等」判定），定义了 `__eq__` 但未定义 `__hash__` 时按 CPython 规则仍不可哈希，两者都未定义时按身份哈希；元组与 `frozenset` 也可作键
- **`dict.keys()` / `dict.values()` 不支持迭代与 `len()`**：`len(d.keys())` 此前报 `TypeError`、`list(d.values())` 返回空列表；现在两者均可迭代、有 `len`、支持 `in` 成员判定，`repr` 与 `type()` 名称也与 CPython 一致（新增 `dict_keys` / `dict_values` 类型类）
- **`yield from` 不转发 `send` / `throw`**：实现了 PEP 380 的委托语义——`send` 值送达子生成器挂起点、`throw` 的异常由子生成器内 `try/except` 优先捕获，子生成器的 `return` 值经 `yield from` 表达式传出
- **`yield` 恢复期重复求值前缀子表达式**：语句因 `yield` 挂起后会被重新执行，此前挂起点之前的子表达式（如 `f(a(), (yield 1))` 中的 `a()`、`side() + (yield 1)` 中的 `side()`）会重复求值导致副作用执行两次；现在按「节点 + 出现次序」记忆已求值结果，重放轮直接复用。记忆仅在语句自身含 `yield` 时启用，与 `sleep` 的语句重放机制相互隔离
- **空字面量被误判为三引号**：`b""` / `""` 这类空字面量此前因只检查前两个引号而被当作三引号起始，报 `Unterminated triple-quoted string`；现改为要求连续三个引号

### 变更

- **`range()` 返回值类型变化**：此前返回列表（带 `is_range` 标记），现返回独立的 `DSLRange` 惰性对象。`list(range(n))` / 索引 / 切片 / 迭代等用法不变，但 `range(3) == [0, 1, 2]` 现在为 `False`（与 CPython 一致），`repr(range(3))` 为 `range(0, 3)`
- **`bytes` 字面量类型变化**：`b"..."` 此前被解析为 `str`，现为独立的 `bytes` 类型；`b"xy"[0]` 现在返回整数 `120` 而非字符形式

### 测试

- 新增 3 个行为一致性测试：`lang_types2`（`bytes` / `range` / `dict` 视图）/ `lang_object_proto`（`__eq__` / `__hash__` / 迭代协议 / 多重赋值目标）/ `lang_yield_delegate`（`yield from` 完整委托与 `yield` 恢复期记忆），并入 `expected.json`（共 142 个用例全部通过），挂起测试 22 个用例通过

## [0.5.0-alpha.2] - 2026-09-23

本版修复 `[0.5.0-alpha.1]` 记录的 P0 问题：表达式级消费含 `sleep` 的生成器时会重复执行生成器体内的副作用

### 修复

- **表达式级消费含 `sleep` 的生成器时重复执行副作用（P0）**：`print(list(g()))` / `sum(g())` / `sorted(g())` / `max(g())` / `tuple(g())` / `[x for x in g()]` / `list(x * 2 for x in g())` 等所有表达式级消费路径此前会在语句重放时重新创建生成器对象，导致生成器体从头再执行一遍：副作用重复、依赖被修改状态的元素值出错、真实等待次数偏少。根因两处并已一并修复 —— `Call` 求值在分派前清空 `_current_call_node` 使生成器记忆形同虚设；`_clear_gen_memo` 在内层语句完成时按根语句键清空记忆。现在生成器对象在重放时被正确复用，副作用只执行一次、元素值与真实等待次数均与 CPython 一致
- **`for` 语句的迭代器误入消费窗口**：`for` 循环的进度由 `resume_info` 保存的迭代器对象维护，此前它同时参与语句级消费窗口，重放时游标被退回窗口起点，使已交付的元素被再次产出（`for v in k():` 中 `k` 体内含 `sleep` 时首元素重复）。现令其不参与消费窗口
- **生成器体内的 `sleep` 被重放序号错误跳过**：生成器对象复用时其进度由自身挂起状态保证，每个 `sleep` 都是首次遇到；此前仍按语句级去重序号跳过，导致后续元素的等待被吃掉（2 个元素只等 1 次）。现在生成器步内部的 `sleep` 一律真正等待
- **`next()` 重放时重复交付同一元素**：语句重放会把读取游标退回窗口起点，但 `next()` 是消费语义，重放时应从已确认取走的位置继续驱动（新增 `_hi_pos` 高水位），而不是把交付过的值再交付一次
- **生成器表达式的子句迭代器参与外层消费窗口**：其进度由帧栈保存，此前同时叠加外层窗口，重放时会把同一元素重复产出（`tuple(g(x) for x in range(3))` 得 `(1, 2)` 而非 `(0, 1, 2)`）。现令其不参与窗口
- **生成器记忆未区分父生成器实例**：记忆键现带上当前正在执行的生成器标识，使 `[[y for y in b()] for _ in range(2)]` 这类「外层重启后重新创建内层生成器」的场景能取到新实例，而不是复用上轮已耗尽的生成器
- **`for` 循环体挂起标记误置**：`body_resume` 此前在进入循环体前即置为 true，在迭代器推进处挂起时重放会重跑上一轮的循环体；现仅当循环体自身确实挂起时才置位

### 测试

- 新增 `lang_sleep_sideeffect`：覆盖 `list` / `sum` / `sorted` / `max` / `tuple` / 推导式 / 生成器表达式 / `for` / 嵌套生成器 / 嵌套推导式 / 闭包工厂 / `islice` / 多轮消费共 14 组副作用与取值断言（共 139 个用例全部通过），挂起测试 22 个用例通过
- 另有 5 项 `alpha.1` 的既有行为（`next()` 消费、生成器内 sleep 计数、推导式内迭代器、外层推导式重启、`for` 循环重放）在本版一并回归通过

### 变更

- **测试运行器 `test.gd` 改为通过实例属性访问状态枚举**：`PyGDS.State.SUSPENDED_SLEEPING` / `PyGDS.State.RUNNING` 改为 `dsl.State.*`。CI 环境无法读取编辑器生成的全局类缓存（`PyGDS` 全局注册不可用），改用实例属性访问后仅依赖 `load("res://pygds.gd")` 的返回值即可解析；此做法与 `demo/test_suspend_all.gd` 通过 `preload` 常量访问 `PYGDS_SCRIPT.State` 的既有约定一致。同时把挂起恢复次数的告警阈值由 64 校准为 2000，与循环上限及告警文案保持一致（此前阈值为 64 而文案写 2000，且正常用例的恢复轮数可能超过 64 而误报）

## [0.5.0-alpha.1] - 2026-09-23

### 新增

- **`time` 模块**：新增内置 `time` 模块，提供 `sleep` / `time` / `time_ns` / `monotonic` / `monotonic_ns` / `perf_counter` / `perf_counter_ns`；`time.sleep(n)` 为协作式挂起（挂起期间宿主继续运行，不阻塞游戏），返回值与 CPython 一致为 `None`，参数错误信息也对齐 CPython（`TypeError: 'str' object cannot be interpreted as an integer` / `ValueError: sleep length must be non-negative`）
- **生成器/推导式内的 `sleep` 支持**：此前「生成器体内 `sleep()` 报错」与「推导式/生成器表达式内 `sleep()` 静默给出错值或死循环」的问题一并解决；现在 `[time.sleep(0) for x in range(3)]`、`[x for x in it if time.sleep(0)]`、`[f(x) for x in it]`（`f` 内含 sleep）、`list(time.sleep(0) for x in range(2))`、`[v for v in (time.sleep(0) for x in range(2))]`、`sum` / `sorted` / `min` / `max` / `any` / `all` / `enumerate` / `zip` / `itertools.islice` 消费含 sleep 的生成器、生成器函数体内 `sleep` 等写法全部按 CPython 语义产出正确结果
- **嵌套生成器内的 `sleep` 支持**：生成器体内再迭代另一个含 `time.sleep()` 的生成器（含多层嵌套、`yield from` 委托、生成器内 genexpr、生成器工厂闭包等组合）此前会明确报错，现按 CPython 语义正确产出。内层迭代器因 `sleep` 挂起时不再被当作「已耗尽」，而是经 `for` 语句向上传播为程序挂起，由语句重放机制接管续跑；`_step()` 中的嵌套守卫与 `_outer_generator` 字段一并移除
- **赋值表达式（walrus）严格规则**：新增两条与 CPython 一致的解析期校验——`assignment expression cannot rebind comprehension iteration variable 'x'`（覆盖列表/集合/字典/生成器推导式，保护名包含本推导式与所有外层推导式的循环目标，跨 `lambda` / `def` 边界不继承）与 `assignment expression cannot be used in a comprehension iterable expression`（推导式可迭代表达式内禁止赋值表达式，与名字无关）
- **`yield` 在推导式内的规则细化**：裸 `yield` 在推导式内报 `SyntaxError: invalid syntax`；括号包裹的 `yield` 按推导式类型报 `'yield' inside list/set/dict comprehension` 或 `'yield' inside generator expression`；最外层子句的可迭代表达式内的 `yield` 属外层生成器函数、合法（此前一律报 `invalid syntax`）

### 破坏性变更 (Breaking Changes)

- **`sleep()` 迁移到 `time` 模块**（v0.4.0 → v0.5.0-alpha.1）：裸 `sleep(n)` 不再存在，需 `import time` 后调用 `time.sleep(n)`；CPython 同样没有内置的裸 `sleep`，此项使两者一致。`demo/demo.gd` 与 `demo/test_suspend_all.gd` 已同步更新

### 修复

- **推导式 / 生成器表达式内 `sleep()` 的挂起支持**：此前 `[sleep(..) for x in ...]` 会重复挂起直至死循环（永不结束），`list(sleep(..) for x in ...)` 静默给出 `[]` 或多余 `None`；现通过「语句重放 + 消费窗口」机制正确推进：一次性迭代器把产出记入日志，语句被挂起后重放时按窗口起点重读已产出元素，从而让原生消费循环（`list` / `sum` / 推导式等）无需感知挂起即可得到正确序列
- **生成器函数体内 `sleep()` 支持**：移除 v0.4.0 的「generator body cannot suspend」报错，改为正确的挂起—恢复（体内 `sleep` 计数按重放轮次去重，保证每次等待只发生一次）
- **递归函数内的 `sleep` 重放**：修复重放时复用调用帧导致的重复执行（如 `def f(n): print(n); sleep(); f(n-1)` 会打印多次 `n`）；调用帧按实参**值**比对（不可变字面量按值、其余按身份），并记录 `return_pc` 时按 `(statements, env)` 双重身份定位，使递归各层帧各自正确恢复
- **`min()` / `max()` 在消费中途挂起时误报空序列**：`has_next()` 返回 false 时区分「确实为空」与「本次挂起中断」，后者交回语句重放而不抛 `ValueError`
- **`for` 循环体挂起后的重放重复推进**：循环内语句因 `sleep` 挂起而重放时，此前会按上一次遗留的 `body_resume` 标记跳过迭代器推进、直接重跑循环体，导致元素被重复产出（如 `for v in b():` 中 `b()` 内含 `sleep` 时同一元素反复输出）；现在在推进迭代器前清除该标记，使「body 恢复」与「迭代器推进」两种情况正确区分
- **`next()` 在生成器消费中途挂起时误抛 `StopIteration`**：`has_next()` 返回 false 时先判 `suspended`，挂起交回语句重放而不是当作迭代结束
- **`operator.indexOf()` 在消费中途挂起时误抛 `ValueError`**：同样区分「确实未找到」与「本次挂起中断」，后者返回 `null` 交回重放
- **字面量 `*` 解包在生成器消费中途挂起时输出多次部分结果**：`[*g()]` / `(*g(),)`（星号元素位于字面量末尾）此前会因 `_append_literal_element` 带着部分元素返回成功，导致语句被视为已完成并反复输出逐步增长的部分列表（`[]` / `[0]` / `[0, 1]` …）；现在循环内检测挂起并返回 false，使表达式返回 `null` 触发语句重放
- **`for` 循环吞掉迭代器抛出的异常**：迭代器推进时抛出异常（如生成器体内 `raise`）会被本语句吞掉；当 `for` 位于 `try` 体内且其后没有别的语句时，外层 `try/except` 无法捕获，错误直接冒泡为未捕获异常。现在 `has_next()` 返回 false 时一并检查 `report.has_error`，把异常向上传播交给 `try` 分发
- **调用表达式抛异常时泄漏半成品值**：`list()` / `tuple()` / 用户类构造等 `DSLClass` 调用在内部抛出异常时，返回的是半成品（如 `[]`、`<C object>`），而 `Call` 求值分支只检查挂起、不检查错误，导致实参求值带着它继续（`print(list(gen))` 会先多输出一行部分列表再抛异常，`print(C())` 会多输出一行对象 repr）；现补上 `report.has_error` 判定，异常原样交给 `try/except`
- **`random` 抽样函数对生成器的拒绝行为对齐 CPython**：`choice` / `choices` / `shuffle` 此前对生成器报 `argument must be a sequence` / `Cannot choose from an empty population`，现统一报 CPython 的 `TypeError: object of type 'generator' has no len()`；`sample` 报 CPython 的 `TypeError: Population must be a sequence.  For dicts or sets, use sorted(d).`。`weights` 参数仅需可迭代，生成器仍被接受（与 CPython 一致）
- **`random.choices` 在人口/权重消费中途挂起时使用半截数据**：`has_next()` 返回 false 时未区分「确实耗尽」与「本次挂起中断」，会拿着不完整的人口或权重继续抽样（权重场景直接误报 `ValueError: The number of weights does not match the population`）；现补上 `suspended` 判定，交回语句重放
- **`KeyError` 的 `str()` / `repr()` / `args` 与 CPython 不一致**：`str(KeyError("k"))` 应为参数的 repr（`'k'`，非字符串参数如 `1` 输出 `1`），无参数时为空串、多参数时为参数元组；`repr(e)` 应为 `KeyError('k')` 形式而非 `<KeyError object>`；`e.args` 应保留原始参数对象。此前内部 `KeyError` 站点一律用 `str` 语义拼消息、异常类也没有 `__repr__`，因此 `KeyError('k')`、`d["missing"]`、`{}.popitem()` 等场景的显示与 `args` 都不对
- **字典/集合方法把错误记在实例上导致异常被静默吞掉**：`dict.popitem()`、`dict.pop(k)`、`set.remove(x)`、`set.pop()` 在失败时把错误写在接收者实例的 `last_error` 上，而 `Call` 求值只检查内置方法原型（proto）的 `last_error`，于是异常既不抛出也不报错，调用静默返回 `None`（如 `print({}.popitem())` 输出 `None`）；现同时检查接收者实例并把原始参数带出，转为对应异常
- **`random` 抽样函数的参数类型规则与 CPython 不一致**：`choice` / `shuffle` 现按 CPython 的「取 `len(seq)` 后按整数下标索引/赋值」语义处理 —— 生成器报 `object of type 'generator' has no len()`，集合报 `'set' object is not subscriptable`，字典按键取（键非 `0..n-1` 时 `KeyError`），`shuffle` 对元组/字符串/`range` 报 `does not support item assignment`，`choice` 支持字符串与 `range`；`sample` 对生成器/集合/字典统一报 `Population must be a sequence.  For dicts or sets, use sorted(d).`。为此给 `range()` 产物加了类型标记，使其类型名与可变性可与列表区分
- **未捕获错误后的宿主状态**：执行中发生未捕获错误时清除挂起标志并记录致命错误，使宿主状态机进入 `ERROR` 终态，不再停留在挂起态被反复恢复（此前会无限重跑并重复输出错误）

### 变更

- 兼容性矩阵更新（README.md / README_EN.md）：内置模块行与用户 import 行补 `time`，赋值表达式行补充两条严格规则，挂起系统示例改为 `time.sleep`，并新增 `sleep` 迁移的破坏性变更说明
- 文档（`docs/zh-CN` 与 `docs/en`）：`architecture.md` 补充赋值表达式校验与生成器挂起重放机制，`builtin.md` 新增 `time` 模块章节与抽样函数的参数类型规则说明，`usage.md` 补充 `time` 模块用法与 walrus 严格规则说明，`exception_system.md` 补充 `str` / `repr` / `args` 取值规则；`sleep` 在嵌套生成器内的已知差异条目已在完成支持后删除并改写为「已支持」

### 已知问题

- **表达式级消费含 `sleep` 的生成器时会重复执行生成器体内的副作用**（已在 [0.5.0-alpha.3] 修复）：把含 `time.sleep()` 的生成器直接放进**表达式**里消费时（`print(list(g()))`、`sum(g())`、`sorted(g())`、`max(g())`、`tuple(g())`、`[x for x in g()]`、`list(x * 2 for x in g())` 等，凡不是 `for` 语句的形式），该语句因 `sleep` 挂起后会被整体重放，而重放时生成器对象被**重新创建**而非复用，于是生成器体从头再执行一遍：
  - 生成器体内的副作用（`append`、`print`、累加等）会被执行多次。例如 `log=[]; def a(): for i in range(2): log.append(i); time.sleep(0); yield i` 后 `list(a())`，CPython 得到 `log == [0, 1]`，PyGDS 得到 `log == [0, 0, 1, 0, 1]`
  - 若产出的值依赖被修改的状态（如 `n += 1; yield n`），**元素值本身也会出错**：CPython `[1, 2]`，PyGDS `[4, 5]`
  - 真实等待次数同样偏少（2 个元素只等 1 次）
  - 受影响范围：`for` 语句消费是正确的（迭代器经 `resume_info` 复用），只有表达式级消费受影响；不含 `sleep` 的生成器不受影响
  - 根因有两处且相互叠加：`Call` 求值在分派前清空 `_current_call_node`，使 `call_user_function` 里的生成器记忆（`_memo_generator`）始终收到 `null` 而形同虚设；同时 `_clear_gen_memo` / `_clear_stmt_window` 在重放根语句期间会被内层语句触发的清理逻辑按根语句键清空。两处都属于「语句重放 + 消费窗口」的核心区域，为便于回退与独立验证，留待下一版专门处理（已在 [0.5.0-alpha.3] 修复）

### 测试

- 新增 8 个行为一致性测试：`lang_time`（time 模块与参数校验）/ `lang_sleep_lazy`（推导式、生成器表达式、生成器函数与各消费函数内的 sleep）/ `lang_sleep_nested`（嵌套生成器内的 sleep、多层嵌套、`yield from`、genexpr、`send`、闭包工厂、异常传播，以及 `next()` / `operator.indexOf()` / 字面量 `*` 解包三处消费点）/ `lang_gen_error`（调用表达式抛异常时不再泄漏半成品值）/ `lang_exc_str`（异常的 str / repr / args 语义）/ `lang_random_gen`（抽样函数的参数类型规则与 weights 挂起重放）/ `err_walrus_rebind` / `err_walrus_comp_iter` / `err_yield_paren_comp`（共 138 个用例全部通过），挂起测试 22 个用例通过

## [0.4.0] - 2026-09-22

### 新增

- **`yield` 生成器函数（Python 3.3+）**：新增 `YIELD` 令牌、`yield` 关键字与 `YieldExpr` AST 节点；`def` 内含 `yield` 的函数在**定义时**由解析器递归检测标记为生成器（跳过嵌套 `def` / lambda / 推导式作用域），调用时**不执行函数体**、立即返回惰性 `generator` 对象（`<class 'generator'>`）；局部变量跨 `yield` 保持，闭包变量正常可见，耗尽后再次迭代直接结束（一次性语义）
- **语句级与表达式级 `yield`**：`yield` / `yield expr` 独立语句，以及 `x = yield v`、`return (yield 1)`、`f(1 + (yield 2))` 等任意表达式位置（恢复时注入 `send` 值参与后续求值，与 CPython 语义一致）；新增 `DSLFunctionGenerator`（持有闭包/参数绑定环境与挂起时保存的解释器执行栈）与 `DSLFunctionGeneratorIterator`（预取缓冲），通过「栈切换」机制让解释器的 `environment` / `_exec_stack` / `_call_stack` / `_current_class` / `_current_self` 在多份生成器挂起状态间切换，天然支持多生成器交替与嵌套
- **`yield from iterable` 委托**：把子可迭代对象的元素逐个产出，耗尽后表达式的值为子生成器的 `return` 值；子迭代器状态按 `YieldExpr` 节点保存在生成器上，支持嵌套 `yield from`、`yield from` 无限生成器（配合 `itertools.islice`）；`send` / `throw` 不转发给子生成器（PEP 380 完整委托超出本期范围），`x = yield from it` 赋值形式暂不支持
- **`send(value)` / `throw(type)` / `close()`**：`send` 把值注入为挂起 `yield` 表达式的结果（`send(None)` 可启动生成器，`send(非 None)` 到未启动生成器报 `TypeError`）；`throw` 在挂起位置抛出异常（未启动生成器在函数体开头注入抛出语句），可被生成器体内的 `try/except` 捕获；`close()` 注入 `GeneratorExit`（新增异常类，继承 `BaseException`、不被 `except Exception` 捕获），`finally` 正常执行，生成器捕获后继续产出时抛 `RuntimeError: generator ignored GeneratorExit`
- **`StopIteration.value`**：生成器 `return value` 时，`next()` 超出抛出的 `StopIteration` 携带 `value`（`return` 无值时为 `None`），`try/except StopIteration as e` 中 `e.value` 可读取；新增 `raise_stop_iteration_value` 与 `raise_existing_exception` 辅助
- **生成器方法 / lambda 生成器**：类内 `def` 含 `yield` 生成器方法（`self` 绑定可用），lambda 体内直接含 `yield` 生成 lambda 生成器（Python 3.12 语义，`lambda: (yield v)` 合法）
- **消费链路贯通**：`next()` / `for` / `list` / `tuple` / `sum` / `sorted` / `min` / `max` / `any` / `all` / `enumerate` / `zip` / `itertools.islice` 等统一通过 `_dsl_iter()` 消费函数生成器（与生成器表达式共用协议）
- **报错边界（对标 CPython 3.12）**：`yield` 在函数外报 `SyntaxError: 'yield' outside function`；在推导式内直接 `yield` 报 `SyntaxError: invalid syntax`（dict 推导式为 `'yield' inside dict comprehension`）；嵌套 lambda / 推导式内的 `yield` 属于其自身作用域，不计入外层函数

### 破坏性变更 (Breaking Changes)

- **`yield` 成为保留关键字**（v0.3.0 → v0.4.0）：此前 `yield` 不在 `Lexer.keywords` 表中、可当普通标识符使用；现为关键字，不能再作变量名/函数名/属性名等标识符，旧代码需改名

### 修复

- **for 循环体恢复语义**：`exec_block` 的帧查找按语句数组与环境的「值+身份」匹配；此前 `ForStmt` 恢复时丢弃残留的 body 帧并从 pc 0 重启，导致「for 体内 `sleep()` 之后同一迭代的语句被跳过」（如 `for i in range(3): print('a', i); sleep(0.1); print('b', i)` 丢失 `b` 行）。现改为恢复时**先不推进迭代器**（`resume_info` 记录 `body_resume`），从保存的 pc 继续被挂起的 body，完成后再推进下一迭代；`for` / `while` 循环体、`for-else` / `while-else`、`try/except/finally` 各分支的恢复统一按挂起阶段路由
- **`TryStmt` 恢复路由**：此前 except / finally 体内挂起后恢复会重跑 try 体（对 `yield` 表现为重产出 try 体内元素）；现 `resume_info` 记录挂起发生在 try / except / finally 的哪个阶段，恢复时直接继续对应分支
- **for-else / while-else 挂起传播**：此前 else 体 `exec_block` 的结果被丢弃，else 体内 `sleep()` / `yield` 挂起被忽略；现传播挂起结果并在恢复时按 `else_env` 继续
- **`send(None)` 破坏 `is None` 身份语义**：生成器注入的 `send` 值此前用 `DSLNone.new()` 每次新建实例，导致 `received is not None` 误判为真（`send(None)` 与 `next()` 的注入值应复用解释器的 None 单例）；现统一经 `_none()` 取缓存单例，`x is None` / `x is not None` 判定恢复正确

### 变更

- 兼容性矩阵更新（README.md / README_EN.md）：生成器/`yield` 行 ❌ 不支持 → ✅ 完整，并新增 `yield` 关键字破坏性变更与生成器已知差异说明
- 文档（`docs/zh-CN` 与 `docs/en`）：`architecture.md` 补充 `YIELD` 令牌、`YieldExpr` 节点与生成器栈切换机制，`builtin_types.md` 补充生成器函数类型与 `send`/`throw`/`close` 方法，`usage.md` 补充生成器函数用法（含 `yield from`、表达式级 `yield`、`StopIteration.value` 与报错边界）

### 测试

- 新增 6 个行为一致性测试：`lang_yield` / `lang_yield_control`（send/yield from/throw/close）/ `lang_yield_consumers`（消费链路）/ `lang_yield_lambda`（生成器 lambda）/ `edge_yield_errprop` / `edge_yield_closure` / `edge_yield_controlflow` / `err_yield_outside` / `err_yield_listcomp` / `err_yield_dictcomp`（共 129 个用例全部通过），挂起测试 22 个用例通过

## [0.3.0] - 2026-09-21

### 新增

- **惰性生成器表达式**：`(x*x for x in iterable [if cond])` 现在求值为真正的惰性生成器对象（`<class 'generator'>`），而非急切求值的列表；支持 `next()` 逐次推进、一次性迭代语义，以及裸写法 `sum(x*x for x in ...)` / `list(x for x in ...)` 作为函数位置参数
- **生成器与迭代器体系贯通**：新增 `DSLGenerator` / `DSLGeneratorIterator`（预取缓冲保证 `has_next()` 准确）；`list`/`tuple`/`sum`/`sorted`/`any`/`all`/`enumerate`/`zip`/`min`/`max`/`next` 等消费函数统一通过 `_dsl_iter()` 接受任意可迭代对象（含生成器与 `itertools` 无限对象）
- **`slice` 对象与构造函数**：`slice(stop)` / `slice(start, stop)` / `slice(start, stop, step)`，支持 `start`/`stop`/`step` 属性、`isinstance(s, slice)`、负步长，以及 `lst[slice(...)]` / `"str"[slice(...)]` 索引复用
- **字面量 `*` 解包**（Python 3.5+）：`[*a, *b]` / `[1, *mid, 2]` / `(*a,)` / `{*a, 1}`；新增 `StarredExpr` AST 节点，列表/元组/集合字面量求值时展开任意可迭代对象；`(*a)` 缺少逗号时报 `SyntaxError`（与 Python 一致）
- **多 `for` 推导式**：推导式 AST 从单 `for` 子句扩展为 `CompClause` 子句数组，支持 `[x*y for x in a for y in b]`、每个 `for` 带多个 `if`、`k, v` 元组目标，列表/字典/集合推导式与生成器表达式全部覆盖；生成器迭代器改用帧栈保存每层子句的迭代器与绑定快照，保持惰性
- **`itertools` 补全**：`accumulate`（前缀累积，含 `initial`）、`pairwise`（相邻对，Python 3.10+）、`groupby`（相邻分组，返回 `[(key, [元素...])]`）、`starmap`（解包调用）
- **`functools.cmp_to_key`**：把旧式 `cmp(a, b)` 函数包装为可用于 `key=` 的 key 工厂；新增 `DSLCmpKey` 包装对象并实现比较魔法方法，`sorted` / `list.sort` 均可使用
- **`operator` 模块**：新增模块，提供 `add`/`sub`/`mul`/`truediv`/`floordiv`/`mod`/`pow`/`neg`/`pos`/`abs`、位运算、比较与逻辑函数、`getitem`/`setitem`/`delitem`/`contains`/`concat`/`countOf`/`indexOf`/`length_hint`，以及 `itemgetter`/`attrgetter` 取值器（新增 `DSLItemGetter` / `DSLAttrGetter` 可调用对象）；二元/一元函数复用表达式求值的 dunder 分派路径，自定义类的 `__add__` 等同样生效
- **`random.choices` / `random.gauss`**：`choices(population, weights=None, k=1)` 有放回加权抽样（基于现有 xorshift32 PRNG）、`gauss(mu=0.0, sigma=1.0)` 正态分布采样（Box-Muller 变换）
- **`math` / `statistics` 补全**：`math.remainder(x, y)`（IEEE 754 余数，商取最近偶数）、`math.cbrt(x)`（立方根，支持负数）、`statistics.quantiles(data, n=4)`（exclusive 分位数切点）；新增内置异常类 `StatisticsError`（继承 `ValueError`，与 CPython 一致），并作为 `statistics.StatisticsError` 暴露给模块成员
- **可调用对象判定统一**：新增 `DSLObject._dsl_is_callable()`，`callable()` 与 `sorted(key=)` / `list.sort(key=)` 共用同一判定，使 `itemgetter` / `attrgetter` 等取值器可直接作为 key 传入
- **赋值表达式 `:=`（walrus，Python 3.8+）**：新增 `COLON_EQ` 令牌与 `WalrusExpr` AST 节点，`x := 1` 先赋值再以该值参与运算；支持 `if (n := len(a)) > 5:`、`while chunk := read():`、实参/容器字面量/三元表达式/默认参数/`assert`/生成器表达式等表达式位置；推导式内绑定到外层作用域（与 Python 一致）；目标必须是简单变量名，`(obj.attr := 1)` / `(lst[0] := 1)` / 裸写 `x := 1` / `del (x := 1)` 均按 CPython 的报错信息拒绝

### 破坏性变更 (Breaking Changes)

- **生成器表达式语义变更**（v0.2.0 → v0.3.0）：此前 `(x for x in iterable)` 被当作列表推导式急切求值为 `list`；现改为真正的惰性生成器对象。依赖旧行为的代码（如对生成器表达式结果直接下标 `g[0]`、`len(g)`、调用 `list` 方法）会报错，需改为 `list(g)` / `tuple(g)` 后使用；生成器为**一次性迭代器**，重复迭代不会从头开始

### 修复

- **连续 `if` 语句跳过条件求值**：`exec_block` 中语句的 `resume_info` 在语句正常结束后未清空，导致「真值 `if` 之后的 `if`」直接执行其 then 分支而不求值条件（中间隔着其他语句时同样触发）。现在每条语句正常结束后清空当前帧的 `resume_info`，它只在语句被挂起后重新进入时保留；新增 `edge_consecutive_if` 回归测试覆盖该场景

### 变更

- 兼容性矩阵更新（README.md / README_EN.md）：生成器表达式 ⚠️ 部分 → ✅ 完整，新增 `slice`、多 `for` 推导式、字面量 `*` 解包、赋值表达式 `:=` 行；内置模块行补齐新增函数与 `operator` 模块
- 文档（`docs/zh-CN` 与 `docs/en`）：`architecture.md` 修正推导式 AST 字段并补齐 `GenComp`/`SetComp`/`WalrusExpr`/`StarredExpr`/`CompClause` 与 `COLON_EQ` 令牌，`builtin_types.md` 新增生成器与 `slice` 类型（含类型总览表），`usage.md` 补充生成器表达式（含破坏性变更说明）、`slice` 用法、字面量 `*` 解包、多 `for` 推导式与赋值表达式 `:=`，`builtin.md` 补齐各模块新增函数与 `operator` 模块
- 代码规范（全部 `.gd` 文件）：文档注释的 `[br]` 统一为「下一行仍为文档注释时才使用」，`pygds.gd` 删除 68 处多余 `[br]`、补齐 3 处缺失，`demo/demo.gd` 与 `demo/test_suspend_all.gd` 的头部注释块补齐 7 处与 1 处，`addons/pygds/plugin.gd` 补齐 1 处；另删除 `_collect_nums` 处重复的文档注释块

### 测试

- 新增 15 个行为一致性测试：`lang_generator` / `lang_slice` / `lang_unpack_star` / `lang_comp_multi` / `lang_itertools3` / `lang_functools2` / `lang_operator` / `lang_random2` / `lang_math3` / `lang_walrus` / `edge_consecutive_if` / `err_walrus_bare` / `err_walrus_attr` / `err_walrus_subscript` / `err_walrus_del`（共 119 个用例全部通过），挂起测试 22 个用例通过

## [0.2.0] - 2026-09-21

### 新增

- **内置模块**：`import` / `from-import` 语法（含别名与 `*` 导入），提供 `math`（常数、基础/对数/三角函数、角度、整数、符号、判定）与 `random`（``seed``/``random``/``uniform``/``randint``/``randrange``/``choice``/``shuffle``/``sample``）模块
- **内置模块扩展**：`statistics`（``mean``/``median``/``mode``/``stdev``/``pstdev``/``variance``/``pvariance``）、`functools`（`reduce`/`partial`）、`itertools` 常用子集（`chain`/`product`/`combinations`/`permutations`/`islice`）、`collections`（`Counter`/`defaultdict`）、`string` 字符串常量（`ascii_letters`/`digits`/`punctuation`/`whitespace`/`printable` 等）
- **`itertools` 扩展**：`repeat`/`cycle`/`count`（无限对象，惰性配合 `islice`/`takewhile` 消费）、`zip_longest`/`takewhile`/`dropwhile`；`islice` 改为惰性消费，可作用于无限迭代器
- **`math` 扩展**：`comb`/`perm`/`prod`/`lcm`
- **`Counter.most_common(n=None)`**：按出现次数降序返回 `[(元素, 次数)]`，同次数按插入顺序
- **字典合并与解包**：`d1 | d2` / `d1 |= d2` / `{**a, **b}`（Python 3.9+，右侧覆盖左侧同键）
- **`dict.fromkeys`** 与 **`int(str, base)`** 进制解析（`base=0` 按 `0x`/`0o`/`0b` 前缀自动识别）
- **调用处 `*`/`**` 解包**：`f(*args)` / `f(**kwargs)`，支持位置/关键字与解包的任意混合
- **数字字面量**：十六进制 `0x`、八进制 `0o`、二进制 `0b`、下划线分隔 `1_000_000`、科学计数法 `1e5` / `2.5e-2`
- **`set` 类型**：集合字面量 `{1, 2}`、`set()` 构造、集合运算（`| & - ^` 与 `== != < <= > >=`）、方法（`add/``remove`/`discard`/`pop`/`clear`/`copy`/`union`/`intersection`/`difference`/`symmetric_difference`/`issubset`/`issuperset`/`isdisjoint`）、成员检查与迭代
- **集合推导式**：`{x*x for x in iterable [if cond]}`，自动去重
- **`frozenset` 类型**：不可变集合，可哈希（可作为 `set` 元素 / `dict` 键），支持集合运算、比较与 `union`/`intersection`/`difference`/`symmetric_difference` 等只读方法
- **`str` `%` 格式化**：printf 风格（`%s %r %d %i %u %f %e %g %x %X %o %c %%`，标志/宽度/精度）
- **`str.format` 格式说明符**：支持位置/关键字参数与完整说明符（对齐、填充、符号、零填充、宽度、千分位、精度、类型 `d f e g s x X o b c %`）及转换标志 `!r`/`!s`/`!a`
- **f-string 增强**：`=` 调试说明符（`f"{x=}"`，可叠加转换标志与格式说明符）与嵌套格式宽度/精度（`f"{x:{w}d}"`）
- **新增 `str` 方法**：`splitlines` / `removeprefix` / `removesuffix` / `partition` / `rpartition` / `isdecimal` / `isnumeric` / `isprintable` / `isascii` / `isidentifier` / `expandtabs` / `rfind` / `rindex`
- **`str` 方法增强**：`find` / `index` / `count` 支持 `start`/`end`，`replace` 支持 `count`；字符串支持 `in` 成员检查；`sorted()` 支持任意可迭代对象（含 `set`）
- 容器字符串表示按 Python repr 转义特殊字符（`\n`/`\t`/`\\`/`'` 等）

### 变更

- 兼容性矩阵更新（README.md / README_EN.md）：数字字面量、`*`/`**` 解包、`%` 格式化、`str.format`、内置模块、`set`、`frozenset`、集合推导式均置为 ✅；`import` 区分为「内置模块 ✅ / 用户文件 ❌」
- 文档（`docs/zh-CN` 与 `docs/en`）：`builtin.md` 新增内置模块章节（含扩展模块），`builtin_types.md` 新增 `set`/`frozenset` 类型与集合推导式、更新 `str.format` 说明，`usage.md` 补充数字字面量 / `%` 格式化 / `str.format` / `*`/`**` 解包 / `import` / f-string 增强
- 测试生成器 `py_package/test.py`：规范化对象 repr（去除 Python 内存地址），保证 `expected.json` 可复现

### 测试

- 新增 22 个行为一致性测试：`lang_import` / `lang_math` / `lang_random` / `lang_unpack` / `lang_numbers` / `lang_set` / `lang_percent` / `lang_str_methods` / `lang_statistics` / `lang_functools` / `lang_itertools` / `lang_collections` / `lang_string_module` / `lang_frozenset` / `lang_setcomp` / `lang_fstring2` / `lang_format` / `lang_dict_merge` / `lang_itertools2` / `lang_math2` / `lang_counter` / `lang_int_base`（共 104 个用例全部通过）

## [0.1.1] - 2026-09-20

### 修复

- 修复 `demo/test_suspend_all.gd` 与 `demo/demo.gd` 对全局类名 `PyGDS` 的依赖：改用 `const PYGDS_SCRIPT = preload("res://pygds.gd")` 引用解释器脚本，使类型注解与 `State` 枚举访问不依赖编辑器生成的全局类缓存（`.godot/global_script_class_cache.cfg`）
- 修复全新 clone（无全局类缓存）下 `--script` 运行挂起测试报 `Could not find type "PyGDS"` 的问题，CI 挂起测试步骤现可正常通过

## [0.1.0] - 2026-09-20

首个正式发布版本。

### 新增

- **Python 3.x 子集解释器**（Lexer → Parser → AST → Interpreter，单文件 `pygds.gd`）
- 内置类型：`int` / `float` / `str` / `list` / `tuple` / `dict` / `bool` / `None`
- 内置函数：`print` / `len` / `range` / `type` / `id` / `repr` / `hash` / `abs` / `min` / `max` / `sum` / `pow` / `divmod` / `sorted` / `reversed` / `enumerate` / `iter` / `next` / `zip` / `any` / `all` / `ord` / `chr` / `hex` / `oct` / `bin` / `isinstance` / `issubclass` / `callable` / `input` 等
- 类系统：继承、方法覆写、`@staticmethod` / `@classmethod` / `@property`、描述符协议、魔法方法
- 异常系统：`try` / `except` / `else` / `finally` / `raise`，自定义异常类
- 方法类型系统：六种方法类型严格对标 CPython
- 挂起系统：SLEEPING（`sleep(n)` 自动恢复）与 WAITING（外部手动恢复）
- API 注册：`register_api` / `register_api_pair`
- 预设代码：`set_preset_script`
- **f-string 字符串插值**：替换字段内支持任意表达式；格式说明符（对齐、填充、符号、零填充、宽度、千分位、精度，类型 `d f e g s x X o b c %`）与转换标志 `!r` / `!s` / `!a`
- **lambda 匿名函数**：支持默认参数、`*args`、`**kwargs`、仅关键字参数与闭包
- **`super()` 父类调用**：零参数与双参数 `super(Class, obj)`
- **反射内置函数**：`getattr` / `setattr` / `delattr`
- **函数式内置函数**：`map` / `filter`
- **运行时错误行号定位**：未捕获异常的错误消息附加 `(line N)`
- **GitHub Actions CI**：自动运行 Godot headless 行为测试与挂起系统测试
- **MIT 许可证** 与 **Godot 编辑器插件**（`addons/pygds/`，提供运行 `.py` 脚本的菜单工具）
- 行为一致性测试套件（`py_package/tests` + `expected.json`）与挂起系统专项测试
- Demo 场景（`demo/`，回合制战斗挂起演示）

### 变更

- 兼容性矩阵补充新特性条目（README.md / README_EN.md）
- README 新增「安装与集成」「常见问题 FAQ」章节，行为测试章节补充 expected.json 再生成流程
- 文档：`docs/zh-CN` 与 `docs/en` 的 `builtin.md` / `usage.md` / `architecture.md` 补充新特性
- `.gitignore`：`tests` 规则改为根锚定 `/tests/`，避免误忽略 `py_package/tests` 测试套件
- `project.godot`：启用 `addons/pygds/` 编辑器插件

### 测试

- 82 个行为一致性用例全部通过（含新增 `lang_fstring` / `lang_lambda` / `lang_super` / `lang_getattr` / `lang_map_filter`）
- 挂起系统 22 个用例全部通过
