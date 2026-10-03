# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)

## [Unreleased]

## [0.7.0] - 2026-10-03

v0.7.0 正式版。自 v0.6.0 以来的主线：行为一致性测试体系整体重构（290 例双端实时比对）、两轮全项目审计与修复、文案对齐专项（P2-2 / P2-3）、内建函数缺口按「务实全集」补齐（P1-32 主体 / P1-56）、深递归日志噪音与 ObjectDB 泄漏的修复；编辑器插件自本版起移除，单文件 `pygds.gd` 为唯一分发形态。逐项明细见下方 alpha.5 ~ alpha.10 各节

### Removed

- **编辑器插件移除**：`addons/pygds/`（编辑器 `Project > Tools` 菜单的「Run PyGDS Script...」便利入口）自本版起移除，`project.godot` 不再启用插件；单文件 `pygds.gd` 是唯一分发形态，脚本执行请经宿主集成（`write_dsl_script` / `run` / API 注册）

## [0.7.0-alpha.10] - 2026-10-03

本版修复 dict 视图集合运算触发引擎 `SCRIPT ERROR` 的日志噪音（P1-69 连带发现），并精简双端运行器的常态输出

### 修复

- **dict 视图集合运算的引擎日志噪音（P1-69 连带发现）**：`_view_set_op` 以 `has_method("_view_elements")` 识别可集合化的右操作数，而基类 `_view_elements` 钩子使该判定对所有 DSL 对象恒真——`ks & 1` 等非法右参会以 `nil` 进入 `_set_from_elements` 触发引擎 `SCRIPT ERROR`（判定结果仍正确，纯日志噪音）；现改用显式 `_is_setlike_view()` 谓词（keys / items 视图为 true，基类与 values 视图为 false）

### 变更

- **运行器输出精简**：cases 用例的 PASS 不再逐条输出，常态输出仅保留失败条目与最终汇总（挂起套件 `demo/test_suspend_all.gd` 的逐测试 PASS 输出不变）

### 测试

- 全量回归 **290/290** 通过；挂起套件 24/24 通过；lint_cases / lint_md / lint_gd 全部 0 问题；ObjectDB 零泄漏维持

## [0.7.0-alpha.9] - 2026-10-02

本版完成 alpha.8 交接的三项任务：P2-50（深递归 `Stack underflow` 引擎日志噪音）、P2-51（退出时 ObjectDB 实例泄漏）与文案对齐专项（P2-2 / P2-3 解禁 + 降级断言升级），并按「务实全集」范围修复 P1-32（内建函数缺口）与 P1-56（复数字面量解析期拒绝）。测量先行定位了 P2-50 的真实机理（引擎调用栈记账上限而非回卷方式），P2-51 修复过程中发现并修复 GDScript `_init` 链式调用缺口，另新发现 P2-52（引擎 VM 硬上限的静默截断）记录入清单。`eval` / `exec` / `compile`、`globals` / `locals` / `vars`、`aiter` / `anext` 维持暂缓（分别与挂起重放机制、异步既定边界冲突，理由见已知问题清单）

### 新增

- **P2-50 消除手段**：本仓库 `project.godot` 设 `debug/settings/gdscript/max_call_stack=2047`（CI 与本地共用），宿主工程同设即可
- **cleanup() 公开 API（P2-51）**：长驻宿主在 run 结束 / 用例切换时主动回收解释器对象图与静态缓存（中英 usage.md 新增「对象生命周期与回收」章节）；释放节点时经 PREDELETE 自动触发，向后兼容
- **complex 类型与 `1j` 字面量（P1-56 / P1-32）**：词法层识别 `1j` / `1.5j` / `1e3j` 虚数字面量（`TokenType.IMAGINARY`）；新增 `DSLComplex`（实部/虚部/conjugate，与 int/float/bool 混算自动升格，整指数幂走精确重复乘法、非整指数走极坐标）；`complex()` 支持数值/字符串（含括号、双序、`"j"` 等形态）构造；等值复数与对应实数同字典键同哈希（`1+0j` 与 `1` 同键）；序比较/整型转换/divmod 按 CPython 报错
- **bytearray（P1-32）**：新增 `DSLByteArray`（继承 `DSLBytes`，覆写类型工厂使全部只读方法返回 bytearray）；构造支持长度/字节串/整数可迭代/`str`+编码；可变语义（下标与切片赋值、`append` / `extend` / `insert` / `pop` / `remove` / `reverse` / `clear` / `copy`）；不可哈希（字典键报 `unhashable type: 'bytearray'`）；`bytes + bytearray` 得 bytes、反向得 bytearray（CPython 同语义）
- **memoryview（P1-32）**：务实支持 B 格式一维视图——len/下标/切片/迭代/`tobytes` / `hex` / `cast("B")` / `release` 与 `readonly` / `obj` / `nbytes` / `itemsize` / `format` / `shape` 等属性；bytes 底层只读（赋值报 `cannot modify read-only memory`），bytearray 底层赋值透传；`bytes(mv)` / `bytearray(mv)` 互转
- **collections.deque（P1-32）**：双向端 append/appendleft/pop/popleft/extend/extendleft、rotate、maxlen（溢出静默挤出一端）、索引赋值、clear/copy/count/index/remove/reverse；不支持切片（CPython 同文案）；`collections.deque` 升格为类型对象（`type()` / `isinstance` 可用）
- **collections.OrderedDict（P1-32）**：继承 dict 全部行为；`move_to_end(key, last=True)`、`popitem(last=True)`（空字典报 `'dictionary is empty'`）、repr 为 `OrderedDict({...})` 形态（空为 `OrderedDict()`）；OrderedDict 间相等按键序敏感、与普通 dict 比较键序无关（CPython 同语义）
- **sys 模块（P1-32）**：`version` / `version_info`（对齐 CPython 3.12 形态）/ `maxsize` / `byteorder` / `platform`（按宿主 OS 映射）/ `argv` / `executable` / `path` / `intern` / `exit`；`sys.exit` 抛 `SystemExit`（BaseException 子类，未捕获时按既定模型进入错误终态，CPython 为静默退出进程）
- **open()（P1-32）**：文件对象务实子集——文本/二进制两态（`r` / `w` / `a` / `rb` / `wb` / `ab`），`read` / `readline` / `readlines` / `write` / `writelines` / `close` / `seek` / `tell` / `flush` / `readable` / `writable`，行迭代，`name` / `mode` / `closed` 属性；路径语义随宿主 FileAccess（相对路径按工程根解析）；新增 `FileNotFoundError` / `UnsupportedOperation` 异常类
- **轻量内建（P1-32）**：`ascii()`（非 ASCII 按码点转义）；函数式 `staticmethod` / `classmethod` / `property`（类体内赋值经类创建钩子补全属性名，`property.fget` / `fset` / `fdel` 可内省，`getter` / `setter` / `deleter` 返回新副本）；`operator.index`（`__index__` 协议入口）

### 修复

- **P2-50 `Stack underflow` 日志噪音**：实测定位机理——每个 DSL 递归层消耗约 6~7 条 GDScript 调用帧，越过引擎记账上限（`debug/settings/gdscript/max_call_stack`，默认 1024）后 `enter_function` 不再入栈而 `exit_function` 照常出栈，逐帧打印下溢（与回卷方式无关，迭代式回卷无效）。消除后 `--filter=syntax_flow_scan` 由 531 条降为 0，输出与判定不变
- **P2-51 ObjectDB 实例泄漏**：归因修正——对象本就是 `RefCounted`，泄漏主体是引用环（环境 ↔ 类 ↔ 方法闭包，生成器 ↔ 迭代器）与进程级静态缓存。实现「对象登记表 + 断环回收」：解释器登记本 run 创建的全部解释器侧对象，`cleanup()` 逐对象清空引用字段打断引用环，并清空全部静态缓存；双端运行器退出泄漏 ~15 万 → **0**，挂起 demo 同样归零，`1 resources still in use` 消失
- **GDScript `_init` 链式调用缺口（P2-51 连带发现）**：GDScript 子类定义 `_init` 时父类 `_init` **不会**被隐式调用，27 个未显式 `super._init()` 的 DSL 类此前从未进入登记表（泄漏残余 2055 个的来源）且 `_object_id` 从未分配；补齐后全量零泄漏，`id()` 对这些类恢复唯一性
- **文案对齐专项（P2-2 / P2-3）**：以下站点全部按 CPython 3.12 对齐（`%` 引擎与解析器各自独立副本逐一对齐）
  - 缺冒号：19 处 `Expected ':'` 统一为 CPython 小写形态 `expected ':'`
  - 未结束字符串：单引号 `unterminated string literal (detected at line N)`（N 为起始行）与三引号 `unterminated triple-quoted string literal (detected at line N)`（N 为扫描终止行，文件末尾换行不计入）
  - `min` / `max`：空序列 `min() iterable argument is empty`、无参 `max expected at least 1 argument, got 0`、非迭代实参 `'int' object is not iterable`
  - `round("a")`：`type str doesn't define __round__ method`
  - `math.factorial(-1)`：`factorial() not defined for negative values`（非整数实参同步对齐 `'float' object cannot be interpreted as an integer`）
  - `math.comb` / `math.perm`：n / k 负值文案拆分对齐（`n must be a non-negative integer` / `k must be a non-negative integer`），并按 CPython 语义将 `k > n` 从报错改为返回 `0`（连带修复 `math.comb(3, 5)` 类行为分歧）
  - `print >> x`：补 CPython 迁移提示 `Did you mean "print(<message>, file=<output_stream>)"?`（问号在引号外）
  - 函数对象 repr：`<function Child.greet at 0x...>`（补限定名与地址）；绑定方法 repr：`<bound method Child.greet of <Child object at 0x...>>`（补限定名与完整实例 repr）
  - `sorted([1, 'a'])` 操作数顺序经实测与 CPython 一致（升序 `'str' and 'int'`、reverse `'int' and 'str'`），原记录的顺序差异不存在，无需修复
- **类属性访问走描述符协议（P1-32 连带发现）**：`DSLClass._dsl_getattribute` 的 `class_attrs` 分支此前原样返回属性值，函数式 `classmethod` / `property` 经类体赋值落进 `class_attrs` 后 `cls` 绑定丢失（报 `UnboundLocalError`）；现按 CPython `type.__getattribute__` 语义以 `(null, cls)` 调用 `__get__`
- **方法包装调用的接收者错误转换（P1-32 连带发现）**：`_dispatch_call` 对 `DSLMethodWrapper` 补接收者 `last_error` 转换，此前错误被吞、调用静默返回 `None`
- **`dict` 兜底 unhashable 文案**：`unhashable type: X` 补引号对齐 CPython（`unhashable type: 'X'`）

### 修复过程发现并记录

- **P2-52（新，不建议投入）**：引擎 VM 调用栈硬上限（2048 帧）会绕过 PyGDS 的 RecursionError 协作回卷直接中止调用链，深递归叠加深表达式的脚本**静默丢失后续输出**；防御需在全部递归入口加解释器侧深度计数，属架构级改动。运行器已加 CASE-ERR 检测（`state == RUNNING` 即引擎硬中止），防止此类脚本被误判为输出分歧

### 测试

- 新增 `builtin_error_text` / `syntax_expected_colon` / `syntax_unterminated_string` / `syntax_unterminated_triple`（解析期文案，`same_error`）、`builtin_ascii` / `builtin_wrappers` / `builtin_open` / `type_complex` / `type_bytearray` / `type_memoryview` / `module_collections_deque` / `module_collections_ordereddict` / `module_sys` 共 13 例
- 断言升级：`builtin_abs_minmax` / `builtin_round` / `module_math` 的类名断言恢复完整消息断言（并补 `min(1)`、`math.comb(-1, 3)`、`k > n` 返回 0 等锁定）；`syntax_operator_matrix` 补 `print >> 1` 提示断言
- 全量回归 **290/290** 通过；挂起套件 24/24 通过；lint_cases / lint_md / lint_gd 全部 0 问题；双端运行器与挂起 demo 退出 ObjectDB 泄漏为 **0**、无 `resources still in use`

### 文档

- README（中英）兼容矩阵与已知问题章节：P2-2 / P2-3 / P2-50 / P2-51 移出未修复表并注明修复方式，新增 P2-52；内置模块清单加 sys，新增 complex / bytearray / memoryview / open() 四行能力，装饰器行补函数式形态；已知问题清单同步（未修复 22 → 18 条）
- usage（中英）新增「对象生命周期与回收」与 complex / bytearray / memoryview / open() 小节，模块清单加 sys
- 已知问题清单：P1-32 改写为残余子项（eval 系 / 作用域字典 / aiter / anext 暂缓理由）、P1-56 移除、P2-50 / P2-51 处置更新、P2-52 新增

## [0.7.0-alpha.8] - 2026-10-02

本版修复 v0.7.0-alpha.7 全项目审计新发现的问题中的 5 条：两条 P0（`nonlocal` 绑定搜索死循环、跨容器相等语义）与三条 P1（增强赋值运算符缺口、dict 视图集合运算、旧式迭代的 `in` 判定），并同步补充双端回归用例

### 修复

- **`nonlocal` 绑定搜索死循环（P0-28）**：`NonlocalStmt` 执行时的绑定搜索 while 循环缺少 `env = env.enclosing` 链推进，目标变量不在第一个外层环境时解释器无限空转挂死（不受步数上限约束，宿主进程需强杀）；修复后跨多级闭包链的 `nonlocal` 正确解析至目标环境，无绑定时按 CPython 报 `SyntaxError: no binding for nonlocal '...'`
- **跨容器类型相等语义（P0-29）**：`[1] == (1,)` 此前按内容比较判 `True`，现按 CPython 语义——不同内建容器类型（list/tuple/set/dict 互比）恒为 `False`，同类型比较行为不变
- **增强赋值 `&=` `^=` `<<=` `>>=`（P1-68）**：四个运算符此前在解析期拒绝（`Unexpected token '='`），现接入词法/解析/执行链路，整数按位与/或/异或/移位与 set 的原地对称差等语义与对应二元运算符一致
- **dict 视图与 set 的集合运算（P1-69）**：`d.keys()` / `d.values()` / `d.items()` 支持 `&` `|` `-` `^` 与 set/view 的全部组合，结果为 `set`
- **旧式 `__getitem__` 迭代对象的 `in` 判定（P1-70）**：`in` 运算在无 `__contains__` 时回退到旧式迭代协议逐元素比对（与 `list()` 等内建消费器同规），不再报 `'G' object is not a container`
- **`%#o` 备用前缀（P2-46a）**：`%` 引擎八进制备用形式此前被忽略（`%#o % 8` → `10`），现按 CPython 输出 `0o10`
- **f-string/str.format 进制前缀与零填充布局（P2-46b）**：`{255:#06x}` 此前为 `000xff`（前缀未参与零填充布局、负号位于前缀之后），现两引擎统一为 CPython 形态 `0x00ff` / `-0x0ff`
- **`%c` 单字符 str 实参（P2-47）**：`"%c" % "A"` 此前输出替换字符，现接受长度为 1 的 `str`；错误消息对齐 CPython（`%c requires int or char`）
- **format `.N` 有效数字语义（P2-48）**：无类型 `.N` 此前按小数位处理（`"{:.3}".format(3.14159)` → `3.142`），现实现 CPython 语义——舍入到 N 位有效数字后按数量级取定点 repr 或去尾零科学计数（`3.14` / `1.23e+02` / `1e+01`）
- **`str.casefold` 完整折叠（P2-49）**：`"ß".casefold()` 此前返回 `"ß"`，现实现 CaseFolding 多字符特例（`ß` → `ss`、连字 `ﬁ`/`ﬂ` 等与 `ſ` → `s`）
- **P2-45 复核为误报**：审计记录的「刚启动生成器 `send(非 None)` 抛 `StopIteration`」经复核不成立——PyGDS 行为与 CPython 一致（`TypeError`），系探针自身把生成器耗尽的 `StopIteration` 误归因，从清单更正

