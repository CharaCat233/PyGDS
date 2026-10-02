# 行为一致性测试体系

PyGDS 的全部行为测试位于 `ci/cases/`，采用**双端实时比对**：每次运行现场执行 CPython 与 PyGDS 各一次，按用例声明的语义判定两端行为是否一致，不使用冻结的期望输出

## 组成

| 文件 | 职责 |
| :--- | :--- |
| [cases/](../../ci/cases/) | 全部用例，一个 `.py` 文件 = 一个职责，文件名编码职责 |
| [run_cases.gd](../../ci/run_cases.gd) | 双端运行器：进程内跑 PyGDS，经 `_pyrun.py` 现场跑 CPython，按判定矩阵裁决 |
| [_pyrun.py](../../ci/_pyrun.py) | CPython 执行垫片：运行单个用例，把 stdout/stderr/退出码以 JSON 文件交还（只执行不判定） |
| [lint_cases.py](../../ci/lint_cases.py) | 结构检查：头注元数据、命名注册表、文档条目一一对应 |
| [lint_md.py](../../ci/lint_md.py) | Markdown 机械自查（主动换行/围栏配对/MD038），自仓库根目录运行 |
| [lint_gd.py](../../ci/lint_gd.py) | GDScript 机械自查（行内多语句/代码区分号/`[br]` 规则），自仓库根目录运行 |

## 运行

```bash
# 全量 (CI 同款)
godot --headless --path . --script res://ci/run_cases.gd

# 只跑名称含 math 的用例
godot --headless --path . --script res://ci/run_cases.gd -- --filter=math

# 结构检查
python ci/lint_cases.py

# Markdown / GDScript 机械自查
python ci/lint_md.py
python ci/lint_gd.py
```

运行器自动探测 CPython 命令（Windows 先 `python`，Linux 先 `python3`）

## 命名注册表

文件名即职责说明，家族前缀如下：

| 前缀 | 职责域 | 示例 |
| :--- | :--- | :--- |
| `syntax_*` | 语句与表达式文法构造，含其编译期 `SyntaxError` | `syntax_for`、`syntax_try`、`syntax_match_dup_bind` |
| `comprehension_*` | 推导式家族，与 `syntax_for` 区分，可带 `_<方面>` 扩展 | `comprehension_list`、`comprehension_multi`、`comprehension_genexp` |
| `builtin_*` | 内置函数 | `builtin_print`、`builtin_isinstance` |
| `type_*` | 内置类型的构造、运算符行为与方法 | `type_str_methods`、`type_int` |
| `module_*` | 标准库模块 | `module_math`、`module_statistics` |
| `class_*` | 用户类系统（定义/继承/MRO/魔法方法/描述符） | `class_mro`、`class_descriptor` |
| `exception_*` | 异常体系与运行期错误语义 | `exception_hierarchy`、`exception_attrs` |
| `suspend_*` | 挂起系统（PyGDS 特有，CPython 侧以阻塞 sleep 为参照） | `suspend_sleep_replay` |
| `misc_*` | 未分类兜底：难以归入上述任一家族时使用 | - |

**边界规则**（用例归入「引入该行为的构造」）：

1. `for` 语句及其直接衍生（如循环目标拆包 `for x, y in xxx:`、`for...else`）属 `syntax_for` 家族；推导式里的 `for` 属推导式家族——`[for i in range(10)]` 的职责是 `comprehension_list`，不是 `syntax_for`
2. 类型方法的行为属 `type_*`，内置函数属 `builtin_*`，标准库模块属 `module_*`；`math.sqrt` 这类单一函数在行为多到值得独立时拆出 `module_math_sqrt`（拆分经验阈值：≥3 条独立行为或属已知脆弱区）
3. 用户类上实现 `__getitem__`/`__iter__`/`__hash__` 等协议属 `class_*`——测的是用户类系统，不是被模拟的内建类型
4. 测语法错误的用例挂在出错构造名下：`match` 的重复绑定编译错误 → `syntax_match_dup_bind`；测运行期捕获语义的属 `exception_*`
5. `misc_*` 是最后手段：新用例应优先按语义归入上述家族；只有确实无家可归时才落入 `misc_*`，并在文档条目中说明原因

## 头注元数据

每个用例文件顶部必须是如下格式的行首注释（运行器与 lint 均解析，缺省比对值为 `same_output`）：

```python
# duty: <描述该文件测什么>
# compare: same_output | same_exception | same_error | diverge
# anchor: CPython 3.12      # 可选: 文案核对所依据的 CPython 版本
# ref: P2-2                 # 可选: 已知问题编号或文档引用
# lines: same               # 可选: 报错用例附加行号比对 (见下)
# skip: <原因>              # 可选: 声明后跳过, 不参与判定
```

