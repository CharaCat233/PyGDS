# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

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

- 修复 `demo/test_suspend_all.gd` 与 `demo/demo.gd` 对全局类名 `PyGDS` 的依赖：
  改用 `const PYGDS_SCRIPT = preload("res://pygds.gd")` 引用解释器脚本，
  使类型注解与 `State` 枚举访问不依赖编辑器生成的全局类缓存
  （`.godot/global_script_class_cache.cfg`）
- 修复全新 clone（无全局类缓存）下 `--script` 运行挂起测试报
  `Could not find type "PyGDS"` 的问题，CI 挂起测试步骤现可正常通过

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