### 测试

- `syntax_global` 补跨两级闭包链的 `nonlocal` 断言；`type_seq_compare` 补跨容器相等断言；`syntax_augassign` 补 `&=` `^=` `<<=` `>>=` 断言；`type_dict_view_types` 补 `view` 与 `set` 集合运算断言；旧式迭代的 `in` 断言并入既有 `__getitem__` 迭代用例
- `syntax_yield_control` 补 fresh-send `TypeError` 断言；`type_str_percent` 补 `%#o` 与 `%c` str 实参断言；`type_str_format` 补 `.N` 有效数字断言；`syntax_fstring` 补 `#06x` 断言；`type_str_methods` 补 `casefold` 断言
- 全量回归 277/277 通过（本地 Godot 4.7.2 与 CI 同版本）

## [0.7.0-alpha.7] - 2026-10-02

本版完成行为一致性测试体系重构（`ci/` 双端实时比对，277 例）并退役冻结基线体系；同时完成全项目审计，新发现 12 条问题（含 2 条 P0）已记录入已知问题清单，随本版修复 4 条解释器行为分歧

### 修复

- **`ord()` 长度校验**：`ord("ab")` 此前不报错并静默取首字符码点，现按 CPython 抛 `TypeError: ord() expected a character, but string of length N found`
- **bytes/str `%` 格式化数值实参类型校验**：`b"%d" % "x"` 此前静默按 `0` 处理，现按 CPython 抛 `TypeError: %d format: a real number is required, not str`
- **`pow` 三参负指数模逆**：`pow(2, -1, 5)` 此前按 `(2 ** -1) % 5` 得 `0.5`，现实现整数模幂（平方乘，避免大中间值）与扩展欧几里得模逆，负指数按 CPython 语义求逆（底数与模不互素时抛 `ValueError: base is not invertible for the given modulus`）
- **statistics 异常类型**：`mean`/`median`/`mode`/`variance`/`pvariance`/`stdev` 的数据点不足错误由 `ValueError` 改为 `StatisticsError`（`ValueError` 子类，既有 `except ValueError` 不受影响），`mean`/`stdev` 文案同步对齐 CPython

### 测试

- **行为一致性测试体系重构（ci/）**：全部用例（277 个）自 `py_package/` 冻结基线体系整体 1:1 迁入 `ci/cases/`，改为**双端实时比对**——每次运行现场执行 CPython 与 PyGDS 各一次，按用例头注声明的比对语义判定，不再使用冻结的期望输出：
  - `same_output`（232 例）：双端均正常完成，stdout 归一化后逐字一致
  - `same_error`（45 例）：双端均报错，异常类名与消息均一致（剥离 `(line N)` 尾缀后）
  - 另有 `same_exception`（类名精确一致，不支持子类容差）与 `diverge`（已文档化既定分歧）两种声明供后续使用；任何单边报错一律判失败
- **用例名改为职责编码命名**：`syntax_*`（文法与其编译期错误）/ 推导式家族（`comprehension_*`，与 `syntax_for` 区分）/ `builtin_*`（内置函数）/ `type_*`（内置类型）/ `module_*`（标准库模块）/ `class_*`（用户类系统）/ `exception_*`（异常体系）/ `suspend_*`（挂起系统）；原空壳用例 `func_unpack` 补写为调用处解包错误路径（`syntax_unpack_args`）
- **新增 `ci/run_cases.gd` 双端运行器**：自动探测 CPython 命令（Windows 先 `python`，Linux 先 `python3`），经 `ci/_pyrun.py` 垫片（结果经 JSON 文件传递，强制 UTF-8）规避 `OS.execute` 输出切分与平台编码差异；内置归一化（对象默认 repr 的内存地址与 `__main__.` 前缀、未对齐解析文案的 `SyntaxError` 类名归一）；支持 `-- --filter=<名>` 过滤单跑
- **运行器支持可选行号比对**：报错用例声明 `# 行号: same` 后，运行器将 PyGDS 错误行的 `(line N)` 尾缀与 CPython traceback 末帧行号核对——运行期错误行号这一 README 兼容性矩阵特性由 `exception_uncaught_line` 用例守住（此前为比对盲区）
- **运行器支持可选行号比对**：报错用例声明 `# 行号: same` 后，运行器将 PyGDS 错误行的 `(line N)` 尾缀与 CPython traceback 末帧行号核对——运行期错误行号这一 README 兼容性矩阵宣称的特性由 `exception_uncaught_line` 用例守住
- **命名注册表调整**：推导式家族统一为 `comprehension_*` 前缀（`comprehension_list` / `comprehension_genexp` 等）；新增 `misc_*` 未分类兜底前缀；规范文档迁移至 `docs/zh-CN/ci.md` 与 `docs/en/ci.md`
- **头注键中英并存**：`duty`/`compare`/`anchor`/`ref`/`lines`/`skip` 与中文键等价，解析器统一归一化；值中 `" # "` 起为尾注释，解析时剥离
- **新增 `ci/lint_cases.py` 结构检查**：头注元数据完整合法、文件名符合家族注册表、`same_output` 用例可编译、中英两份文档条目与用例一一对应（双向）
- **文档与 GDScript 机械自查脚本迁入 `ci/`**（`lint_md.py` / `lint_gd.py`），`build/` 临时目录整体移除
- **旧体系退役**：`py_package/` 目录与根目录 `test.gd`（单端冻结基线比对器）移除，CI 只运行新体系（lint + 双端运行）
- **全项目审计**：21 个差分探针 + CI 日志归因新发现 12 条问题（P0-28/29、P1-68~70、P2-45~51，含 `nonlocal` 跨级闭包链挂死与跨容器相等语义两条 P0），已记录入已知问题清单
- `actions/checkout` 升级至 `v5`（消除 Node.js 20 弃用告警）；挂起 demo 逐测试释放 PyGDS 实例

### 文档

- **新增 `docs/zh-CN/behavioral.md` 与 `docs/en/behavioral.md`**：277 个用例的逐例说明（职责/比对/源文件链接，中英双语），按八大家族分组附导语，文档中的代码标识符一律行内代码包裹
- `README`（中英）行为测试章节改为新体系说明，详细文档表补 behavioral.md 条目
- `docs/zh-CN/ci.md` 与 `docs/en/ci.md`：命名注册表（含 `comprehension_*` 推导式家族与 `misc_*` 未分类兜底前缀）、边界规则、判定矩阵、归一化集合、用例书写规范（确定性）与新增用例流程

## [0.7.0-alpha.6] - 2026-10-01

本版修复 alpha.5 收尾发现的挂起重放缺陷群：状态机式内建消费器跨语句驱动睡眠生成器的重放循环（P0-27）、用户迭代器 `__next__` 异常被内建消费器吞掉、解包赋值将挂起误报为 None 解包错误，并回退 alpha.5 的 `__iter__` 严格性文案（P2-43，实测与挂起重放机制冲突）

### 修复

- **内建消费器 + 生成器 + `time.sleep` 挂起循环（P0-27）**：生成器步内 `time.sleep` 挂起、由状态机式消费器（`itertools.groupby`）跨语句驱动时，语句重放把源迭代器游标回退到消费窗口起点，已消费元素被再次投递进状态机，组边界污染、输出截断乃至 2000 次挂起上限循环（alpha.3 起既有）；修复取 for 语句自持迭代器同规——groupby 状态机构造时让源迭代器退出语句消费窗口（游标由状态机自持，重放不回退），grouper 与外层迭代器补产出日志与消费窗口（重放轮从日志重读已交付元素，与生成器迭代器同协议），groupby 对象缓存唯一外层迭代器（对齐 CPython `iter(it) is it`）并按调用节点记忆化（与生成器对象同协议，重放轮复用同一状态机）
- **用户迭代器 `__next__` 异常被消费器吞掉（P0-27 连带）**：用户迭代器预取把 `__next__` 抛出的全部异常一律清除并视为耗尽，`list(It())` 中迭代器中途抛 ValueError 时异常丢失且返回部分结果；现仅 StopIteration 视为耗尽并清除错误标记，其余异常保留错误状态经消费方向外传播
- **解包赋值挂起误报（P0-27 连带）**：`k, v = next(gb)` 等解包语句的值求值中途挂起时（返回 null），被误报为 `TypeError: cannot unpack non-iterable NoneType object`；现先检查挂起标志，挂起交回语句重放
- **`__iter__` 严格性文案回退（P2-43）**：alpha.5 的 `iter() returned non-iterator of type 'int'` 严格文案经实测与挂起重放机制冲突（生成器步内挂起的重放轮以非迭代器形态再次进入基类 `_dsl_iter` 的用户 `__iter__` 路径，误触发文案引发挂起循环），回退为宽松处理并记入已知问题清单（P2-43 不投入）；连带修正用户 `__iter__` 路径：null 结果（挂起或已有错误）原样传播不落旧式协议回退，list / tuple / range 返回值直接构造对应迭代器

### 测试

- 新增 5 个测试并入 `expected.json`（共 276 个用例全部通过，既有条目零变更）：`lang_iter_consumer_sleep`（内建消费器全形态 + 生成器步内 sleep）、`lang_iter_groupby_sleep`（groupby 单语句直消 / for 驱动 / 急切推导式 / 无 key / 手工 next 推进）、`lang_iter_raise`（用户迭代器与生成器中途 raise 穿透 list，StopIteration 仍为耗尽）、`lang_iter_yieldfrom_expr`（表达式内 yield 与 yield from 混合的 next 与 list 驱动）、`lang_iter_len_error`（`random.choices` 对生成器的 TypeError 文案）
- 移除 `lang_iter_strict`（P2-43 回退连带，272 → 271）
- 挂起综合测试 24 个用例全部通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/builtin.md` 与 `docs/en/builtin.md`：模块清单补 `time`（九模块）；类型方法覆盖核对补缺 4 项（`time.process_time`、`str.maketrans`、`str.translate`、`bytes.fromhex`），反向核对无幽灵条目
- `docs/zh-CN/usage.md` 与 `docs/en/usage.md`：type 别名段改为绑定 TypeAliasType / `__value__` 惰性求值；新增「变量注解与类型别名」小节（注解求值语义 / PEP 604 联合 / PEP 695 绑定）
- `docs/zh-CN/architecture.md`：注解「擦除」表述改为求值并存 `__annotations__`
- `docs/zh-CN/class_system.md` 与 `docs/en/class_system.md`：execute_class 流程补 `AnnotatedAssign`（类体注解）分支

## [0.7.0-alpha.5] - 2026-09-30

本版修复 alpha.4 收尾扫描发现的全部 5 条缺陷：`.format()` 嵌套格式规格、行内复合语句体的 else / elif 接续与分号归属、内建容器 dunder 协议方法、`__iter__` 严格性文案与变量注解求值（PEP 526），并连带补齐 PEP 604 联合类型与 PEP 695 别名绑定

### 新增

- **`.format()` 嵌套格式规格（P0-26）**：规格内 `{...}` 以同一实参池按 CPython 顺序（外层字段名先于嵌套规格）递归格式化——`"{:{w}}".format(5, w=6)` 输出 `'     5'`（repr 形态，宽度 6 右对齐）、`"{:{}}"` / `{0:{1}}` 自动与显式编号、`{:{w}.{p}f}` 组合均正确；f-string 嵌套此前已正常
- **行内复合语句体（P1-66）**：`if x: ...` 换行后的 `elif` / `else` 正常接续（`while` / `for` 同）；连带修复分号归属——`if False: a = 1; b = 2` 的 `b = 2` 此前逃出 if 体（词法层分号产出普通换行），现分号分隔的后续语句与首句同属行内体（`try:` 行内体同）
- **内建容器 dunder 协议方法（P1-67）**：`__len__`（list / tuple / dict / str / bytes / range）、`__iter__`（八类容器，返回与 `iter()` 同型的 `*_iterator` 对象）、`__delitem__`（list / dict）在实例上可调用（`[1, 2].__len__()` 为 2）；klass 为 null 的字面量实例经注册类型类回退查找
- **变量注解求值（P2-44，PEP 526）**：模块与类体的注解表达式按 CPython 语义在声明处求值（`x: undefined_name = 1` 报 `NameError`），存入 `__annotations__`（模块全局 / 类属性，插入序）；类体带值注解创建类属性、裸注解不创建；函数体内的注解不求值（CPython 同）；函数参数与返回注解在 def 时求值并存入 `f.__annotations__`（含 `"return"` 键，lambda 恒为空）；`from __future__ import annotations` 生效时全部跳过（PEP 563 语义）
- **PEP 604 联合类型（连带）**：`int | str` 产生 UnionType（repr 为 `int | str`、等值比较、成员扁平化），`isinstance` / `issubclass` 按成员判定
- **PEP 695 别名绑定（连带）**：`type X = expr` 将 X 绑定为 TypeAliasType 对象（repr 为别名名，`__value__` 惰性求值一次并缓存，定义环境捕获），别名可用于注解位置

### 修复

- **`__iter__` 返回非迭代对象的文案（P2-43）**：用户 `__iter__` 返回非迭代对象（int / list 等）时报 CPython 同文案 `iter() returned non-iterator of type 'int'`（此前按宽松回退当作可迭代处理并报 `'X' object is not iterable`）；返回带 `__next__` 的对象与生成器仍按迭代器接受

### 测试

- 新增 6 个测试并入 `expected.json`（共 272 个用例全部通过，既有条目零变更）：`lang_inline_compound`（分号归属 / else 接续 / elif 链 / while 与 for 的 else / try 行内体）、`lang_format_nested`（嵌套规格全形态）、`lang_dunder_protocols`（八类容器 len / iter / delitem 及不可变拒绝）、`lang_iter_strict`（int / list 拒绝文案与合法自返）、`lang_annotations`（注解求值 / `__annotations__` / 类体 / 函数 / 函数内跳过 / PEP 604 联合）、`lang_type_alias`（别名绑定 / `__value__` / 注解位置使用）
- 挂起综合测试 24 个用例全部通过；93 个用例文件双端输出一致；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md`：注解语义说明更新（注解一律求值并入 `__annotations__`，future annotations 生效时跳过）；PEP 695 段更新（别名绑定为 TypeAliasType）

