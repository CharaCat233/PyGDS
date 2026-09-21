# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

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

- 新增 10 个行为一致性测试：`lang_yield` / `lang_yield_control`（send/yield from/throw/close）/ `lang_yield_consumers`（消费链路）/ `lang_yield_lambda`（生成器 lambda）/ `edge_yield_errprop` / `edge_yield_closure` / `edge_yield_controlflow` / `err_yield_outside` / `err_yield_listcomp` / `err_yield_dictcomp`（共 129 个用例全部通过），挂起测试 22 个用例通过

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
