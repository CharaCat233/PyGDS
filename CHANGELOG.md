# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

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