键接收英文（`duty` / `compare` / `anchor` / `ref` / `lines` / `lines`）和中文别名（`职责` / `比对` / `锚定` / `关联` / `行号` / `跳过`），解析器统一归一化为英文键。值中自 `" # "`（空格-井号-空格）起为行内尾注释，解析时剥离——如 `lines: same   # 报错在循环内` 合法且等价于 `lines: same`，`duty` 文本内请避免 `" # "`

正文内每个用例段前写一行注释，说明该段验证的 CPython 行为与对齐要点。微妙行为（求值顺序、边界值、既定差异）必须写明「CPython 做什么、为什么 PyGDS 必须一致」

## 判定矩阵

| 比对值 | 前置条件 | 通过条件 |
| :--- | :--- | :--- |
| `same_output` | 双端均正常完成 | stdout 归一化后逐字一致 |
| `same_exception` | 双端均报错 | 异常类名精确一致（**不支持子类容差**：`ValueError` vs `Exception` 不算匹配） |
| `same_error` | 双端均报错 | 类名与消息均一致（剥离 `" (line N)"` 尾缀并归一化后） |
| `diverge` | 已文档化的既定分歧 | 仅要求双端「报错与否」状态一致 |

**单边报错**（一侧报错另一侧正常完成）无论声明什么比对值一律 FAIL——它意味着 CPython 正常的代码 PyGDS 报错（或反之），是最刺眼的回归

**行号比对**：报错用例可附加 `# lines: same`（中文别名 `# 行号: same`）（仅支持运行期未捕获异常，解析期错误双端行号语义不同），运行器将 PyGDS 错误行的 `(line N)` 尾缀与 CPython traceback 末帧的 `File ..., line N` 核对，不一致判 `LINE`，任一侧无行号判 `LINE-UNKNOWN`。运行期错误行号是 README 兼容性矩阵宣称的特性，由此机制守住

失败细分（kind）：`ONESIDED`（单边报错）/ `ERRTYPE`（异常类不同）/ `ERRMSG`（消息不同）/ `OUT`（stdout 不同）/ `UNEXPECTED-ERR`（声明 same_output 但双端均报错）/ `NO-ERR`（声明报错但双端均正常）/ `CASE-ERR`（垫片/用例自身故障）/ `META`（未知比对值）

`same_exception` 到 `same_error` 的升级路径即文案对齐进度表：消息未对齐的先标 `same_exception`（关联 P2-2 等），对齐后升级为 `same_error`，此后 CI 守住消息不再回退

## 归一化（双端同规则）

- CRLF 转化为 LF
- 对象默认 repr：剥除 `" at 0x…>"`（内存地址每次运行都不同）与 `<__main__.` 模块限定前缀——PyGDS 的默认对象 repr 为简化形式 `<Foo object>`，属既定差异，暂由归一化吸收，后续可对齐后移除
- PyGDS 解析器未对齐文案的行首格式 `"Line N, Column M: "` 在提取错误时归一为 `"SyntaxError: "` 前缀——它本质上就是 `SyntaxError`，只是文案格式未对齐；此类用例应声明 `same_exception`（类名可对齐），文案对齐后升级 `same_error`

归一化集合必须保持极小，任何需要「为单个用例加归一化规则」的情况都是坏味道，应改写用例

## 用例书写规范（确定性）

双端比对要求用例在 **同端两次运行之间** 结果稳定：

1. 不打印内存地址原值（默认 repr 除外，已归一化）、`time.time()` 原值、`random` 数值原值；随机行为测不变量（如「同 `seed` 产生同序列」「权重为 0 的元素不被抽出」）
2. `time.sleep` 用 `0.05` 量级的小值——CPython 侧是真实阻塞，大值会拖慢整套件；且低于 Windows 定时器量子的间隔（约 0.0156s）可能不前进，导致单调时钟类断言不确定
3. 不使用 `sys.exit` / `input` / 文件 IO
4. libm 中非 IEEE 正确舍入的函数（`cbrt` / `pow` / `exp` / `log` / 三角族）的浮点结果须 `round(..., N)` 后比对——glibc 与 Windows CRT 舍入不同；`sqrt` / `remainder` 为正确舍入可直接比对
5. 不测运行期构造字符串的 `is` 身份——单字符缓存与 strip 自返回是 CPython 版本相关实现细节（3.12.8 与 3.13 行为不同），只测字面量编译期身份与 `==` 语义
6. 报错类用例：未捕获异常收尾的标 `same_error`/`same_exception`，`try` 捕获后打印结果的按普通 `same_output` 处理

## 新增用例流程

1. 在 `ci/cases/` 新建 `<家族>_<主题>.py`：头注元数据 + 带注释的用例体
2. `python ci/lint_cases.py` —— 会提示补文档
3. 在 [behavioral.md](behavioral.md) 对应家族小节各补一条目（职责/比对/源文件链接，微妙行为附说明段）
4. `godot --headless --path . --script res://ci/run_cases.gd -- --filter=<用例名>` 单跑验证，再全量跑一遍