## [0.7.0-alpha.4] - 2026-09-30

本版修复 alpha.3 收尾探针发现的全部 7 条缺陷：类创建钩子（`__init_subclass__` / `__set_name__`）、`global` 多名声明、`issubclass` 元组第二参、相邻字符串字面量连接、运行期泛性别名（PEP 585）与 bytes `%` 格式化（PEP 461），并在修复过程中连带对齐 isinstance 同族语义、补齐 bytes 的 repr 引号规则 / 字典键 / 容器 repr

### 新增

- **`__init_subclass__` 类创建钩子**：子类创建时沿新类 MRO 父链（不含新类自身）取首个定义者并以新类为 cls 调用（新类自定义的钩子仅对其子类生效，与 CPython 一致）；支持 classmethod 形式与 `super().__init_subclass__()` 链式调用（为此补 `object.__init_subclass__` 默认空操作，`hasattr(object, "__init_subclass__")` 为 True）；`type()` 三参形式同样触发；钩子异常阻断类创建且类名不绑定
- **`__set_name__` 类创建钩子**：类体自有属性中其类型定义了 `__set_name__` 的对象，在类创建时按属性访问协议绑定后以 `(owner, name)` 逐一调用（先于 `__init_subclass__`）；非描述符属性（数值 / None / 函数）不触发，继承链不重复触发；`type()` 三参形式同样触发
- **`global` 多名声明**：`global a, b` 逗号分隔多名声明（此前解析期拒绝，仅单名可用），解析 / 执行 / 局部名静态收集 / 类体四处同步
- **`issubclass` 元组第二参**：`issubclass(C, (A, B))` 短路求值（首个匹配即返回，后续非类元素不检查）、嵌套元组递归（CPython 同语义）；连带修正 arg 1 非类从静默 False 改为报 `TypeError: issubclass() arg 1 must be a class`、实参数文案改为 `issubclass expected 2 arguments, got N`、arg 2 文案补 "or a union" 后缀
- **isinstance 同族对齐**：元组形态递归（嵌套元组支持）、元组内非类元素报 `isinstance() arg 2 must be a type, a tuple of types, or a union`、实参数文案对齐
- **相邻字符串字面量连接**：字符串 / 字节串 / f-string 字面量在解析器合并紧邻同类字面量（括号内跨行与反斜杠续行自然相邻，语句间换行不相邻），str 与 bytes 混用报 `SyntaxError: cannot mix bytes and nonbytes literals`，含 f-string 时按书写次序合并为单个 f-string
- **运行期泛性别名（PEP 585）**：`list[int]` / `dict[str, int]` / `tuple[int, ...]` / `set[X]` / `frozenset[X]` / `type[X]` 返回 GenericAlias 对象（repr / 等值 / `__origin__` / `__args__` / 内容哈希 / 经原始类型调用，`list[int]()` 为 `[]`），身份判定对照注册表不受用户类遮蔽影响；用户类 `__class_getitem__` 协议接通；非泛型类下标报 CPython 同文案 `type 'X' is not subscriptable`；isinstance / issubclass 拒绝参数化泛型
- **bytes `%` 格式化（PEP 461）**：`%b` / `%s`（3.12 中二者等价，实参须为 bytes 或实现 `__bytes__`）、`%a` / `%r`（ASCII 转义形态，非 ASCII 字符转义为 \uXXXX 等）、`%c`（0-255 整数或单字节 bytes）、数值与浮点全族转换、宽度 / 精度 / 旗标、映射形式（bytes 为键）；实现为格式串按 latin-1 解字符后复用 str 格式化机制，结果重编回字节

### 修复

- **bytes repr 引号与转义（连带）**：内容含单引号且不含双引号时改用双引号包裹（此前 `b"'a'"` 显示为 `b''a''`），控制字符按转义文本输出（此前 `\t` 等输出真实字符）
- **bytes 作字典键（连带）**：`{b"k": v}` 此前报 `unhashable type: bytes`，现按内容编码支持（等值字节串为同一键）
- **bytes 在容器 repr 中（连带）**：`{b"k": 1}` 等此前显示 `<bytes object>`，现为 `b'k'` 形态

### 测试

- 新增 6 个测试并入 `expected.json`（共 266 个用例全部通过，既有条目零变更）：`lang_class_hooks`（两类钩子的次序 / classmethod / super 链 / 异常阻断 / type 三参 / 非描述符跳过 / 继承不重复）、`lang_global_multi`（函数与类体的多名声明、读改写）、`lang_issubclass_tuple`（元组短路 / 嵌套递归 / 自定义类 / isinstance 同族 / 六种错误文案）、`lang_str_concat`（同行 / 括号跨行 / 续行 / bytes / f-string / 方法链 / 字典键）、`lang_generic_alias`（别名全形态 / origin / args / 等值与哈希 / 调用 / 用户协议）、`lang_bytes_format`（全转换面 / 旗标 / 映射 / `__bytes__` 协议）
- 挂起综合测试 24 个用例全部通过；93 个用例文件双端输出一致；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md`：字符串字面量小节补相邻字面量连接；PEP 695 段补运行期泛性别名
- `docs/zh-CN/builtin_types.md` 与 `docs/en/builtin_types.md`：bytes 小节补 `%` 格式化说明

## [0.7.0-alpha.3] - 2026-09-30

本版完成 alpha.3 排期的全部 9 项：PEP 448 调用侧与类侧泛化（P0-23 / P1-60）、类体 `global`/`nonlocal`（P0-24）、参数表尾随逗号（P1-57）、点省略浮点字面量（P1-58）、`for` 目标星形名（P1-59）、`__future__` 导入 no-op（P1-61）、`BaseException` 注册（P1-62）与运行期字符串身份（P2-39）。修复过程对新代码面做双端探针复核，连带发现并修复 5 处既有缺陷（except 处理器重抛跳过 finally、`throw()` 拒收 BaseException 根实例、异常类 isinstance `type`、单目标元组形态不解包、非类星参基类静默通过）

### 新增

- **PEP 448 调用侧泛化（P0-23）**：调用实参按书写顺序求值与拼装，`f(1, *[2, 3], 4)` 实参为 `[1, 2, 3, 4]`（此前 `4` 被前插为 `[1, 4, 2, 3]`）；多组 `*` / `**` 可交错（`f(*[1], 2, *[3]`、`f(**d, k=9, **d2)`）；`*a` 允许跟在普通关键字参数之后（CPython 3.12 语义，此前误拒）；实参求值次序与 CPython 一致（源码顺序）；解析期对齐：重复关键字实参报 `SyntaxError: keyword argument repeated: a`，定位实参跟在 `**` 之后报 `positional argument follows keyword argument unpacking`，`*` 跟在 `**` 之后报 `iterable argument unpacking follows keyword argument unpacking`（均与 CPython 同句式）
- **关键字实参合并冲突检测**：关键字实参与 `**` 解包之间重复键报 `TypeError: g() got multiple values for keyword argument 'a'`（此前静默后者覆盖前者）；星参解包迭代中途挂起时丢弃部分实参交回语句重放，不再以部分实参调用被调对象
- **PEP 448 类侧泛化（P1-60）**：`class C(*bases)` 星参基类，展开可迭代对象元素逐个作为基类，支持与普通基类混排和尾随逗号；非可迭代报 `Value after * must be an iterable, not X`，非类元素报 `all bases must be classes`（后者文案与 CPython 元类路径不同，双方均为 TypeError）；星参基类可接生成器（含体内 sleep 挂起重放）；展开后的直接基类重复检查照常生效
- **类体 `global` / `nonlocal`（P0-24）**：类体内 `global g` 声明后，`g = 7` 写模块全局、读取沿外层链解析、不产生类属性；`nonlocal x` 绑定外层函数作用域（搜索跳过嵌套类作用域），无绑定时报 CPython 同文案 `SyntaxError: no binding for nonlocal 'x' found`
- **参数表尾随逗号（P1-57）**：`def f(a,)` / `def g(a, b=2,)` / `lambda x,` / `def f(**kw,)` / `def f(a, /, *, b,)` 等全部位置接受尾随逗号；对齐 CPython 的两处拒绝文案：裸 `*` 后无命名参数报 `named arguments must follow bare *`，`**kwargs` 后跟参数报 `arguments cannot follow var-keyword argument`
- **点省略浮点字面量（P1-58）**：`.5` 与 `1.` 为合法浮点字面量，支持科学计数法与下划线分隔（`.5e2` / `1.e5` / `.5_5`）；`1..foo` 等衍生形态与 CPython 同为语法错误
- **`for` 目标完整形态（P1-59）**：`for` 目标与解包赋值共用同一目标语法——星形名（`for *h, t in ...`）、括号/方括号嵌套（`for x, (y, z) in ...`）、下标与属性目标（`for a[i] in ...` / `for o.x in ...`）、单目标元组形态（`for a, in ...` 仍解包一层）；单个裸星形名（`for *a in`）报 CPython 同文案 `starred assignment target must be in a list or tuple`；连带将解包错误文案对齐 CPython：`cannot unpack non-iterable int object` / `too many values to unpack (expected 2)` / `not enough values to unpack (expected 2, got 1)`（字符串元素按字符解包随之生效）
- **`from __future__` 导入 no-op（P1-61）**：`__future__` 特性导入为编译器指令，按语法空操作处理（不绑定名字）；合法特性名（CPython 3.12 全表含 `barry_as_FLUFL` / `all_feature_names`）解析期校验，未知特性名报 `SyntaxError: future feature x is not defined`，`braces` 报彩蛋文案 `not a chance`，星号导入报 `future feature * is not defined`（三处均与 CPython 逐字一致）；文件中部导入与名字绑定的残留差异见已知问题清单 P2-41
- **`BaseException` 注册为可引用名（P1-62）**：异常体系以 `BaseException` 为根注册（`Exception` 与 `GeneratorExit` 改挂其下），`issubclass(ValueError, BaseException)` 可用、`except BaseException` 可捕获全部异常（含 `GeneratorExit`，`except Exception` 不捕获裸 `BaseException` 实例，与 CPython 一致）、`raise BaseException("x")` 与 `class E(GeneratorExit)` 的实例 `args` 记录正常
- **运行期字符串身份（P2-39）**：解析期常量折叠——字符串字面量 `+`（`"a" + "b" is "ab"` 为 True）与字符串/字节串字面量 `*` 整数字面量（`"ab" * 2 is "abab"`）、字节串 `+`（`b"a" + b"b" is b"ab"`，配套 bytes 字面量驻留池），折叠结果超过 CPython 的 4096 字符上限时不折叠；latin-1 单字符缓存——下标/切片/分割/迭代/`chr` 等运行期单字符结果与字面量共享实例（`"a b".split()[0] is "a"`、`chr(97) is "a"`、`"abc"[1] is "b"` 均为 True）；空串为全局单例（`"".join([]) is ""`）；大小写变换、replace、join、translate 结果不缓存（与 CPython 一致），center/ljust/rjust/zfill 宽度足够与 expandtabs 无 tab 时返回原对象自身，`"%s" % x` / `"{}".format(x)` 单 str 实参走快速路径返回原对象

### 修复

- **except 处理器体内异常沿 try 传播时 finally 体被跳过（连带发现）**：except 处理器内 `raise`（裸重抛或新异常）时直接向上返回，跳过本 try 的 finally 体（CPython 中 finally 照常执行）；普通语句与生成器 `throw` / `close` 路径同样受影响（如 `except BaseException: raise` + finally 的生成器在 `close()` 时 finally 不执行）；现处理器异常改为直达 finally（不再匹配后续 except 子句），finally 以 return/break/continue 或新异常终结的丢弃/取代语义不变；`except as` 名的隐式删除在异常退出时同步生效
- **`it.throw()` 拒收 BaseException 根异常实例（连带发现）**：`it.throw(GeneratorExit())` 误报 `TypeError: thrown value is not an exception`（校验仅认 Exception 子类）；现按 BaseException 根校验
- **异常类对 `type` 的 isinstance 为 False（连带发现）**：`isinstance(TypeError, type)` 为 False（异常 DSLClass 未挂 type 类指针，与 `isinstance(int, type)` 不一致）；现于异常类注册时挂接
- **单目标元组形态赋值不解包（连带发现）**：`a, = (1, 2)` 将整个元组赋给 `a`（CPython 解包后报元素数错误）；现与 for 目标一致按元组形态解包一层
- **for 循环解包错误文案（随 P1-59）**：`for a, b in [5]` 的 `Cannot unpack non-sequence` 与元素数错误的 `Unpacking mismatch` 改为 CPython 文案（见新增条目）

### 测试

- 新增 8 个测试并入 `expected.json`（共 260 个用例全部通过，既有条目零变更）：`lang_pep448_call`（星参次序、多组 `*`/`**` 混排、关键字求值次序、重复键 TypeError）、`lang_trailing_comma`（def/lambda/方法/嵌套函数参数表尾逗号）、`lang_float_literals`（`.5` / `1.` 全形态与运算）、`lang_for_targets`（星形/嵌套/字符串解包/下标与属性目标、CPython 解包错误文案、函数局部静态收集）、`lang_class_star_bases`（星参基类、重复检查、非类元素）、`lang_future_import`（文件头多形态导入、无名字绑定）、`lang_baseexception`（根类引用、except/raise/throw、GeneratorExit 子类）、`lang_str_identity`（常量折叠、单字符缓存、空串单例、自返回语义）
- 挂起综合测试 24 个用例全部通过；93 个用例文件双端输出一致；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md`：数字字面量补点省略/尾点形态；调用处 `*`/`**` 解包补 PEP 448 次序与冲突语义；import 小节补 `__future__` no-op 行为；循环小节补 `for` 目标解包形态；行连接小节尾随逗号范围扩至参数表与类基
- `docs/zh-CN/exception_system.md` 与 `docs/en/exception_system.md`：异常层次结构补 `BaseException` 根与 `GeneratorExit` 挂接，注册顺序同步，补充可引用性说明
- `docs/zh-CN/class_system.md` 与 `docs/en/class_system.md`：`execute_class` 流程补星参基类与类体 `global`/`nonlocal` 声明处理

## [0.7.0-alpha.2] - 2026-09-30

本版完成 alpha.2 排期的两项（原暂缓条目清零）：`__index__` 协议接入全部序列下标站点（P1-48），以及修复「try 体异常在途时 finally 体内挂起致异常丢失且脚本假终止」（P0-22）。P0-22 的根因是挂起边界与恢复轮把错误通道的在途标志当致命信号，修复过程在同一机制下连带发现并修复四处既有缺陷（防御性报错改写 `last_exception`、`yield from` 委托链伪造 `StopIteration`、函数调用帧复用丢失语句中部恢复状态、睡眠重放去重的两类误序号场景）；`iter(callable, sentinel)` 两参形式在 callable 内挂起的场景随之恢复正常

### 新增

- **`__index__` 协议与 bool 下标（原暂缓条目 P1-48）**：`str` / `list` / `tuple` / `bytes` / `range` 的下标读取、切片分量（`start` / `stop` / `step`，按 CPython 次序 step → start → stop 换算）、`list` 的下标赋值 / 切片赋值 / `del` 与 namedtuple 下标，均接受 `bool`（按 `0` / `1`）与定义了 `__index__` 的对象（经协议取值，负数回绕 / 越界判定等与整数下标一致）；`__index__` 返回非 int 报 `TypeError: __index__ returned non-int (type X)`，协议内 `raise` 原样传播，未定义协议仍报各序列原有的 `TypeError` 文案；字典键不做 `__index__` 转换（全部对齐 CPython）
- **`list` / `tuple` 切片读取的零步长校验**：`[1, 2, 3][::0]` 此前静默返回空列表（元组同），现报 `ValueError: slice step cannot be zero`（与 `str` 切片及切片赋值路径一致，对齐 CPython）

### 修复

- **try 体异常在途时 finally 体内挂起致异常丢失且脚本假终止（原暂缓条目 P0-22）**：挂起返回时在途异常使 `report.has_error` 为真，`interpret` 收尾将其误判为未捕获致命错误直接假终止（`<!ERR>` 后无输出），恢复轮的块顶检查也会被同一在途标志误导；现在途异常在挂起边界暂存（对致命判定隐身，`last_exception` 保持供匹配与异常链使用；`close()` 注入的 `GeneratorExit` 维持其「结束即静默」约定不参与暂存），finally 恢复后正常完成时写回错误通道沿正常路径传播（外层 `except` 可捕获，未捕获时报错行号正确）；`finally` 以 `return` / `break` / `continue` 或自身新异常终结时清空暂存（丢弃 / 取代语义不变）
- **`for` 可迭代表达式带错返回 null 时误抛防御性错误致外层匹配失败**：可迭代表达式求值失败（挂起恢复轮重放尤其如此）后再抛 `RuntimeError: iterable is null in for loop`，`report` 的 first-wins 保留旧文案但 `last_exception` 被改写为新异常，外层 `except` 无法匹配转为假终止；现在途异常直接向上传播
- **`yield from` 委托链上子生成器步内发起程序挂起被伪造为 `StopIteration`**：`send` / `throw` / `__next__` 驱动的步进返回「程序挂起」时误落 `StopIteration` 构造，委托层再将其误判为「子生成器正常结束」并清异常，异常被静默吞掉或跨轮状态错乱；现挂起步原样向上传播
- **函数调用挂起恢复丢失体帧的语句中部恢复状态**：挂起点位于函数体内 `try` / `finally` / 循环等复合语句内部时，调用帧复用新推的体帧不带 `resume_info` 与重放标记，恢复轮从函数体第一条语句重跑，已完成语句的副作用重复执行（如 `try` 体在 `finally` 挂起场景下 `print` 执行两次）；现挂起时一并保存、复用时原样转交
- **睡眠重放去重的序号错位（两个场景）**：其一，独立 `sleep` 语句挂起后重放根键泄漏——根语句不重放（表达式已求值完即挂起）则根键永不归零，同一根之后的独立睡眠被按序号误去重；其二，函数帧内前一个睡眠已挂起、帧从其后语句续跑时，同帧内位于其后的睡眠序号前移亦被误去重——两者的实际等待次数均少于声明次数；现不重放的根语句在挂起时立即收尾消费窗口，程序睡眠的语句在非生成器帧内整句重跑（重跑轮按序号去重，不重复等待；生成器步内睡眠不参与序号去重，不受影响）

### 测试

- 新增 2 个测试并入 `expected.json`（共 252 个用例全部通过，既有条目零变更）：`lang_index_protocol`（五类序列的下标与切片分量转换、负数回绕、赋值 / 切片赋值 / `del`、`__index__` 返回 bool、字典键不转换、非 int 返回、未定义协议、协议内 `raise`、namedtuple、int 子类）、`lang_suspend_finally_raise`（finally 挂起 x 在途异常的捕获、两次挂起、新异常取代与 `__context__`、`return` 保留、嵌套两层、裸 `raise` 重抛、except 处理器挂起、`break` 丢弃、`yield from` 委托链、生成器体内挂起后 `raise`）
- 挂起综合测试新增 I1 / I2 两个用例（22 → 24）全部通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）；P0-22 修复按「挂起 x 异常组合矩阵」做了 30 余个最小探针的双端比对（finally / except / `yield from` / 生成器体内挂起与在途异常、`close()` / `throw` 注入、多睡眠轮次的排列），「实际等待次数」经 `--cycles` 核查与声明次数一致

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md`：异常处理小节补充与挂起系统交互的语义（在途异常跨挂起边界照常传播、处理器与 `finally` 体内可挂起）
- `docs/zh-CN/builtin_types.md` 与 `docs/en/builtin_types.md`：切片类型小节补充序列下标与切片分量的接受类型（整数 / `bool` / `__index__` 协议）与字典键不转换的边界

## [0.7.0-alpha.1] - 2026-09-29

本版实现 v0.7.0 主要任务（异常对象直接创建）：解释器新增异常对象直接构造统一入口 `raise_exception_typed`，既有错误通道内部改调该入口，类型与消息静态已知的站点省去「记字符串、再解析」的回环；错误文案逐字节保持不变（连带修复的两处异常对象形态差异除外），`last_error` 探测通道与挂起机制时序不受影响

### 新增

- **`raise_exception_typed` 统一构造入口**：按类型名查全局注册表构造异常 wrapper，写入 `args` 与 `__cause__` / `__suppress_context__` 默认字段并设置 `last_exception`，消息为站点给定的最终显示文本（不再经 `__init__` 加工），`original_args` 非空时（如 `KeyError` 的键）直接作为 `e.args`；`raise_exception` 与 `raise_exception_from_last_error` 内部改调该入口，错误文案与异常对象形态对外零变化
- **静态站点直接构造**：for / `yield from` / 推导式 / 星号解包 / 解包赋值的「不可迭代」回退、`list` / `tuple` / `dict` 构造器的「不可迭代」回退、`operator.getitem` 的「不可下标」回退共 12 个站点的静态回退分支改为直接调用 `raise_exception_typed`；`del` 未定义名与增强赋值读取未定义名的 `NameError`、`sorted` 比较失败的 `TypeError` 共 3 个站点改为静态构造，不再经字符串解析
- **全量扫描补齐的内建能力**：`iter(callable, sentinel)` 两参形式（callable 内挂起的场景暂缓，见已知问题清单 P0-22 备注）；`str.maketrans` / `str.translate`；`bytes.fromhex`；`int.bit_length` 与 `real` / `imag` / `numerator` / `denominator` 属性，`float.is_integer` 与 `real` / `imag` 属性；`str.encode` / `bytes.decode` 支持 `ascii` / `latin-1` 编码与 `errors` 的 `strict` / `replace` / `ignore`（utf-8 严格解码逐字节校验非法序列），并注册 `UnicodeEncodeError` / `UnicodeDecodeError` 异常类型

### 修复

- **全量扫描发现的缺陷（4 项暂缓 / 暂不投入，见已知问题清单）**：
  - 递归容器的 `repr` / `str` 无循环保护致脚本挂死，现以 `[...]` / `{...}` / `(...)` 标记截断（CPython 语义）
  - `"%d" % True` 静默输出 `0`（CPython 为 `1`）；`%x` / `%o` 同
  - `"{missing}".format(x=1)` 缺失关键字静默返回空串，现报 `KeyError`；`"{} {}".format(1)` 位置不足静默填充，现报 `IndexError`（文案含 `for positional args tuple` 尾缀，对齐 CPython）
  - 函数内「先读后赋值」的局部名静默回退全局读取，现报 `UnboundLocalError`（增强赋值读取同）；增强赋值不再误用全局值
  - finally 中 `return` / `break` / `continue` 未丢弃进行中的异常，现按 CPython 语义丢弃并正常返回；挂起恢复路径按进入 finally 前的语句结果续做
  - `**` 解包非字符串键触发宿主层错误静默终止，现报 `TypeError: keywords must be strings`
  - `startswith` / `endswith` 传元组参数静默返回 `False`，现按元组逐一匹配
  - `0 < True` 等 int 与 bool 混合排序比较报 `TypeError`，现按数值比较（`sorted` / `min` / `max` 同）
  - 深递归穿透宿主 GDScript 栈溢出（无输出不可捕获），现于 256 层报可捕获的 `RecursionError`（CPython 默认 1000 层，宿主栈限制下取安全阈值）
  - 生成器体内逃逸的 `StopIteration` 直接逃逸，现按 PEP 479 转为可捕获的 `RuntimeError: generator raised StopIteration`
  - 序列乘负数（`[0] * -1` 等）报 `TypeError`，现返回空序列
  - property 的 `@x.deleter` 装饰器未接通（`del p.x` 报 `AttributeError`），现正确调用 deleter
  - 仅定义 `__gt__` 时 `a < b` 报 `TypeError`，现按 CPython 反射语义尝试 `b.__gt__(a)`（`<` / `>` / `<=` / `>=` 四运算）
  - `3 not in (1, 2)` 等比较链解析期报错（解析器的 `not in` 组合逻辑不可达），现正确解析
  - 异常实例 `__context__` 缺失，现于抛出时按 CPython 语义记录处理中 / 传播中的异常（实例与 raise 语句两条路径）
  - `"abc"[::0]` 零步长切片静默返回空串，现报 `ValueError: slice step cannot be zero`（字符串路径）
  - `"-42".zfill(5)` 输出 `00-42`，现为 `-0042`（符号保留最前）
  - `{1, 2}.update([3, 4], {5})` 多可迭代参数静默丢弃后者，现全部并入
  - `__slots__` 以 list / set 字面量声明时实例赋值误报 `AttributeError`，现与元组形态一致
  - `hash(1.0) != hash(1)`，现整值浮点与对应整数同哈希；元组与 frozenset 改按内容哈希（精确数值仍不与 CPython 对齐，P2-4 同族）
  - `format(2.25, '.1f')` 与 `%.1f` 为 `2.3`，现走二进制精确银行家舍入输出 `2.2`（与 `round` 一致，不经宿主 printf）
  - `list.index` / `tuple.index` 文案 `value not in list`，现为 `9 is not in list`（`%R` 形态）
  - `set.remove` 缺失键的 `KeyError.args` 为字符串 `('99',)`，现为原始值 `(99,)`（根因之一是错误参数数组与局部变量共享引用、清除后传空，已一并修正同类站点）
  - `setattr(1, 'x', 2)` 抛 `TypeError`（无 `__dict__`），现对齐 CPython 的 `AttributeError`
  - `f"{x = }"` 带空格的自文档形态丢失前缀，现输出 `x = 42`（`=` 两侧空格进入输出，对齐 CPython）
  - 内建方法调用失败时错误参数数组与局部变量共享引用被提前清空（悬空引用），`dict.pop` 等站点的 `e.args` 旁路恢复完整
  - `"a,b".split(",", 0)` 未按 `maxsplit=0` 语义整串返回；默认空白分割的余项不再吞并连续空白（按 CPython 原样保留）
  - `math.sqrt(-1)` / `math.log(0)` 静默返回 nan，现报 `ValueError: math domain error`
  - `reversed()` 返回可重复消费的列表而非一次性迭代器，现按 CPython 返回 `*_reverseiterator`（并支持字典反向键迭代，`dict_reversekeyiterator`）
  - `"{0.real}".format(3)` 等格式字段的属性访问链未支持，现按 CPython 逐级解析
  - `b"abc" < b"abd"` 等字节串排序比较报 `TypeError`，现按字节字典序比较
  - `bytes(range(3))` 未支持，现按 CPython 语义转换（越界仍报 `ValueError`）
  - `except as` 名在块结束后未按 CPython 语义隐式删除，现删除绑定
  - 重复参数名（`def f(*, a, a)`）静默接受，现报解析错误（文案与 CPython 的 SyntaxError 同句式）
  - `"ab".center(5)` 填充分配与 CPython 公式不一致，现按 `marg // 2 + (marg & width & 1)` 分配；填充字符非单字符现报 `TypeError`
  - 第三轮扫描：`collections.Counter` 补 `total()` / `elements()` / 算术运算（`+` / `-` / `&` / `|`，仅保留正计数）/ 映射实参语义与 `Counter({...})` repr；`itertools.chain.from_iterable` 与 `itertools.tee` 补齐；`itertools.product` 补 `repeat` 关键字；类体内嵌套类现挂入外层类属性（`Outer.Inner` 可达）；`"%s" % obj` / `{}` / f-string 对自定义 `__str__` 生效；`"abc".find("")` 按语义返回 `0`
  - **alpha.2 前置清缴（原暂缓条目 4 项）**：异常类对象暴露 BaseException 的 getset 描述符（`type(e).__cause__` 等返回 `<attribute ...>` 形态）；字符串与整数字面量驻留（`"a" is "a"`、`257 is 257` 为 True，± 号紧贴整数字面量常量折叠）；推导式改用私有驱动环境（lambda 闭包共享推导式作用域，`[lambda: i for i in range(3)]` 调用时取最后绑定值，对齐 CPython）；walrus 在推导式内绑定包含作用域（PEP 572）；内建方法调用前预清理驻留对象残留 last_error（修复 `dict.pop` 失败后同对象方法被旧错误误杀）
- **`random.choice` / `random.shuffle` 抽样字典时 `KeyError` 的 `str` 与 `args`**：`str(e)` 此前多一层引号（`'0'`）且 `e.args` 为字符串（`('0',)`），现与 CPython 一致输出 `0` 且 `e.args` 为原始键 `(0,)`
- **`del` 未定义名的 `NameError` 实例 `str(e)`**：报告通道已有错误导致异常构造被跳过 `__init__`，`str(e)` 退化为类型名 `NameError`，现输出完整消息 `name 'x' is not defined`；未捕获时错误行与其他错误一致附 `(line N)` 后缀

### 破坏性变更 (Breaking Changes)

- **异常对象形态与错误文案修正**：依赖 `str(e)` 带引号形态、字符串 `args`、`value not in list` 旧文案、`00-42` 补零形态或 format 静默空串（均不符合 Python 语义）的代码行为改变
- **递归深度上限**：函数调用深度超过 256 层报 `RecursionError`（此前穿透到宿主栈溢出）；CPython 默认约 1000 层，深度依赖需留意

### 测试

- 新增 7 个测试并入 `expected.json`（共 250 个用例全部通过，既有条目零变更）：`err_typed_raise`（内部错误站点构造的异常对象形态）、`err_scan_fixes`（format 缺失键 / 位置不足、`%d` 对 bool、零步长切片、`0 ** -1`、`setattr` 异常类型、startswith 元组、index 文案、负数序列乘、bool 排序比较）、`lang_flow_scan`（finally 流控丢弃、局部名 UnboundLocalError、隐式 `__context__`、PEP 479、递归上限）、`lang_builtin_scan`（数值方法与属性、`bytes.fromhex`、哈希不变量、编码族错误语义、translate / maketrans、zfill 符号、iter 两参）、`lang_class_scan`（递归容器 repr、property deleter、slots 多形态）、`lang_scan_r2`（split maxsplit 与余项空白、math 域错误、reversed 迭代器与字典反转、format 字段属性链、bytes 比较与 bytes(range)、except as 隐式删除、raise 文案、center 公式与填充校验）、`lang_scan_r3`（Counter 全族、chain.from_iterable 与 tee、嵌套类、product repeat、%s 与 `__str__`、find 空串）
- 挂起测试 22 个用例通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）；文档代码示例均经双端实测

### 文档

- `docs/zh-CN/exception_system.md` 与 `docs/en/exception_system.md`：新增 `raise_exception_typed` 统一构造入口小节，`raise_exception` 与 `raise_exception_from_last_error` 的代码片段与说明同步为委托实现
- `docs/zh-CN/builtin.md` 与 `docs/en/builtin.md`：`iter` 补两参形式，`encode` / `decode` 补编码与 errors 语义

## [0.6.0-alpha.7] - 2026-09-29

本版实现已知问题清单排期条目 `P0-13` 与 `P2-17` ~ `P2-26` 共 11 项（含此前已单独入库的 `P2-18` 小整数驻留），并对收尾回归中发现的三处连带缺陷一并修复

### 新增

- **内建装饰器组合的包装语义（P2-17）**：`@staticmethod` / `@classmethod` / `@property` 与任意装饰器组合时，内建形式改经真实的包装对象承载——staticmethod 包装原样返回持有对象（实例访问不传 `self`），classmethod 包装绑定所属类，property 包装持有装饰后的 getter，行为与 CPython 的重新包装一致；包装对象实现 `__get__` 描述符协议与调用转发，在类访问、实例访问、`super()`、魔术方法回退等路径正确解包；纯单一内建形式仍走 `method_type` 快速路径，既有用法不受影响
- **函数类型名（P2-20）**：`type(fn).__name__` 为 `function`，内建函数与绑定方法分别为 `builtin_function_or_method` / `method`；三个类型类仅经 `type()` 可见，不是内建名
- **内省属性（P2-21）**：实例 `__class__` 返回所属类（含内建值按类型名解析），类 `__dict__` 返回只读 `mappingproxy`（写入报 `TypeError`，`type(C.__dict__).__name__` 为 `mappingproxy`），异常实例补 `__traceback__`（返回 `None`）；`getattr` / `hasattr` / 属性赋值目标等访问路径同步覆盖
- **`defaultdict` repr（P2-22）**：输出 `defaultdict(<class 'int'>, {...})` 形式，工厂为 `None` 等取值与 CPython 一致；构造器支持无参
- **`__slots__`（P2-23）**：实例赋值沿 MRO 收集 slots 白名单，链上全部类声明 slots 时白名单外的属性赋值报 `AttributeError`（消息对齐 CPython），slots 实例不带 `__dict__`；继承链取并集，任一类未声明时不限制
- **`itertools.groupby` 惰性 grouper（P2-24）**：`groupby` 产出 `(key, grouper)` 对，grouper 为与外层共享游标的惰性一次性迭代器——外层推进后旧 grouper 立即耗尽，不再提前快照；`iter(groupby_obj)` 直通本体
- **`zip(strict=True)`（P2-26）**：接受 `strict` 关键字参数，某可迭代对象先耗尽而其余仍有剩余时报 `ValueError`，文案对齐 CPython 的 `zip() argument N is shorter/longer than argument 1`（多参数时 `arguments 1-j` 形式）
- **小整数驻留（P2-18）**：`DSLInteger` 引入静态驻留池，`-5..256` 范围内的等值整数共享同一实例，`is` 身份语义与 `CPython` 对齐；字面量、`int()` 转换、算术结果、`len()`、`range` 迭代计数等全部整数创建路径统一经驻留池；`True` / `False` 单例与 `id()` 一致性不受影响

### 修复

- **整数溢出明确报 `OverflowError`（P0-13）**：加 / 减 / 乘 / 幂 / 左移 / 一元负号 / 整除与 `abs()` 在结果超出 int64 时报 `OverflowError`（如 `integer addition exceeds 64-bit range`），超长字面量与 `int()` 的字符串、浮点转换同样报错，不再静默环绕；移位计数为负对齐 CPython 报 `ValueError: negative shift count`；`(-2) ** 63` 恰为最小整数、`9223372036854775807 // -1` 之外范围内运算结果不变；`bool` 算术（`True + True`）不受影响；连带拦截宿主层 `int64min // -1` 组合的挂死
- **`UnboundLocalError`（P2-19）**：函数局部名静态收集（赋值 / 增强赋值 / for 目标 / 解包 / walrus / 嵌套 def / 类 / import / except as / del / match 捕获，剔除 `global` / `nonlocal`），读取未赋值局部名改抛 `UnboundLocalError: cannot access local variable 'x' where it is not associated with a value`（`NameError` 子类，可被两者捕获）；模块层仍为 `NameError`
- **`round()` 二进制精确银行家舍入（P2-25）**：`round(2.675, 2)` 为 `2.67`（此前为 `2.68`），`round(0.5)` / `round(2.5)` 半到偶，负 ndigits 与整数入参按 `10**a` 半到偶，超大值窗口内原样返回；实现基于 53 位尾数的精确十进制展开与串上半到偶，连带修复零值入参的规格化死循环与负小浮点 repr 的符号污染（`print(-1e-09)` 此前输出十进制展开）
- **CRLF 行尾解析（连带发现）**：源码为 CRLF 行尾时，类体 / 函数体内空行会误触缩进处理产出 `DEDENT`/`INDENT`，导致随后解析报 `Unexpected token ''`；现空行（含 CRLF）不再参与缩进处理，Windows 环境常见行尾可正常解析

### 破坏性变更 (Breaking Changes)

- **整数溢出从静默环绕变为报 `OverflowError`**：依赖环绕行为（不符合 Python 语义）的代码行为改变；CPython 为无限精度整数，超出 int64 的运算是既定的明确报错差异
- **`round()` 中程值舍入结果变化**：`round(2.675, 2)` 等十进制中程值从「远离零」改为与 CPython 一致的二进制精确银行家舍入
- **函数内未绑定局部名从 `NameError` 变为 `UnboundLocalError`**：两者为父子关系，`except NameError` 仍可捕获

### 测试

- 新增 11 个测试并入 `expected.json`（共 243 个用例全部通过，既有条目 `expected` 零变更）：`lang_int_intern`（驻留身份与转换路径）、`lang_fn_types`（函数类型名）、`lang_introspect`（`__class__` / `__dict__` / `__traceback__`）、`edge_defaultdict_repr`（工厂 repr）、`lang_zip_strict`（strict 双向文案）、`lang_unbound_local`（局部名收集与消息）、`edge_slots`（白名单与继承）、`lang_groupby_lazy`（惰性 grouper 与过期耗尽）、`lang_round_exact`（边界值银行家舍入与零值符号）、`lang_builtin_decorators`（组合包装语义与反序形态）、`lang_int_overflow`（int64 边界与移位语义）
- 挂起测试 22 个用例通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md`：数字字面量小节补整数范围与 `OverflowError` 说明，装饰器组合段更新为语义保留
- `docs/zh-CN/builtin.md` 与 `docs/en/builtin.md`：`round` 补银行家舍入与边界示例，`zip` 补 `strict`，`groupby` 更新为惰性 grouper 语义
- `docs/zh-CN/class_system.md` 与 `docs/en/class_system.md`：装饰器一节更新包装对象机制
- `docs/zh-CN/exception_system.md` 与 `docs/en/exception_system.md`：异常层级补 `UnboundLocalError`
- `architecture.md` 中英同步驻留池语义、`mappingproxy` 与 grouper 共享游标状态类
- README 与 README_EN「已知问题与限制」章节移除 `P2-17`；已知问题清单移除 `P0-13` 与 `P2-17` ~ `P2-26`

## [0.6.0-alpha.6] - 2026-09-27

本版修复全量扫描发现的三个 P0 级缺陷（P0-14 短路求值、P0-15 增强赋值静默终止、P0-16 `del` 括号目标）与六项功能缺口（P1-36 `...` 字面量、P1-37 `collections.namedtuple`、P1-44 反射运算符、P1-45 类体作用域、P1-46 property 内 `super()`、P1-47 用户自定义描述符、P1-48 `min` / `max` 的 `default`、P1-49 `__getitem__` 旧式迭代）

### 新增

- **`and` / `or` 短路求值（P0-14）**：二元求值对逻辑运算特判——先求左操作数，按真值决定是否求值右操作数；右操作数的副作用与异常在 CPython 不会发生时不再发生，返回值仍为命中的操作数本身
- **`...`（Ellipsis）字面量（P1-36）**：`...` 为 `Ellipsis` 单例（`print(...)` 输出 `Ellipsis`，`type(...)` 为 `<class 'ellipsis'>`，`... is ...` 为 `True`），可用于函数体占位、默认值与注解位置；`ellipsis` 类型类仅经 `type()` 可见，不是内建名（与 CPython 一致）
- **`collections.namedtuple`（P1-37）**：`namedtuple(typename, field_names)` 生成带命名字段的元组子类；实例支持下标（含负数）、`len`、迭代、解包、按字段名访问与 `repr`（`Point(x=1, y=2)`），`==` 与元组及同族实例按值比较；类上提供 `_fields` / `_make(iterable)` / `_replace(**kw)`，实例提供 `_asdict()`；字段名接受空白 / 逗号分隔字符串或字符串可迭代对象；错误文案对齐 CPython 的 `__new__` 形式
- **反射运算符（P1-44）**：左操作数无法处理时尝试右操作数的 `__radd__` / `__rsub__` / `__rmul__` / `__rtruediv__` / `__rfloordiv__` / `__rpow__` / `__rmod__` / `__ror__`（如 `10 + Money(5)`）；左操作数为内建类型且右操作数定义了 `__eq__` / `__ne__` 时先走右操作数（CPython 的 `NotImplemented` 语义，如 `1 == Money(1)`）；反射方法内抛出的异常照常传播
- **类体作用域（P1-45）**：方法默认参数与类体内推导式在定义期可读取类体变量（`class E:` 中 `def f(self, k=default)` 与 `squares = [x * x for x in vals]` 可用）；方法体本身仍只沿外层作用域解析（CPython 细则）；默认参数按定义期求值一次缓存
- **property 内的 `super()`（P1-46）**：getter / setter / deleter 调用时正确设置方法上下文，零参 `super()` 可用于属性访问器；新增 `super().__setattr__` 语义（先 `__get__` 取候选值，仅当其可写时写入，与 CPython 一致）
- **用户自定义描述符（P1-47）**：用户类实例定义 `__get__` / `__set__` 时按描述符协议分派——类访问以 `(null, 类)` 调用 `__get__`、实例访问以 `(实例, 类)` 调用，`__set__` 优先于实例字段写入
- **`min` / `max` 的 `default` 参数（P1-48）**：可迭代对象为空时返回 `default`（未提供时仍报 `ValueError`）
- **`__getitem__` 旧式迭代协议（P1-49）**：仅定义 `__getitem__` 的对象可被 `for` / `list()` / `sum()` / 解包等消费，按下标连续迭代，`IndexError` 结束（用户 `raise` 与内部站点两种通道均支持），其余错误照常传播

### 修复

- **切片增强赋值与用户类原地方法静默终止脚本（P0-15）**：`lst[0:1] *= 2` 与用户类 `__iadd__` 等原地运算（`+=` / `-=` / `*=` / `/=` / `//=` / `**=` / `%=` / `|=`）此前静默终止脚本（无输出无报错），现按 CPython 语义执行：原地方法优先于普通二元方法，结果替换原绑定；增强赋值的失败路径改为明确异常（属性 / 下标缺失报 `AttributeError` / `TypeError`，未定义变量报可捕获的 `NameError`）
- **`del (b,)` 括号元组目标静默无效（P0-16）**：`del (a, b)` / `del [a, b]` 及嵌套形式现正确删除各目标；对字面量目标明确报 `SyntaxError`
- **二元运算错误传播**：用户方法内已抛出的真实异常不再被反射重试或错误改写覆盖，原样向上传播并可被 `except` 按类型捕获

### 破坏性变更 (Breaking Changes)

- **`and` / `or` 求值时序变更**：右操作数不再被无条件求值。依赖「右操作数总是执行」副作用的代码（不符合 Python 语义）行为改变
- **增强赋值失败从静默变为报错**：此前静默终止脚本的写法（切片增强赋值、用户类未定义原地方法）现按 CPython 报 `TypeError`

### 测试

- 新增 8 个测试并入 `expected.json`（共 232 个用例全部通过，既有条目 `expected` 零变更）：行为类 `lang_bool_shortcircuit`（副作用顺序 / 防错惯用法 / 操作数返回）、`lang_assign_aug`（切片增强赋值 / 原地方法 / 错误可捕获 / `del` 括号目标）、`lang_reflect_ops`（`__radd__` 族 / 反射比较 / 左侧优先 / 异常传播）、`lang_class_body_scope`（默认参数与推导式读类体变量 / 方法体不读 / property 内 `super()`）、`lang_user_descriptor`（`__get__` 类与实例访问 / `__set__` 校验拦截）、`lang_getitem_iter`（旧式迭代全消费形态 / 其余错误传播）、`lang_ellipsis`（单例语义 / 占位 / 默认值）、`lang_namedtuple`（字段访问 / 迭代解包 / 比较 / `_fields` / `_make` / `_replace` / `_asdict` / 错误文案）
- 挂起测试 22 个用例通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/builtin.md` 与 `docs/en/builtin.md`：`min` / `max` 补 `default` 说明与示例，`collections` 模块补 `namedtuple` 行与示例（双侧实测）
- `docs/zh-CN/usage.md` 与 `docs/en/usage.md` 新增「`...`（Ellipsis）」小节（双侧实测）
- README 与 README_EN「已知问题与限制」章节标注上述各项已修复
- 已知问题清单移除 P0-14 ~ P0-16、P1-36 ~ P1-37、P1-44 ~ P1-49；`CHANGELOG` 新增 `[0.6.0-alpha.6]` 版本节

## [0.6.0-alpha.5] - 2026-09-27

本版实现：类的多继承。DSLClass 引入直接基类列表与 C3 线性化缓存，全部沿单父链遍历的查找点迁移为 MRO 迭代，`super()` 改为沿实例（或类）MRO 的协作式查找

### 新增

- **类的多继承（P1-42）**：`class C(A, B):` 与三参 `type(name, bases, dict)` 接受多个基类；`DSLClass` 新增 `bases`（直接基类数组）与 `mro`（C3 线性化序列，创建时计算并缓存）字段，类对象新增 `__mro__`（元组）与 `mro()`（列表）内省成员（用户同名成员优先）
- **MRO 驱动的查找**：方法解析（`_lookup_method`）、类属性访问、isinstance / issubclass、异常匹配、`dir()`、类模式的 `__match_args__` 与 match-self 判定、异常体系核对、`__init__` 定位全部沿 MRO 进行，与「isinstance 为 True 则方法可查到」保持一致
- **MRO 冲突与一致性检查**：直接基类重复报 `TypeError: duplicate base class A`；C3 线性化无法一致报 `TypeError: Cannot create a consistent method resolution order (MRO) for bases A, B`（文案含 CPython 的内嵌换行）；多个基类的底层实例布局不相容（如 `class C(list, dict)`）报 `TypeError: multiple bases have instance lay-out conflict`（异常类之间共享同一布局，可多基继承）；检查先于类体执行
- **`super()` 沿 MRO 协作**：零参与双参 `super()` 从定义类在目标 MRO 中的下一项开始查找；类方法经 super 访问绑定到目标类本身（而非查找命中的类）；菱形继承下 `super().__init__()` 逐类恰好执行一次

### 修复

- **KeyError 子类的 `str()` 未按键 repr 输出**：`class KE(KeyError)` 的 `str(KE("m"))` 此前输出 `m`（按子类名走普通消息规则），现沿 MRO 识别 KeyError 语义输出 `'m'`（多继承下经 `class E1(KeyError, IndexError)` 暴露的既有边缘）

### 破坏性变更 (Breaking Changes)

- **`class C(A, B)` 从报错变为支持**：此前多基类直接报 `multiple bases are not yet supported`，现按 CPython 语义支持（行为增强，无兼容性影响）

### 测试

- 新增 3 个测试并入 `expected.json`（共 224 个用例全部通过，既有条目 `expected` 零变更）：行为类 `lang_class_mro`（多基查找顺序 / `__mro__` 与 `mro()` / isinstance / issubclass / dir / 冲突与重复基类拒绝）、`lang_class_diamond`（菱形 `__init__` 链逐类一次 / super() 协作 / 混合布局多基）、`lang_class_super_mro`（双参 super / 类方法 super 绑定 / 多基异常子类 / 类模式沿 MRO 取 `__match_args__` / 三参 type 多基）
- 挂起测试 22 个用例通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md` 新增「多继承与 MRO」小节（示例双侧实测）
- `docs/zh-CN/class_system.md` 与 `docs/en/class_system.md` 更新 DSLClass 结构与属性查找示例，新增「C3 线性化」与「多继承与 MRO」章节
- README 与 README_EN 兼容矩阵多继承行改为完整，「已知问题与限制」章节标注 P1-42 已修复
- 已知问题清单移除 P1-42；`CHANGELOG` 新增 `[0.6.0-alpha.5]` 版本节

## [0.6.0-alpha.4] - 2026-09-27

本版实现 P1-40：f-string 同引号嵌套与嵌套 f-string（PEP 701，Python 3.12），词法层以状态机重写 f-string 扫描，并在收尾扫描中修复若干连带发现的 f-string 缺陷

### 新增

- **f-string 同引号嵌套（P1-40）**：替换字段内的字符串字面量可使用与外层相同的引号（`f"{d["k"]}"`，含三引号复用 `f"""{d["""k"""]}"""`），嵌套 f-string 可用任意引号（`f"nested {f"{x}"} end"`）并支持递归再嵌套（`f"{f"{d["k"]}"}"`）；`{{` / `}}` 转义、`!s/!r/!a` 转换、格式说明符与 `=` 调试说明符语义不变；替换字段内表达式仍经 `parse_sub_expression` 通道求值，运行时无改动
- **f-string 字段内表达式扩展**：`!=` 比较（`f"{1 != 2}"`）、切片冒号（`f"{a[1:2]}"`）、字典 / 集合字面量（`f"{ {'a': 1} }"`）、lambda 与 walrus 等带冒号 / 括号结构，以及带前缀嵌套字符串（`f"{rf"{x}"}"`）全部可用；嵌套格式说明符的花括号内支持字符串表达式（`f"{x:>{'8'}}"`）
- **f-string 字段内多行表达式**：替换字段内表达式可跨行书写，支持缩进续行与行内注释（`f"""{` 换行 `x +` 换行 `1` 换行 `}"""`），单引号 f-string 的字段内同样可跨行；子表达式通道按表达式模式扫描，换行视为空白，不产出 NEWLINE / INDENT 令牌，表达式由自身文法终结

### 修复

- **f-string 字段内 `!=` 被误当转换标志（静默错值）**：`f"{1 != 2}"` 此前把 `!` 后的 `=` 当作转换字符（输出 `1`），现仅识别 `!s` / `!r` / `!a` 为转换标志，`!=` 按表达式处理，其余非法转换字符报 `f-string: invalid conversion character 'q': expected 's', 'r', or 'a'`
- **f-string 字段内切片冒号被误当格式说明符起点**：`f"{a[1:2]}"` 此前报 `'[' was never closed`，现字段内跟踪 `() [] {}` 深度，仅在花括号深度 1 且括号深度 0 处识别格式说明符起点
- **带前缀字符串的转义引号提前终止**：`f"\""` / `r"\""` / `b"\""` 此前报未闭合字符串（无前缀的普通字符串不受影响），现带前缀字符串的单引号与三引号扫描跳过反斜杠转义序列，被转义的引号不终止字符串
- **f-string 转换标志与格式说明符组合丢失格式（静默错值）**：`f"{x!r:>3}"` 此前忽略格式说明符（输出 `42` 的 repr 而非按宽度格式化），现转换标志先于格式说明符生效，格式应用于转换后的值（对齐 `format(conv(x), spec)` 语义）
- **f-string 字段表达式的行首空白报错**：`f"{ x }"`（字段内前导空格）此前报 `Unexpected token ''`（子词法器把行首空格产出 INDENT），现子表达式通道按表达式模式扫描，行首空白不再触发缩进处理

### 破坏性变更 (Breaking Changes)

无

### 测试

- 新增 1 个测试并入 `expected.json`（共 221 个用例全部通过，既有条目 `expected` 零变更）：行为类 `lang_fstring_pep701`（同引号嵌套全形态 / 嵌套 f-string 递归 / 三引号复用 / raw 前缀嵌套 / `!=` 与切片 / 转换标志与格式说明符组合 / 多行表达式含缩进续行与注释）
- 挂起测试 22 个用例通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md` 的 f-string 章节新增「同引号嵌套」说明与示例（含多行表达式，双侧实测）
- README 与 README_EN 兼容矩阵 f-string 行更新，「已知问题与限制」章节标注 P1-40 已修复
- 已知问题清单移除 P1-40；`CHANGELOG` 新增 `[0.6.0-alpha.4]` 版本节

## [0.6.0-alpha.3] - 2026-09-27

本版实现已知问题清单中已排期的四项轻量语法补齐（P1-33 异常链、P1-34 任意装饰器、P1-35 `__name__`、P1-39 泛型类型参数语法），并修复 `raise` 路径与调用分派上的连带缺陷

### 新增

- **`raise ... from` 异常链（P1-33）**：`raise 表达式 from 因果表达式` 解析与执行，因果值存入异常实例的 `__cause__` 字段（wrapper 实例存 `fields`，裸 DSLException 存专有字段），`__suppress_context__` 随显式 `from` 置 `True`（`from None` 时 `__cause__` 为 `None`），无 `from` 时两者默认 `None` / `False`；因果值须为异常实例 / 异常类 / `None`，否则报 `TypeError: exception causes must derive from BaseException`；隐式 `__context__` 链与未捕获输出的链式回溯打印未实现（文档如实标注）
- **任意装饰器与带参装饰器（P1-34）**：`@` 后接受任意可调用表达式（自写装饰器、带参工厂、属性链等），并支持装饰 `class` 定义；`@classmethod` / `@staticmethod` / `@property` / `@name.setter` / `@name.deleter` 五种内建形式保留 `method_type` 快速路径，可与任意装饰器组合（内建形式最多一次）；装饰器表达式先按源码顺序全部求值、再从最贴近定义者依次应用（CPython 顺序），最终返回值替换原绑定；顶层 `def`、类体方法与 `class` 三个应用点全覆盖，装饰器表达式内 `time.sleep` 挂起经语句重放正常推进
- **`__name__` / `__file__` 脚本级全局名（P1-35）**：解释器启动时注入 `__name__ = "__main__"`（可重新赋值，入口守卫 `if __name__ == "__main__":` 可用）与 `__file__`（默认空串）；新增宿主 API `set_script_path(path)`，在 `run()` 前设置脚本路径
- **泛型类型参数语法与 `type` 别名（P1-39）**：`class C[T, U]:` / `def f[T](x):` / `type X = int`（PEP 695）按语法接受并忽略类型语义；类型参数可带绑定注解与默认值（均只解析不求值），`type` 别名语句解析为 no-op（别名名不绑定，右侧表达式不求值）

### 修复

- **裸异常类 raise 报错**：`raise ValueError`（类不带括号）此前报 `TypeError: exceptions must derive from Exception`，现按 CPython 无参实例化后抛出；`raise GeneratorExit()` 等不继承 `Exception` 的已注册异常（`BaseException` 系）同样可正常抛出与捕获
- **不可调用对象调用静默丢失**：`5()` / 用户实例未定义 `__call__` 时调用此前静默终止脚本（无报错无输出），现按 CPython 报 `TypeError: 'int' object is not callable`（可被 try/except 捕获）
- **`raise` 表达式求值挂起被跳过重放**：`raise f()`（`f` 内含 `sleep`）此前以 RAISE 结果提前返回，语句恢复时按整体重放兜底；现按挂起语义返回 `SUSPENDED` 交回语句重放，与 `match` 主题求值等语句一致

### 破坏性变更 (Breaking Changes)

无（`match = 1` 式的既有用法与五种内建装饰器形式的行为均不变；`@unknown` 此前报 `Unknown decorator`，现按任意表达式解析，不可调用时报 `TypeError`）

### 测试

- 新增 5 个测试并入 `expected.json`（共 220 个用例全部通过，既有条目 `expected` 零变更）：行为类 `lang_raise_from`（`__cause__` / `__suppress_context__` 全形态 / 裸类 / `BaseException` 系 / 因果校验）、`lang_name_main`（`__name__` 取值与重赋值 / 入口守卫 / 函数与类内访问）、`lang_decorator`（自写 / 带参 / 堆叠与求值顺序 / 类与方法装饰器 / 内建组合 / 不可调用装饰器 / 挂起）、`lang_generic_syntax`（泛型类与函数 / 绑定注解 / `type` 别名 / 注解位置使用）；错误类 `err_raise_from_missing`（`raise from` 缺主表达式文案对齐）
- 挂起测试 22 个用例通过；差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md` 新增「装饰器」「泛型类型参数语法与 `type` 别名」「`raise ... from` 异常链」「`__name__` 与 `__file__`」四节（示例双侧实测）
- `docs/zh-CN/exception_system.md` 与 `docs/en/exception_system.md` 更新 `raise` 执行流程（裸类实例化 / from 子句 / 因果校验），新增 `raise ... from` 异常链小节
- `docs/zh-CN/class_system.md` 与 `docs/en/class_system.md` 更新装饰器解析说明，新增「任意装饰器」章节（解析 / 应用时机 / 挂起与限制）
- README 与 README_EN 兼容矩阵更新装饰器行并新增异常链 / `__name__` / 泛型行，「已知问题与限制」章节标注 P1-33 / P1-34 / P1-35 / P1-39 已修复，新增 P2-17（内建装饰器形式与返回包装函数的装饰器组合时包装语义不保留）

## [0.6.0-alpha.2] - 2026-09-26

本版实现已知问题清单中 P2-9 ~ P2-15 全部条目（type 身份语义、`dir()` 内置实例、`float.hex()`、字典视图实时性、match 模式错误文案、异常对象 `args`/`str`/`repr`、元组下标），并在收尾扫描中修复若干连带发现的问题

### 新增

- **type 身份语义（P2-9）**：`type` 名字绑定到类型类自身（`print(type)` 输出 `<class 'type'>`），`type(x)` 与 `type(name, bases, dict)` 经类调用分派（`__new__` 分发 1 参 / 3 参形式）；`isinstance(int, type)`、`type(C) is type` 与 CPython 一致；用户类实例化时挂 type 类引用（`isinstance(C, type)` 为 True）
- **`dir()` 内置类型实例（P2-10）**：`dir([])` / `dir(5)` / `dir({})` 等不再返回空列表，按类型名定位类型类并沿继承链收集方法、类属性与实例级魔术方法描述符名（结果排序）；`dir(None)` 按 object 层方法列出；`dir()` 无参返回当前作用域的用户定义名（排除内建注册名）
- **`float.hex()`（P2-11）**：返回 IEEE 754 双精度十六进制浮点字符串（`0x1.8000000000000p+0`），自实现 frexp 式分解与次规格数处理，覆盖 `±0.0` / `±inf` / `nan` / 最小规格数 / 次规格数
- **range 的 `count` / `index`**：`range(10).count(3)` / `range(3).index(9)`（后者不存在时按 CPython 报 `ValueError: 9 is not in range`）；range 字面量实例的方法查找经 range 类型类解析
- **异常对象 `args` / `str` / `repr`（P2-14）**：异常实例携带 `args` 元组（含用户异常子类，构造参数确定即记录，对齐 `BaseException.__new__` 语义）；`str(e)` 返回消息（多参数为元组 repr，`KeyError` 用键 repr，无参为空串），`repr(e)` 为 `TypeName('msg')` 格式；DSLException 直连分支同样支持
- **元组下标（P2-15）**：`d[1, 2]` 以元组作字典键（下标与赋值目标两条解析路径），支持尾逗号、嵌套元组、增强赋值与 `del`；非字典容器的元组下标按 CPython 报 `TypeError`
- **字典视图实时性（P2-12）**：`d.keys()` / `d.values()` / `d.items()` 持有源字典引用，`len` / `bool` / 成员判定 / 相等 / `repr` 实时反映字典内容；视图迭代期间增删键按 CPython 报 `RuntimeError: dictionary changed size during iteration`（值替换不触发）；新增字典值与键值对活迭代器

### 修复

- **复合键迭代产出内部编码字符串**：`iter(d)` / `for k in d` / 视图对元组键 / 冻结集合键 / 用户类键的字典此前产出 `'tuple:|1|2'` 这类内部编码（静默错值），现经「规范化键 → 原始键对象」映射还原为真实键对象；映射随 `_key_to_variant` 写入自动登记，`copy` / `update` / `clear` / `popitem` 等同步维护
- **字符串内转义引号提前终止**：`"a \"b\""` 此前在词法层提前结束字符串（报续行 / 未闭合错误），单行与三引号字符串扫描现跳过转义序列，被转义的引号不参与结束判定
- **repr 字符串引号选择**：`repr("it's")` 此前输出无效格式 `'it's'`，现按 CPython 规则选择引号（优先单引号，内容含单引号且不含双引号时用双引号包裹，仅转义包裹引号本身），`str` / `list` / `tuple` / `dict` / `set` / 容器嵌套全部对齐
- **`type()` 三参建类的类属性键**：`type("A", (), {"x": 1})` 此前把字典内部键的 `"s:"` 前缀带入类属性名（`A.x` 报 AttributeError），现还原为真实键名；类属性与方法分流不再把非函数值误判为可调用
- **`case` 子句与括号未闭合的优先级（P2-13）**：`case [a, b:` 等模式内未闭合括号此前报 `'[' was never closed`，现解析层在关闭括号失败处还原报错（模式内冒号按 CPython 报 `invalid syntax`，文件末尾未闭合仍报 `was never closed`）；`case 1 1:` / `case *:` / `case {**}` / `case 1 as:` / `case 1 if:` / `case 1::` / `match x 1:` 的文案与 CPython 对齐，`case 1`（缺冒号）报 `expected ':'`，`match x if x:` 报 `invalid syntax`；三元表达式缺 else 的文案对齐为 `expected 'else' after 'if' expression`

### 破坏性变更 (Breaking Changes)

- **异常对象的 `str(e)` / `repr(e)` 语义变更**：`str(e)` 从返回异常类型名改为返回消息文本（无参为空串），依赖旧格式的代码需改用 `type(e).__name__`
- **`print(type)` 等类型对象显示变更**：`type` 从内建函数变为类对象（`<built-in function type>` → `<class 'type'>`）；`type(x)` 调用结果不变
- **`dir()` 输出变更**：内置类型实例从返回空列表改为返回方法名列表；`dir()` 无参从返回全部内建名改为仅返回用户定义名
- **部分语法错误文案变更**：`case` 模式内的错误从行号前缀格式改为 CPython 的 `invalid syntax` / `expected ':'` 格式；此前静默通过的 `{1: a, 1.0: b}`（映射重复键）等已在 alpha.1 报错

### 测试

- 新增 11 个测试并入 `expected.json`：行为类 `lang_type_dir_hex`（type 身份 / dir 内置实例 / range 方法 / float.hex）、`lang_dict_view_live`（视图实时性 / 迭代失效 / 复合键还原）、`lang_exception_repr`（args / str / repr / 引号选择 / 用户异常 / `__init__` 覆盖）、`lang_tuple_subscript`（元组键全形态）；错误类 `err_match_extra_token` / `err_match_star_alone` / `err_match_dstar_alone` / `err_match_guard_missing` / `err_match_double_colon` / `err_match_unclosed_pattern` / `err_ternary_no_else`，共 215 个用例全部通过，既有条目 `expected` 零变更，挂起测试 22 个用例通过
- 差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

## [0.6.0-alpha.1] - 2026-09-26

本版实现 `match` / `case` 结构化模式匹配（Python 3.10+，基线对齐 CPython 3.12 的匹配语义与语法错误文案）。`match` / `case` 按软关键字处理，既有以 `match` / `case` 命名的标识符不受影响

### 新增

- **`match` / `case` 语句**：主题表达式支持元组形式（`match 1, 2:`）与括号 / 括号内换行；`match` 块内要求至少一个 `case` 子句，`case` 体支持缩进块与单行体
- **模式种类**：字面量模式（数字 / 字符串 / bytes / `None` / `True` / `False` / 负数）、捕获模式（永远匹配并绑定）、通配符 `_`、序列模式（固定长度 / `*rest` 任意位置 / `*_` / 空序列 / 无括号逗号序列）、映射模式（常量与点号常量键 / `**rest`）、类模式（`isinstance` 检查 / `__match_args__` 位置映射 / 关键字子模式 / 嵌套 / 内建类型单位置绑定主题——`case int(v):` 对 `int` / `float` / `str` / `list` / `dict` / `tuple` / `set` / `frozenset` / `bytes` / `bytearray` / `bool` 及其子类生效）、或模式（`|`）、`as` 绑定、任意深度嵌套
- **语义**：字面量模式中 `None` / `True` / `False` 按单例身份比较（`case True:` 不匹配 `1`），数字 / 字符串 / bytes 用相等比较（`case 1:` 匹配 `1.0` 与 `True`）；命中时先绑定捕获名再求值守卫，守卫为假时绑定保留并继续下一个 `case`；匹配自上而下逐个尝试，首个命中执行后退出；捕获绑定遵循普通赋值作用域（`global` / `nonlocal` 生效）
- **编译期检查（`SyntaxError`，文案与 CPython 3.12 一致）**：或模式分支绑定名不一致（`alternative patterns bind different names`）、模式内重复绑定（`multiple assignments to name 'a' in pattern`）、`case ... as _`（`cannot use '_' as a target`）、类模式关键字重复（`attribute name repeated in class pattern: x`）、关键字后位置子模式（`positional patterns follow keyword patterns`）、`**rest` 后仍有键、`**_`、映射模式常量键等值重复（`mapping pattern checks duplicate key (1.0)`，`1` / `1.0` / `True` 同键）、带无守卫捕获或通配的 `case` 后续不可达（`name capture 'y' makes remaining patterns unreachable` / `wildcard makes remaining patterns unreachable`）、带守卫的子句不构成不可达
- **运行期错误**：类模式位置子模式超量报 `Cls() accepts N positional sub-patterns (M given)`（单数区分）；`__match_args__` 非元组报 `Cls.__match_args__ must be a tuple (got list)`；位置映射名与关键字重复报 `Cls() got multiple sub-patterns for attribute 'x'`；类模式关键字属性缺失按匹配失败处理（不抛异常），属性 getter 抛出的非 `AttributeError` 异常照常传播；用户类实例不参与序列 / 映射匹配（对齐 CPython 3.12 的类型标志语义）
- **软关键字消歧**：`match` 仅在语句起始且同一逻辑行存在括号外冒号时按 match 语句解析；`match = 1` / `match(x)` / `match[0] = 1` / `match: int = 1` / `match = {1: 2}` 等标识符用法全部保持；`case` 在 `match` 块外仍是普通标识符
- **挂起系统兼容**：主题、守卫、类模式属性 getter、case 体中的 `time.sleep` 均正常挂起与语句重放推进（生成器内 `match`、循环内 `match`、并列调用的副作用不重复均验证）

### 文档

- `docs/zh-CN/usage.md` 与 `docs/en/usage.md` 新增「match / case 结构化模式匹配」章节（语法示例双侧实测 + 模式语义补充说明）
- `docs/zh-CN/builtin_types.md` 与 `docs/en/builtin_types.md` 类型总览新增模式匹配的类型参与规则
- README 与 README_EN 兼容矩阵新增 `match`/`case` 行，「已知问题与限制」章节移除 P1-10 条目

### 测试

- 新增 20 个测试：行为类 `lang_match_basic`（字面量 / 捕获 / 通配 / 守卫 / 或 / as / 主题元组 / 软关键字 / 循环内匹配）、`lang_match_seq`（序列与星号 / 无括号序列 / 嵌套 / 排除规则）、`lang_match_map`（映射与 `**rest` / 嵌套 / 布尔键）、`lang_match_class`（类模式 / 值模式 / 内建类型绑定 / 运行期错误文案）、`lang_match_sleep`（挂起场景全形态）；错误类 `err_match_*` 15 例（case 缺模式、or 绑定不一致、重复绑定、不可达 case、`as _`、关键字重复与后置、`**rest` 后有键、`**_`、match 块内非 case、顶层单星 / 顶层 case、多星、重复键），全部并入 `expected.json`（共 204 个用例全部通过，既有条目 `expected` 零变更），挂起测试 22 个用例通过
- 差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

## [0.5.0] - 2026-09-26

### 文档

- `docs/zh-CN` 与 `docs/en` 三份核心文档（builtin / builtin_types / usage）同步 v0.5.0-alpha.7 / alpha.8 的行为变化：`iter()` 的真迭代器语义（生成器返回自身、活动视图、字典迭代中增删键报 `RuntimeError`）、`type()` 对用户类返回 `<class 'type'>`、新增 `bytes()` 构造函数与 `bytes` 方法族、`format()` / `dir()` 内建、`str.encode` / `str.format_map`、`int` / `float` 方法族、集合原地更新族与可迭代实参、`dict_items` 视图相等语义
- 方法签名统一为 Python 注释风格
- README 兼容矩阵补全：`bytes` 行补充构造函数与方法族，新增「用户类排序比较」行（`__lt__` / `__gt__` 参与排序与 `min` / `max`，含反射语义）

其余已知问题与功能缺口见 README 的「已知问题与限制」章节，或在仓库 `tests/已知问题清单.md` 查看带复现脚本的完整清单

## [0.5.0-alpha.8] - 2026-09-26

本版修复 alpha.7 排查发现的 6 项已知问题，并通过收尾扫描补齐一批内建函数与方法缺口

### 修复

- **`iter(生成器)` 返回快照列表（P1-30）**：`it = iter(g())` 此前把生成器驱动完成并快照为列表（可重复消费），现在返回生成器自身（`iter(gen) is gen`，耗尽后不可重复消费）；`itertools.repeat` / `count` / `cycle` 等无限对象改为一等迭代器包装（绝不走快照分支）；`defaultdict` 与 `d.items()` 接入对应迭代器类型；迭代器的驱动状态在 `iter()` 调用时定格
- **排序不支持用户类 `__lt__` / `__gt__`（P1-31）**：`[P(2), P(1)].sort()` 此前报 `TypeError`。现排序与 `min` / `max` 的元素比较统一走与二元运算符相同的分派（用户比较方法优先、不可用时试反射比较、再回退内置比较）。CPython 富比较语义对齐：`sorted(reverse=True)` 按交换操作数的 `__lt__` 比较（不要求 `__gt__`）、只有 `__lt__` 或只有 `__gt__` 的类都能通过反射参与排序、`max` 缺 `__gt__` 时反射到 `__lt__`；比较方法体内抛出的异常按原类型传播（可被 try/except 捕获），不再被通用文案遮蔽；比较方法内的 `sleep` 经语句重放正确推进（每处比较各等待一次）
- **迭代字典时增删键不报错（P2-6）**：`it = iter(d)` 后增删字典键再消费，此前静默继续（或取到新键）。现按 CPython 报 `RuntimeError: dictionary changed size during iteration`，可被 try/except 捕获；既有键的值替换不触发；推导式、`sum` / `sorted` / `tuple` / `set` / `dict` / `next` 等全部消费路径统一传播。实现采用迭代器尺寸快照检查 + 解释器异常通道（上一轮的 `error_msg` 轮询方案已废弃）
- **`type(用户类)` 返回 `<class 'object'>`（P2-8）**：现返回 `<class 'type'>`；`type` / `dict_items` 类型类补全注册。顺带把 `dict_keys` / `dict_values` / `dict_items` 类型类从全局命名空间收敛到内置类型表（与迭代器类型一致，`isinstance(x, dict_keys)` 按 CPython 报 `NameError`，这些类型名不再是内建名）
- **迭代器类型类暴露在全局命名空间（P2-7）**：`list_iterator` / `dict_keyiterator` / `repeat` / `count` / `cycle` 等类型类此前注册进全局命名空间（`isinstance(it, list_iterator)` 可直接用），现仅注册进内置类型表供 `type()` 返回与 `isinstance` 的类型名解析；全局命名空间与 CPython 一致（脚本若以这些名字定义变量不再被覆盖）
- **`iter()` 对部分容器的类型名（P2-5）**：`type(iter(defaultdict(int))).__name__` 现为 `dict_keyiterator`（此前 `list`）；`d.items()` 返回独立的 `dict_items` 视图类型（此前是快照列表），`type(iter(d.items())).__name__` 为 `dict_itemiterator`，支持 `len()` / 成员判定 / `repr`（`dict_items([...])`）与集合语义相等比较
- **`list(1)` 等不可迭代实参静默返回空**：`list(1)` / `tuple(1)` / `dict(1)` 此前静默返回空容器。现按 CPython 报 `TypeError: 'int' object is not iterable`（`list` / `tuple` / `dict` 三个构造器统一修正，`set` / `frozenset` 原本已报错）
- **嵌套用户调用内的挂起被跳过重放**：排序比较函数内 `sleep` 等场景中，挂起发生在内建方法内部嵌套的用户调用里时，调用结果被误当作「独立调用已完成」返回 None，语句恢复时被跳过重放，得到半成品结果（排序未生效）。现按「调用栈是否留有嵌套帧」判定：嵌套调用内的挂起必须整句重放

### 新增

- **`bytes()` 构造函数与 bytes 方法族**：`bytes` 类型此前仅支持 `b'...'` 字面量，`bytes(3)` 报 `NameError`。现支持 `bytes(整数)`（零填充）、`bytes(可迭代)`（0-255，越界报 `ValueError`）、`bytes(str, encoding)`、`bytes(bytes)`（拷贝）；方法族补齐 `decode` / `hex` / `upper` / `lower` / `title` / `strip` / `lstrip` / `rstrip` / `split` / `replace` / `find` / `index` / `count` / `startswith` / `endswith` / `join` / `center` / `ljust` / `rjust`（`bytes` 字面量实例的方法查找同步接通）
- **`format()` 内建**：`format(value, spec)` 此前缺失（`NameError`）。现复用 `str.format` 的格式说明符驱动，支持宽度 / 对齐 / 分组（`,` / `_`）/ 精度 / 进制等全部既有 spec
- **`dir()` 内建**：列出对象属性（用户类实例含实例属性与方法、类对象含类方法与类属性、模块含成员），结果排序；内置类型字面量实例暂返回空列表（已知限制，见已知问题清单 P2-10）
- **int 方法**：`bit_length` / `bit_count` / `to_bytes(length, byteorder, signed=False)` / `from_bytes(bytes, byteorder, signed=False)`（越界按 CPython 报 `OverflowError`，负数转无符号报 `can't convert negative int to unsigned`）；**float 方法**：`is_integer` / `as_integer_ratio`（Infinity / NaN 按 CPython 报 `OverflowError`）；**str 方法**：`encode`（UTF-8）/ `format_map(mapping)`

### 变更

- **集合方法接受任意可迭代**：`union` / `intersection` / `difference` / `symmetric_difference` / `issubset` / `issuperset` / `isdisjoint` 此前要求实参为 set（否则报 `TypeError`），现与 CPython 一致接受任意可迭代（`{1, 2}.union([9])`）；新增原地更新族 `update` / `intersection_update` / `difference_update` / `symmetric_difference_update`
- **`dict_items` 视图相等按集合语义**：`d1.items() == d2.items()` 此前恒为 `False`（引用比较），现与顺序无关逐对比较（`dict_keys` 同语义）；`!=` 同步支持

### 破坏性变更 (Breaking Changes)

- **全局命名空间移除迭代器与 `dict` 视图类型名**：`list_iterator` / `dict_keyiterator` / `dict_keys` / `dict_values` 等名字不再是内建名（`isinstance(it, list_iterator)` 现报 `NameError`，与 CPython 一致）。此前以这些名字定义变量的脚本不再被覆盖，此前依赖这些内建名的脚本需要改用 `type(x).__name__` 比较
- **集合运算方法对非可迭代的实参**：`{1}.union(5)` 报错文案从 `union() argument must be a set` 变为 `'int' object is not iterable`
- **此前静默通过的错误现在报错**：`list(1)` / `tuple(1)` / `dict(1)` 等不可迭代实参从返回空容器改为报 `TypeError`

### 测试

- 新增 7 个行为一致性测试：`lang_iter_gen`（生成器 iter 语义）、`lang_iter_view`（`dict_items` 视图与类型名）、`err_dict_mutate`（字典迭代中增删键的 RuntimeError 可捕获）、`lang_user_sort`（用户类排序 / 反射 / min-max / 混合类型错误）、`lang_bytes_methods`（bytes 构造与方法族）、`lang_num_methods`（int/float 方法与 `format()`）、`edge_set_iterable`（集合可迭代实参与原地更新族），并入 `expected.json`（共 184 个用例全部通过，既有条目 `expected` 零变更），挂起测试 22 个用例通过
- 差分审计（45 例）保持 42/45 相同，剩余 3 条分歧全部为既定不对齐项（P2-2 两条文案差异与 P2-4 哈希数值）

## [0.5.0-alpha.7] - 2026-09-25

本版修复 P1-13（语句重放时并列调用的副作用重复执行），并按新的注释规范完成全量注释规范化

### 修复

- **语句重放时并列调用的副作用重复执行（P1-13）**：`print("g:", g(1, 2) + g(1, 2) + g(2, 1))`（`g` 内含 `sleep`）此前会把副作用执行 5 次（`log: [(1, 2), (1, 2), (2, 1), (1, 2), (1, 2)]`，CPython 为 3 条），实参互不相同的并列调用同样受影响。根因：`sleep` 挂起发生在表达式求值中途时，语句会整句重头重执行，其中**已完成的兄弟调用**被重新求值——这些调用的帧已被上一轮取走或从不曾挂起，函数体被完整重跑。修复分三部分：调用帧记录创建时的调用节点并按节点匹配（同一语句中字面相同的两次调用是不同 AST 节点，防止前一次求值取走后一次调用的帧）；完成的用户调用按节点记录返回值与实参签名，整句重头重执行的语句内无帧且实参匹配的调用直接短路取缓存（函数体不再执行，副作用不重复）；挂起帧记录「整句重头」与「精确续延」两种恢复方式，只有前者允许短路（循环体从挂起语句精确续延时，后续迭代的新逻辑调用不受影响）。生成器步（`_current_generator != null`）与推导式 / 生成器表达式元素求值（`_gen_walk_depth` 深度大于 0）内不参与短路——那里的调用是后续元素的新逻辑调用

### 变更

- **注释规范化（交接文档 7.4 新规）**：全库移除注释中的「与 CPython 一致」类等同性对比（仅保留差异说明）、版本历史信息与问题编号（`P0-12` 等），注释内的 `;` 统一改为逗号——注释只描述当前代码的约束与语义，历史与根因由 `CHANGELOG` 承担。`pygds.gd` 约 70 处、18 个测试模块的头注释同步规范化
- **测试注释头规范化连带**：`py_package/tests/` 18 个模块的头注释去掉版本 / 编号引用后 `expected.json` 的 `source` 字段同步更新（各用例 `expected` 输出零变更），并新增 `lang_sleep_call_replay`（P1-13 场景回归，共 177 个用例全部通过）

### 测试

- 新增 1 个行为一致性测试：`lang_sleep_call_replay`（并列调用的副作用只执行一次、实参互不相同的并列调用、递归调用、循环体内调用、嵌套函数内并列调用），并入 `expected.json`（共 177 个用例全部通过，既有条目 `expected` 零变更），挂起测试 22 个用例通过
- 12 个挂起重放变体（并列 / 递归 / 循环 / 嵌套 / 单行体 / 实参互异）与 CPython 输出逐一比对一致
- 差分审计（45 例）在可修复集上保持归零

## [0.5.0-alpha.6] - 2026-09-24

本版完成「可修复集 21 条」的清账（P0-3 ~ P0-12、P1-19 ~ P1-29），差分审计脚本（45 例）在可修复集上归零，剩余分歧全部为既定不对齐项（P2 类文案差异与 `random` / 哈希数值的稳定化差异）

### 新增

- **括号内换行（隐式续行）与反斜杠续行（P1-19）**：跨行的括号表达式、列表/字典/集合字面量、函数调用实参此前报 `Unexpected token '<newline>'`，现与 CPython 一致；行尾 `\` 吞掉换行继续同一逻辑行，`print(1, 2,)` 等调用实参尾随逗号也一并支持；括号未闭合到文件末尾时按 CPython 报 `SyntaxError: '(' was never closed`（文案对齐）
- **`try` / `else` 子句（P1-21）**：`else` 体在 try 体正常结束时执行（`return` / `break` / `continue` 跳出时不执行）；else 体抛出的异常不被同一 try 的 `except` 捕获；`finally` 与挂起恢复（`try_stage` 新增 `"else"` 阶段）均正确组合
- **用户类 `__getitem__` / `__setitem__` / `__delitem__`（P1-24）**：此前报 `'C' object is not subscriptable`（或在解析期拒绝 `C()[1] = 'x'`），现在三个下标协议均桥接到用户方法（与 `__len__` 同一桥接模式），方法内 `raise` 的异常正确传播；`D()[2] = 1` 等以「调用结果」为目标的下标赋值也正确解析
- **用户类 `__int__` / `__float__`（P1-25）**：`int(C())` / `float(C())` 此前报 `TypeError`，现在按 CPython 调用用户方法并校验返回类型（`__int__` 返回非 int 报 `__int__ returned non-int (type X)`）；顺带支持 `__index__`
- **真正的序列迭代器（P0-12 / P1-28）**：`iter()` 对 list / tuple / str / range / dict / set 返回一等迭代器对象——持有原容器引用（活动视图，`lst.append(3)` 后迭代能取到新元素）、耗尽后再迭代为空、`iter(it)` 返回自身；类型名与 CPython 对齐（`list_iterator` / `tuple_iterator` / `str_ascii_iterator`（纯 ASCII 字符串）/ `str_iterator` / `range_iterator` / `dict_keyiterator` / `set_iterator`，均已注册供 `type()` 与 `isinstance` 判定），`repr` 为 `<list_iterator object>` 形式
- **`hasattr` 内置函数（P1-29）**：按 try-getattr 语义实现，属性不存在返回 `False`；非 `AttributeError` 的错误原样传播不吞掉。同时修正类对象属性查找失败的行为——`getattr(cls, name)` 此前静默返回 `None`，现在按 CPython 报 `AttributeError: type object 'X' has no attribute 'Y'`（`getattr` 的默认值参数不受影响）

### 修复

- **嵌套容器的相等判定失效（P0-3，回归修复）**：涉及「容器套容器」的相等、成员判定、`index` / `count` / `remove` 全部失效且不报错（`[[1]] == [[1]]` 得 `False`、`(2, 'b') in [(1, 'a'), (2, 'b')]` 得 `False`）。这是 v0.5.0 线内唯一的严重性退步：v0.4.0 / alpha.2 此处报 `RuntimeError`（大声失败），alpha.3 为接入用户类 `__eq__` 时改为静默错值。现给 `DSLList` / `DSLTuple` / `DSLDict` 补齐 `_dsl_eq`（逐元素递归值比较，字典按键集合与对应值比较）
- **负数整除与取模语义错误（P0-4）**：Godot 对 int 的 `/` 向零截断、`%` 符号跟随被除数（C 语义），导致 `-7 // 2` 得 `-3`、`-7 % 2` 得 `-1`。现按 CPython 规则修正：整数 `//` 向负无穷取整、整数 `%` 符号跟随除数、float 的 `%` 改用 `a - b * floor(a / b)`、`divmod` 复用修正后的两者；`bool` 作为 `int` 子类同步修正。大整数（`-(2**62)` 量级）不丢精度
- **字面量转义序列未解码（P0-5）**：`\xNN` / `\NNN` / `\uNNNN` / `\UXXXXXXXX` / `\N{名称}` 此前原样保留（`len('\x41')` 得 4）。现全部解码；`\a` `\b` `\f` `\v` 补齐；字符串内反斜杠续行（`\` + 换行）生效；非法转义（`\xZZ` / `\x4` / `\u12`）报 `SyntaxError`；未识别转义（`\8` / `\p`）按 CPython 原样保留。bytes 语义与 CPython 一致：`b'\u4e2d'` / `b'\N{...}'` 原样保留、`b'\400'` 等八进制溢出截断为单字节、`b'\x00'` 支持 NUL 字节。`\N{名称}` 支持内置名称表（ASCII 全名与常用符号约 200 条；Godot 无 Unicode 名称库，表外名称报 `SyntaxError`，支持范围已在文档如实标注）。受 Godot 的 String 无法保存 NUL 的平台限制，str 字面量解码出 NUL 时报 `SyntaxError`（明确报错优于静默替换字符），bytes 侧不受影响
- **`sorted` / `min` / `max` 对元组与列表元素静默错序（P0-6 / P1-26）**：`DSLTuple` / `DSLList` 未实现 `magic_lt` 等，比较失败被静默当作 false，排序退化为原序。现实现字典序比较（首个不等元素定序、前缀短者更小），`list` 与 `tuple` 互比按 CPython 报 `TypeError`；`sorted` / `list.sort` / `min` / `max` 的比较失败改为**抛出 `TypeError`**（不再静默返回），错误文案跟随外层运算符
- **`min` / `max` 忽略 `key` 参数（P0-7）**：`max([1,2,3], key=lambda x: -x)` 此前得 `3`，现在按 CPython 用 key 值比较、返回原对象（每个候选只求值一次 key，并列时保留先出现者）；`min` / `max` 的多参数形式同样支持 `key`
- **`del` 的切片目标静默不生效（P0-8 / P1-22）**：`del a[1:3]` 此前既不删除也不报错。现支持切片删除（含 `del a[::2]` 扩展切片、负索引、越界区间）与**切片赋值**（`a[1:3] = [9]` 长度可变替换；扩展切片要求等长，否则报 `ValueError: attempt to assign sequence of size N to extended slice of size M`；右侧非可迭代报 `TypeError: must assign iterable to extended slice`；步长为 0 报 `ValueError: slice step cannot be zero`）；`del` 的未支持下标类型改为明确报 `TypeError`（不再静默通过）
- **`repr(None)` 返回 `<NoneType object>`（P0-9）**：现返回 `None`（`DSLNone` 补 `magic_repr`）；顺带补齐 `None` 的相等判定——`list.remove(x)` 等内置方法返回的 `None` 与 `None` 字面量按值相等（此前不同 `DSLNone` 实例引用比较为不等）
- **`chr()` 与 `%c` 越界不报错（P0-10）**：越界码点此前静默产出替换字符（或返回 `None`）。现按 CPython 校验：`chr()` 越界报 `ValueError: chr() arg not in range(0x110000)`，`%c` 越界报 `OverflowError: %c arg not in range(0x110000)`
- **`format` 千位分隔符被静默忽略（P0-11）**：`'{:,}'.format(1234567)` 此前不做分组。现实现 CPython 分组规则：十进制每 3 位；`_` 用于二进制/八进制/十六进制按 4 位分组；`,` 与 `_` 同时出现报 `ValueError: Cannot specify both ',' and '_'.`；`,` 与 `x/X/o/b` 同用报 `Cannot specify ',' with 'x'.`；与宽度/对齐/符号/`#` 前缀正确组合；f-string 的格式说明符（`f"{x:,}"`）同步支持
- **`None` 不能作字典键（P1-27）**：`{None: 1}` 此前报 `TypeError: unhashable type: NoneType`。现补 `DSLNone` 键编码（与集合键的 `"n"` 约定一致）；字符串键内部编码加 `s:` 前缀以与哨兵值区分（`{None: 1} == {'n': 1}` 正确为 `False`）
- **单行复合语句只支持表达式语句（P1-20）**：`if True: pass`、`def f(): return 1`、`class C: pass`、`try: pass`、`if True: import math` 等此前报 `Unexpected token`，现单行体支持全部语句类型
- **生成器表达式元素为元组时解析失败（P1-23）**：`list((x, y) for x in range(2))` 此前报 `SyntaxError: invalid syntax`，现正确解析（`for` 前的元组不再被拒绝）；同时按 CPython 规则收窄裸 genexpr 实参——`f(1, x for x in it)` / `f(x for x in it, 1)` 报 `SyntaxError: Generator expression must be parenthesized`
- **`dict(**kwargs)` 忽略关键字实参**：`dict(**{'x': 5})` 此前返回空字典（`api_dict_new` 未处理 kwargs），现正确并入；`dict` 子类（如 `Counter(**{...})`）同步修复

### 变更

- **`sorted` / `list.sort` / `min` / `max` 的比较失败从静默改为报错**：此前元素不可比较（如 `[1, 'a']`）时排序静默返回原序、`min` / `max` 静默返回取决于输入顺序的结果；现在统一抛 `TypeError: '<' not supported between instances of 'X' and 'Y'`。此前依赖「比较失败即跳过」的代码会开始报错——这正是「要么正确，要么明确报错」立场的落实
- **类对象的 `repr` 对用户类带模块前缀**：`print(C)` 现输出 `<class '__main__.C'>`（此前 `<class 'C'>`），与 CPython 一致；内建类型（`int` 等）不变
- **类对象属性查找失败改为报 `AttributeError`**：`getattr(cls, 'nope')` 此前静默返回 `None`，现在抛 `AttributeError`（`getattr` 的默认值形式不受影响）
- **字典键的内部编码调整**：字符串键在内部以 `s:` 前缀存储（配合 None 键的引入）；对脚本层不可见，键的顺序、取值、遍历行为均不变

### 测试

- 新增 18 个行为一致性测试：`lang_line_cont`（括号内换行/反斜杠续行/尾随逗号）/ `err_paren_unclosed`（括号未闭合）/ `lang_nested_eq`（嵌套容器相等）/ `lang_seq_compare`（字典序比较与 min/max key、排序报错）/ `lang_floordiv_mod`（负数整除取模与 divmod）/ `lang_escape`（str/bytes 转义解码与原始字符串）/ `lang_slice_assign`（切片赋值删除）/ `lang_one_line_stmt`（单行复合语句）/ `lang_try_else`（try/else）/ `lang_genexpr_tuple`（genexpr 元组元素）/ `lang_dunder_item`（下标协议）/ `lang_dunder_conv`（int/float 转换协议）/ `lang_iter_type`（真迭代器与类型名）/ `lang_none_key`（None 字典键）/ `lang_hasattr`（hasattr）/ `lang_repr_none`（repr(None)）/ `lang_chr_range`（chr/%c 越界）/ `lang_fmt_thousands`（千位分隔符），并入 `expected.json`（共 176 个用例全部通过，既有条目零变更），挂起测试 22 个用例通过
- 差分审计（`tests/mk_audit_cases.py` 生成 45 例 + `tests/diff_one.py` 比对）：可修复集 21 条全部分歧归零，剩余 3 条均为既定不对齐项（缺冒号与未结束字符串的解析期文案属 P2-2；`hash(None)` 数值属 PyGDS 稳定哈希与 CPython 进程相关哈希的既定差异）
- `test.py` 的期望值生成修正：此前只要 stderr 有输出就以其最后一行覆盖期望值，导致带 `SyntaxWarning` 的合法脚本（转义测试）期望值被警告文本污染；现仅在脚本以非零状态退出（解析失败）时取 stderr

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
