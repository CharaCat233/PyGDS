# 行为一致性测试说明

本文档是 `ci/cases/` 全部用例的逐例说明：每个条目对应一个用例文件，写明其职责与比对语义。判定矩阵、命名注册表、用例书写规范与新增流程见 [ci.md](ci.md)。

比对值含义：`same_output` = 双端 stdout 归一化后逐字一致；`same_exception` = 双端报错且异常类名精确一致；`same_error` = 双端报错且类名与消息均一致；`diverge` = 已文档化的既定分歧，仅要求双端报错状态一致。

## 语法与文法（syntax_*）

语句与表达式文法构造及其编译期 SyntaxError。边界原则：用例归入引入该行为的构造——`for` 内拆包属 `syntax_for`，推导式内的 `for` 属推导式家族；`match` 的重复绑定等编译期检查挂在 `syntax_match_*` 名下。

### syntax_annotation

- 职责: 函数参数/返回值/变量的类型注解
- 比对: `same_output`
- 源文件: [ci/cases/syntax_annotation.py](../../ci/cases/syntax_annotation.py)

### syntax_annotation_eval

- 职责: 变量与函数注解求值、注解字典与联合类型
- 比对: `same_output`
- 源文件: [ci/cases/syntax_annotation_eval.py](../../ci/cases/syntax_annotation_eval.py)

### syntax_arithmetic

- 职责: 算术运算符及优先级
- 比对: `same_output`
- 源文件: [ci/cases/syntax_arithmetic.py](../../ci/cases/syntax_arithmetic.py)

### syntax_assert

- 职责: `assert` 报错消息与 `AssertionError`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_assert.py](../../ci/cases/syntax_assert.py)

### syntax_assign_aug

- 职责: 增强赋值目标形态、原地方法与 `del` 括号目标
- 比对: `same_output`
- 源文件: [ci/cases/syntax_assign_aug.py](../../ci/cases/syntax_assign_aug.py)

### syntax_async_for_outside

- 职责: 顶层 `async for` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_async_for_outside.py](../../ci/cases/syntax_async_for_outside.py)

### syntax_async_name_reserved

- 职责: `async` 用作变量名触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_async_name_reserved.py](../../ci/cases/syntax_async_name_reserved.py)

### syntax_async_with_outside

- 职责: 顶层 `async with` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_async_with_outside.py](../../ci/cases/syntax_async_with_outside.py)

### syntax_augassign

- 职责: 增强赋值运算符求值
- 比对: `same_output`
- 源文件: [ci/cases/syntax_augassign.py](../../ci/cases/syntax_augassign.py)

### syntax_await_nonasync_fn

- 职责: 同步函数内 `await` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_await_nonasync_fn.py](../../ci/cases/syntax_await_nonasync_fn.py)

### syntax_await_outside

- 职责: 函数外 `await` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_await_outside.py](../../ci/cases/syntax_await_outside.py)

### syntax_bitwise

- 职责: 按位与或异或取反及移位运算
- 比对: `same_output`
- 源文件: [ci/cases/syntax_bitwise.py](../../ci/cases/syntax_bitwise.py)

### syntax_break_outside

- 职责: 循环外 `break` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_break_outside.py](../../ci/cases/syntax_break_outside.py)

### syntax_call_err1

- 职责: 调用处关键字参数后接位置参数的 `SyntaxError`
- 比对: `same_error`
- 源文件: [ci/cases/syntax_call_err1.py](../../ci/cases/syntax_call_err1.py)

### syntax_closure

- 职责: 闭包捕获、`nonlocal` 与多闭包共享环境
- 比对: `same_output`
- 源文件: [ci/cases/syntax_closure.py](../../ci/cases/syntax_closure.py)

### syntax_compare

- 职责: 比较/逻辑/成员/身份运算与短路
- 比对: `same_output`
- 源文件: [ci/cases/syntax_compare.py](../../ci/cases/syntax_compare.py)

### syntax_compare_chain

- 职责: 比较链 `a<b<c` 的结合求值
- 比对: `same_output`
- 源文件: [ci/cases/syntax_compare_chain.py](../../ci/cases/syntax_compare_chain.py)

### syntax_continue_outside

- 职责: 循环外 `continue` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_continue_outside.py](../../ci/cases/syntax_continue_outside.py)

### syntax_decorator

- 职责: 函数/类装饰器、带参装饰器叠加与求值次序
- 比对: `same_output`
- 源文件: [ci/cases/syntax_decorator.py](../../ci/cases/syntax_decorator.py)

### syntax_def

- 职责: 位置限定、可变与 kw-only 参数匹配
- 比对: `same_output`
- 源文件: [ci/cases/syntax_def.py](../../ci/cases/syntax_def.py)

### syntax_def_default

- 职责: 默认参数定义时求值与可变默认陷阱
- 比对: `same_output`
- 源文件: [ci/cases/syntax_def_default.py](../../ci/cases/syntax_def_default.py)

### syntax_def_error

- 职责: 实参数量与形式不匹配的 `TypeError`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_def_error.py](../../ci/cases/syntax_def_error.py)

### syntax_del

- 职责: `del` 变量/列表元素/字典键/属性
- 比对: `same_output`
- 源文件: [ci/cases/syntax_del.py](../../ci/cases/syntax_del.py)

### syntax_ellipsis

- 职责: `...` 字面量、真值、默认值与注解位置
- 比对: `same_output`
- 源文件: [ci/cases/syntax_ellipsis.py](../../ci/cases/syntax_ellipsis.py)

### syntax_expected_colon

- 职责: 缺冒号的解析错误文案对齐 (CPython: `expected ':'`)
- 比对: `same_error`
- 源文件: [ci/cases/syntax_expected_colon.py](../../ci/cases/syntax_expected_colon.py)

### syntax_escape

- 职责: `str`/`bytes` 转义序列解码与 `\N` 命名转义
- 比对: `same_output`
- 源文件: [ci/cases/syntax_escape.py](../../ci/cases/syntax_escape.py)

### syntax_float_literals

- 职责: `.5` 与 `1.` 点省略浮点字面量各位置
- 比对: `same_output`
- 源文件: [ci/cases/syntax_float_literals.py](../../ci/cases/syntax_float_literals.py)

### syntax_flow

- 职责: 分支/循环组合与 `break`/`continue`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_flow.py](../../ci/cases/syntax_flow.py)

### syntax_flow_scan

- 职责: `finally` 流控、局部名错误、PEP 479 与递归上限
- 比对: `same_output`
- 源文件: [ci/cases/syntax_flow_scan.py](../../ci/cases/syntax_flow_scan.py)

### syntax_for

- 职责: `for` 目标星形、嵌套、下标属性与解包错误文案
- 比对: `same_output`
- 源文件: [ci/cases/syntax_for.py](../../ci/cases/syntax_for.py)

### syntax_for_else

- 职责: `for...else` 正常结束与 `break` 的执行
- 比对: `same_output`
- 源文件: [ci/cases/syntax_for_else.py](../../ci/cases/syntax_for_else.py)

### syntax_fstring

- 职责: f-string 插值、格式说明符、转换与嵌套
- 比对: `same_output`
- 源文件: [ci/cases/syntax_fstring.py](../../ci/cases/syntax_fstring.py)

### syntax_fstring_debug

- 职责: f-string `=` 调试说明符与嵌套动态宽度
- 比对: `same_output`
- 源文件: [ci/cases/syntax_fstring_debug.py](../../ci/cases/syntax_fstring_debug.py)

### syntax_fstring_pep701

- 职责: 同引号嵌套、多行字段与注释等 PEP 701 形态
- 比对: `same_output`
- 源文件: [ci/cases/syntax_fstring_pep701.py](../../ci/cases/syntax_fstring_pep701.py)

### syntax_generic

- 职责: PEP 695 `type` 别名与泛型类/函数语法接受
- 比对: `same_output`
- 源文件: [ci/cases/syntax_generic.py](../../ci/cases/syntax_generic.py)

### syntax_global

- 职责: `global` 与 `nonlocal` 多名声明各作用域
- 比对: `same_output`
- 源文件: [ci/cases/syntax_global.py](../../ci/cases/syntax_global.py)

### syntax_if

- 职责: 连续 `if`/`elif` 条件各自独立求值
- 比对: `same_output`
- 源文件: [ci/cases/syntax_if.py](../../ci/cases/syntax_if.py)

### syntax_import

- 职责: 导入语句别名、星号导入与 `ImportError`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_import.py](../../ci/cases/syntax_import.py)

### syntax_import_future

- 职责: `__future__` 导入顶部位置与空操作语义
- 比对: `same_output`
- 源文件: [ci/cases/syntax_import_future.py](../../ci/cases/syntax_import_future.py)

### syntax_index_neg

- 职责: `list`/`str`/`tuple` 负索引与越界报错
- 比对: `same_output`
- 源文件: [ci/cases/syntax_index_neg.py](../../ci/cases/syntax_index_neg.py)

### syntax_inline_compound

- 职责: 行内复合语句分号归属与 `else` 接续
- 比对: `same_output`
- 源文件: [ci/cases/syntax_inline_compound.py](../../ci/cases/syntax_inline_compound.py)

### syntax_lambda

- 职责: `lambda` 定义/默认参数/闭包/`sort` `key`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_lambda.py](../../ci/cases/syntax_lambda.py)

### syntax_line_cont

- 职责: 括号内隐式续行与反斜杠续行
- 比对: `same_output`
- 源文件: [ci/cases/syntax_line_cont.py](../../ci/cases/syntax_line_cont.py)

### syntax_match

- 职责: `match` 字面量/捕获/通配/守卫/或模式
- 比对: `same_output`
- 源文件: [ci/cases/syntax_match.py](../../ci/cases/syntax_match.py)

### syntax_match_as_wildcard

- 职责: 模式 `as` 绑定通配符 `_` 触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_as_wildcard.py](../../ci/cases/syntax_match_as_wildcard.py)

### syntax_match_case_bare

- 职责: 空 `case` 缺模式触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_case_bare.py](../../ci/cases/syntax_match_case_bare.py)

### syntax_match_case_toplevel

- 职责: `case` 出现在顶层触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_case_toplevel.py](../../ci/cases/syntax_match_case_toplevel.py)

### syntax_match_class

- 职责: 类模式: `__match_args__`/值模式/错误
- 比对: `same_output`
- 源文件: [ci/cases/syntax_match_class.py](../../ci/cases/syntax_match_class.py)

### syntax_match_double_colon

- 职责: `case 1::` 双冒号触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_double_colon.py](../../ci/cases/syntax_match_double_colon.py)

### syntax_match_dstar_bare

- 职责: `{**}` 缺捕获名触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_dstar_bare.py](../../ci/cases/syntax_match_dstar_bare.py)

### syntax_match_dstar_mixed

- 职责: `**rest` 与其余键混用触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_dstar_mixed.py](../../ci/cases/syntax_match_dstar_mixed.py)

### syntax_match_dstar_wildcard

- 职责: `{**_}` 通配 rest 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_dstar_wildcard.py](../../ci/cases/syntax_match_dstar_wildcard.py)

### syntax_match_dup_bind

- 职责: 序列模式重复绑定同名触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_dup_bind.py](../../ci/cases/syntax_match_dup_bind.py)

### syntax_match_dup_key

- 职责: 映射模式 1 与 1.0 判为重复键报错
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_dup_key.py](../../ci/cases/syntax_match_dup_key.py)

### syntax_match_extra_token

- 职责: 模式后多余记号触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_extra_token.py](../../ci/cases/syntax_match_extra_token.py)

### syntax_match_guard_missing

- 职责: `if` 守卫缺表达式触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_guard_missing.py](../../ci/cases/syntax_match_guard_missing.py)

### syntax_match_kw_dup

- 职责: 类模式关键字参数重复触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_kw_dup.py](../../ci/cases/syntax_match_kw_dup.py)

### syntax_match_kw_pos

- 职责: 关键字模式后接位置模式触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_kw_pos.py](../../ci/cases/syntax_match_kw_pos.py)

### syntax_match_map

- 职责: 映射模式: 键/rest/嵌套/排除规则
- 比对: `same_output`
- 源文件: [ci/cases/syntax_match_map.py](../../ci/cases/syntax_match_map.py)

### syntax_match_multi_star

- 职责: 序列模式出现多个星号触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_multi_star.py](../../ci/cases/syntax_match_multi_star.py)

### syntax_match_noncase

- 职责: `match` 体内混入非 `case` 语句报错
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_noncase.py](../../ci/cases/syntax_match_noncase.py)

### syntax_match_or_bind

- 职责: 或模式各分支绑定名不一致报错
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_or_bind.py](../../ci/cases/syntax_match_or_bind.py)

### syntax_match_pattern_unclosed

- 职责: 模式方括号未闭合触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_pattern_unclosed.py](../../ci/cases/syntax_match_pattern_unclosed.py)

### syntax_match_reach_capture

- 职责: 捕获模式致后续 `case` 不可达报错
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_reach_capture.py](../../ci/cases/syntax_match_reach_capture.py)

### syntax_match_reach_wildcard

- 职责: 通配模式致后续 `case` 不可达报错
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_reach_wildcard.py](../../ci/cases/syntax_match_reach_wildcard.py)

### syntax_match_seq

- 职责: 序列模式: 星号捕获/无括号/嵌套
- 比对: `same_output`
- 源文件: [ci/cases/syntax_match_seq.py](../../ci/cases/syntax_match_seq.py)

### syntax_match_star_bare

- 职责: 裸 `*` 星号模式触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_star_bare.py](../../ci/cases/syntax_match_star_bare.py)

### syntax_match_star_toplevel

- 职责: 顶层 `*a` 星号模式触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_match_star_toplevel.py](../../ci/cases/syntax_match_star_toplevel.py)

### syntax_name_main

- 职责: `__name__`/`__file__` 与主守卫
- 比对: `same_output`
- 源文件: [ci/cases/syntax_name_main.py](../../ci/cases/syntax_name_main.py)

### syntax_number_literal

- 职责: 进制/下划线/科学计数法字面量
- 比对: `same_output`
- 源文件: [ci/cases/syntax_number_literal.py](../../ci/cases/syntax_number_literal.py)

### syntax_one_line_stmt

- 职责: `if`/`while`/`def`/`class` 单行复合语句
- 比对: `same_output`
- 源文件: [ci/cases/syntax_one_line_stmt.py](../../ci/cases/syntax_one_line_stmt.py)

### syntax_operator_matrix

- 职责: 运算符支持矩阵/反射右操作数/文案
- 比对: `same_output`
- 源文件: [ci/cases/syntax_operator_matrix.py](../../ci/cases/syntax_operator_matrix.py)

### syntax_paren_unclosed

- 职责: 左括号未闭合触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_paren_unclosed.py](../../ci/cases/syntax_paren_unclosed.py)

### syntax_pass

- 职责: `pass` 在类/函数/分支/循环/`try` 中占位
- 比对: `same_output`
- 源文件: [ci/cases/syntax_pass.py](../../ci/cases/syntax_pass.py)

### syntax_raise_from

- 职责: `raise from` 异常链与 `__cause__`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_raise_from.py](../../ci/cases/syntax_raise_from.py)

### syntax_raise_from_missing

- 职责: `raise from` 缺左侧表达式触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_raise_from_missing.py](../../ci/cases/syntax_raise_from_missing.py)

### syntax_recursion

- 职责: 斐波那契递归调用
- 比对: `same_output`
- 源文件: [ci/cases/syntax_recursion.py](../../ci/cases/syntax_recursion.py)

### syntax_recursion_mutual

- 职责: 阶乘递归与 is_even/is_odd 相互递归
- 比对: `same_output`
- 源文件: [ci/cases/syntax_recursion_mutual.py](../../ci/cases/syntax_recursion_mutual.py)

### syntax_return_outside

- 职责: 函数外 `return` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_return_outside.py](../../ci/cases/syntax_return_outside.py)

### syntax_scope

- 职责: `global` 与 `nonlocal` 声明改写外层变量
- 比对: `same_output`
- 源文件: [ci/cases/syntax_scope.py](../../ci/cases/syntax_scope.py)

### syntax_shortcircuit

- 职责: `and`/`or` 短路返回操作数与 `not`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_shortcircuit.py](../../ci/cases/syntax_shortcircuit.py)

### syntax_slice

- 职责: `list`/`str`/`tuple` 切片含步长与负界
- 比对: `same_output`
- 源文件: [ci/cases/syntax_slice.py](../../ci/cases/syntax_slice.py)

### syntax_slice_assign

- 职责: 切片赋值与切片删除含扩展步长
- 比对: `same_output`
- 源文件: [ci/cases/syntax_slice_assign.py](../../ci/cases/syntax_slice_assign.py)

### syntax_str_concat

- 职责: 相邻字符串字面量隐式连接
- 比对: `same_output`
- 源文件: [ci/cases/syntax_str_concat.py](../../ci/cases/syntax_str_concat.py)

### syntax_ternary

- 职责: 三目运算符基本与嵌套形式
- 比对: `same_output`
- 源文件: [ci/cases/syntax_ternary.py](../../ci/cases/syntax_ternary.py)

### syntax_ternary_nest

- 职责: 三目嵌套右结合与惰性求值
- 比对: `same_output`
- 源文件: [ci/cases/syntax_ternary_nest.py](../../ci/cases/syntax_ternary_nest.py)

### syntax_ternary_no_else

- 职责: 条件表达式缺 `else` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_ternary_no_else.py](../../ci/cases/syntax_ternary_no_else.py)

### syntax_trailing_comma

- 职责: `def`/`lambda` 参数表尾随逗号
- 比对: `same_output`
- 源文件: [ci/cases/syntax_trailing_comma.py](../../ci/cases/syntax_trailing_comma.py)

### syntax_try_else

- 职责: `try`/`else`/`finally` 执行时机
- 比对: `same_output`
- 源文件: [ci/cases/syntax_try_else.py](../../ci/cases/syntax_try_else.py)

### syntax_type_alias

- 职责: `type X = ...` 别名语句
- 比对: `same_output`
- 源文件: [ci/cases/syntax_type_alias.py](../../ci/cases/syntax_type_alias.py)

### syntax_unpack

- 职责: 多层与星号解包赋值及循环解包
- 比对: `same_output`
- 源文件: [ci/cases/syntax_unpack.py](../../ci/cases/syntax_unpack.py)

### syntax_unpack_args

- 职责: 调用处解包的错误路径（实参数量与键名不匹配）
- 比对: `same_output`
- 源文件: [ci/cases/syntax_unpack_args.py](../../ci/cases/syntax_unpack_args.py)

### syntax_unpack_call

- 职责: 调用处 `*`/`**` 解包实参
- 比对: `same_output`
- 源文件: [ci/cases/syntax_unpack_call.py](../../ci/cases/syntax_unpack_call.py)

### syntax_unpack_nested

- 职责: 嵌套解包、变量交换与多重赋值目标（下标/属性/键）
- 比对: `same_output`
- 源文件: [ci/cases/syntax_unpack_nested.py](../../ci/cases/syntax_unpack_nested.py)

### syntax_unpack_pep448

- 职责: 调用侧多次 `*`/`**` 混排与求值序
- 比对: `same_output`
- 源文件: [ci/cases/syntax_unpack_pep448.py](../../ci/cases/syntax_unpack_pep448.py)

### syntax_unpack_pep448_err

- 职责: 调用侧可迭代解包跟在关键字解包之后的 `SyntaxError`
- 比对: `same_error`
- 源文件: [ci/cases/syntax_unpack_pep448_err.py](../../ci/cases/syntax_unpack_pep448_err.py)

### syntax_unterminated_string

- 职责: 单引号未结束字符串的解析错误文案对齐 (detected at 为起始行)
- 比对: `same_error`
- 源文件: [ci/cases/syntax_unterminated_string.py](../../ci/cases/syntax_unterminated_string.py)

### syntax_unterminated_triple

- 职责: 三引号未结束字符串的解析错误文案对齐 (detected at 为扫描终止行)
- 比对: `same_error`
- 源文件: [ci/cases/syntax_unterminated_triple.py](../../ci/cases/syntax_unterminated_triple.py)

### syntax_unpack_star

- 职责: 列表/元组/集合字面量 `*` 解包
- 比对: `same_output`
- 源文件: [ci/cases/syntax_unpack_star.py](../../ci/cases/syntax_unpack_star.py)

### syntax_walrus

- 职责: 赋值表达式 `:=` 的作用域绑定
- 比对: `same_output`
- 源文件: [ci/cases/syntax_walrus.py](../../ci/cases/syntax_walrus.py)

### syntax_walrus_attr

- 职责: 赋值表达式以属性为目标触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_walrus_attr.py](../../ci/cases/syntax_walrus_attr.py)

### syntax_walrus_bare

- 职责: 裸赋值表达式作语句触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_walrus_bare.py](../../ci/cases/syntax_walrus_bare.py)

### syntax_walrus_comp_iter

- 职责: 赋值表达式用于推导式可迭代部分报错
- 比对: `same_error`
- 源文件: [ci/cases/syntax_walrus_comp_iter.py](../../ci/cases/syntax_walrus_comp_iter.py)

### syntax_walrus_del

- 职责: `del` 赋值表达式触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_walrus_del.py](../../ci/cases/syntax_walrus_del.py)

### syntax_walrus_rebind

- 职责: 赋值表达式重绑定推导式循环变量报错
- 比对: `same_error`
- 源文件: [ci/cases/syntax_walrus_rebind.py](../../ci/cases/syntax_walrus_rebind.py)

### syntax_walrus_subscript

- 职责: 赋值表达式以下标为目标触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_walrus_subscript.py](../../ci/cases/syntax_walrus_subscript.py)

### syntax_while_else

- 职责: `while...else` 正常退出与 `break`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_while_else.py](../../ci/cases/syntax_while_else.py)

### syntax_with

- 职责: `with` 语句文法主体, 多管理器次序, 流控穿越与 try/finally 对照
- 比对: `same_output`
- 源文件: [ci/cases/syntax_with.py](../../ci/cases/syntax_with.py)

### syntax_with_as_target

- 职责: `as` 目标全形态 (元组/嵌套/星形/属性/下标) 与解包失败时管理器仍退出
- 比对: `same_output`
- 源文件: [ci/cases/syntax_with_as_target.py](../../ci/cases/syntax_with_as_target.py)

### syntax_with_bare_as

- 职责: `with x as:` 缺目标触发解析期错误 (invalid syntax)
- 比对: `same_error`
- 源文件: [ci/cases/syntax_with_bare_as.py](../../ci/cases/syntax_with_bare_as.py)

### syntax_with_missing_colon

- 职责: `with` 头缺冒号触发解析期错误 (expected ':')
- 比对: `same_error`
- 源文件: [ci/cases/syntax_with_missing_colon.py](../../ci/cases/syntax_with_missing_colon.py)

### syntax_with_starred_as

- 职责: `with x as *a:` 裸星形目标触发解析期错误 (与 for 目标同规则)
- 比对: `same_error`
- 源文件: [ci/cases/syntax_with_starred_as.py](../../ci/cases/syntax_with_starred_as.py)

### syntax_with_trailing_comma

- 职责: `with` 管理器列表尾随逗号触发解析期错误 (invalid syntax)
- 比对: `same_error`
- 源文件: [ci/cases/syntax_with_trailing_comma.py](../../ci/cases/syntax_with_trailing_comma.py)

### syntax_yield

- 职责: 生成器 `next`/惰性/`return` 值
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield.py](../../ci/cases/syntax_yield.py)

### syntax_yield_closure

- 职责: 生成器结合闭包/默认参数/类方法
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_closure.py](../../ci/cases/syntax_yield_closure.py)

### syntax_yield_consumers

- 职责: `sum`/`sorted`/`zip` 等消费生成器
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_consumers.py](../../ci/cases/syntax_yield_consumers.py)

### syntax_yield_control

- 职责: `send`/`throw`/`close` 与 `yield from`
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_control.py](../../ci/cases/syntax_yield_control.py)

### syntax_yield_controlflow

- 职责: `yield` 嵌入分支/循环/`try` 及委托
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_controlflow.py](../../ci/cases/syntax_yield_controlflow.py)

### syntax_yield_dictcomp

- 职责: 字典推导式内 `yield` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_yield_dictcomp.py](../../ci/cases/syntax_yield_dictcomp.py)

### syntax_yield_errprop

- 职责: 生成器异常传播与 `return` 值封装
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_errprop.py](../../ci/cases/syntax_yield_errprop.py)

### syntax_yield_expr

- 职责: 表达式内 `yield`/`yield from` 求值与传播
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_expr.py](../../ci/cases/syntax_yield_expr.py)

### syntax_yield_from

- 职责: `yield from` 转发 `send`/`throw` 与记忆
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_from.py](../../ci/cases/syntax_yield_from.py)

### syntax_yield_lambda

- 职责: `lambda` 体内的 `yield` 生成器
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_lambda.py](../../ci/cases/syntax_yield_lambda.py)

### syntax_yield_listcomp

- 职责: 列表推导式内裸 `yield` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_yield_listcomp.py](../../ci/cases/syntax_yield_listcomp.py)

### syntax_yield_nested_call

- 职责: `yield` 子表达式嵌套调用不重放
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_nested_call.py](../../ci/cases/syntax_yield_nested_call.py)

### syntax_yield_outside

- 职责: 函数外 `yield` 触发解析期错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_yield_outside.py](../../ci/cases/syntax_yield_outside.py)

### syntax_yield_paren_comp

- 职责: 括号 `yield` 作推导式元素触发解析错误
- 比对: `same_error`
- 源文件: [ci/cases/syntax_yield_paren_comp.py](../../ci/cases/syntax_yield_paren_comp.py)

### syntax_yield_with

- 职责: 生成器与 `with` 交互 (体含 yield, as 跨步保持, close 与 throw 穿越退出路径)
- 比对: `same_output`
- 源文件: [ci/cases/syntax_yield_with.py](../../ci/cases/syntax_yield_with.py)

### syntax_yield_with_genexit

- 职责: `with` 抑制 GeneratorExit 后再次 yield 报 ignored (CPython 同文案)
- 比对: `same_error`
- 源文件: [ci/cases/syntax_yield_with_genexit.py](../../ci/cases/syntax_yield_with_genexit.py)

## 推导式（comprehension_*）

列表、字典、集合推导式与生成器表达式。与 `syntax_for` 的边界：推导式是独立构造，其内层 `for`/`if`、多 `for` 嵌套（`comprehension_multi`）等行为都归本家族。

### comprehension_dict

- 职责: 字典推导式的键值构造、过滤与多重 for
- 比对: `same_output`
- 源文件: [ci/cases/comprehension_dict.py](../../ci/cases/comprehension_dict.py)

### comprehension_genexp

- 职责: 生成器表达式惰性与 `next`/`sum`/`zip` 等消费
- 比对: `same_output`
- 源文件: [ci/cases/comprehension_genexp.py](../../ci/cases/comprehension_genexp.py)

### comprehension_genexp_tuple

- 职责: 生成器表达式产出元组元素与 `*args` 消费
- 比对: `same_output`
- 源文件: [ci/cases/comprehension_genexp_tuple.py](../../ci/cases/comprehension_genexp_tuple.py)

### comprehension_list

- 职责: 列表推导式与生成器表达式带过滤
- 比对: `same_output`
- 源文件: [ci/cases/comprehension_list.py](../../ci/cases/comprehension_list.py)

### comprehension_multi

- 职责: 多 `for`/多 `if` 的列表、集合、字典与生成器推导式
- 比对: `same_output`
- 源文件: [ci/cases/comprehension_multi.py](../../ci/cases/comprehension_multi.py)

### comprehension_set

- 职责: 集合推导式 `{x for ...}` 与条件
- 比对: `same_output`
- 源文件: [ci/cases/comprehension_set.py](../../ci/cases/comprehension_set.py)

## 内置函数（builtin_*）

内置命名空间中的函数：print/len/isinstance/getattr/iter/min/max/sorted 等。函数的报错路径（如 `chr` 越界）一并在此覆盖。

### builtin_abs_minmax

- 职责: `abs`/`min`/`max`/`sum` 内置函数各形态
- 比对: `same_output`
- 源文件: [ci/cases/builtin_abs_minmax.py](../../ci/cases/builtin_abs_minmax.py)

### builtin_error_text

- 职责: min/max/round/math 错误文案、print>>提示与函数 repr 对齐
- 比对: `same_output`
- 源文件: [ci/cases/builtin_error_text.py](../../ci/cases/builtin_error_text.py)

### builtin_ascii

- 职责: `ascii()` 的非 ASCII 转义与各类型 repr 形态
- 比对: `same_output`
- 源文件: [ci/cases/builtin_ascii.py](../../ci/cases/builtin_ascii.py)

### builtin_open

- 职责: `open()` 的文本/二进制读写、行迭代、seek 与异常文案
- 比对: `same_output`
- 源文件: [ci/cases/builtin_open.py](../../ci/cases/builtin_open.py)

二进制读/写以 `bytes` 为单位, 文本读采用惰性缓冲, 二进制比较段使用 `wb` 写入以规避 CPython 文本模式写盘的换行翻译差异

### builtin_wrappers

- 职责: 函数式 `staticmethod` / `classmethod` / `property` 与 `operator.index`
- 比对: `same_output`
- 源文件: [ci/cases/builtin_wrappers.py](../../ci/cases/builtin_wrappers.py)

函数式 property 在类体内赋值时经类创建钩子补全属性名 (CPython `__set_name__` 语义), `property.fget` / `fset` 可内省, `operator.index` 走 `__index__` 协议 (含用户类) 并对 float/str 报 CPython 文案

### builtin_any_all

- 职责: `any`/`all` 对各真值组合与空容器的判定
- 比对: `same_output`
- 源文件: [ci/cases/builtin_any_all.py](../../ci/cases/builtin_any_all.py)

### builtin_chr

- 职责: `chr` 与 `%c` 越界时的报错类型
- 比对: `same_output`
- 源文件: [ci/cases/builtin_chr.py](../../ci/cases/builtin_chr.py)

### builtin_convert

- 职责: `int`/`float`/`bool` 转换与混合运算结果类型
- 比对: `same_output`
- 源文件: [ci/cases/builtin_convert.py](../../ci/cases/builtin_convert.py)

### builtin_getattr

- 职责: `getattr`/`setattr`/`delattr` 属性操作
- 比对: `same_output`
- 源文件: [ci/cases/builtin_getattr.py](../../ci/cases/builtin_getattr.py)

### builtin_hasattr

- 职责: `hasattr` 判定与 `getattr` 缺省及报错
- 比对: `same_output`
- 源文件: [ci/cases/builtin_hasattr.py](../../ci/cases/builtin_hasattr.py)

### builtin_isinstance

- 职责: `isinstance`/`issubclass` 类型判定
- 比对: `same_output`
- 源文件: [ci/cases/builtin_isinstance.py](../../ci/cases/builtin_isinstance.py)

### builtin_issubclass

- 职责: `issubclass`/`isinstance` 元组嵌套短路
- 比对: `same_output`
- 源文件: [ci/cases/builtin_issubclass.py](../../ci/cases/builtin_issubclass.py)

### builtin_iter_gen

- 职责: `iter` 对生成器返回自身与耗尽不可重复
- 比对: `same_output`
- 源文件: [ci/cases/builtin_iter_gen.py](../../ci/cases/builtin_iter_gen.py)

### builtin_iter_type

- 职责: `iter` 各容器类型名、活动视图与耗尽
- 比对: `same_output`
- 源文件: [ci/cases/builtin_iter_type.py](../../ci/cases/builtin_iter_type.py)

### builtin_len_bad_args

- 职责: `len` 传参数量错误触发 `TypeError` 被捕获
- 比对: `same_output`
- 源文件: [ci/cases/builtin_len_bad_args.py](../../ci/cases/builtin_len_bad_args.py)

### builtin_map_filter

- 职责: `map`/`filter` 与 `lambda`/命名函数配合
- 比对: `same_output`
- 源文件: [ci/cases/builtin_map_filter.py](../../ci/cases/builtin_map_filter.py)

### builtin_minmax_getitem

- 职责: `min`/`max` 缺省与 `__getitem__` 旧式迭代
- 比对: `same_output`
- 源文件: [ci/cases/builtin_minmax_getitem.py](../../ci/cases/builtin_minmax_getitem.py)

### builtin_numeric_convert

- 职责: `int`/`float` 严格解析与错误文案
- 比对: `same_output`
- 源文件: [ci/cases/builtin_numeric_convert.py](../../ci/cases/builtin_numeric_convert.py)

### builtin_ord_chr_radix

- 职责: `ord`/`chr` 与 `hex`/`oct`/`bin` 进制转换
- 比对: `same_output`
- 源文件: [ci/cases/builtin_ord_chr_radix.py](../../ci/cases/builtin_ord_chr_radix.py)

### builtin_print_type

- 职责: `print` 的 `sep`/`end` 与 `type()` 查询
- 比对: `same_output`
- 源文件: [ci/cases/builtin_print_type.py](../../ci/cases/builtin_print_type.py)

### builtin_repr

- 职责: `repr(None)` 与内建类型 `repr`
- 比对: `same_output`
- 源文件: [ci/cases/builtin_repr.py](../../ci/cases/builtin_repr.py)

### builtin_round

- 职责: `round` 银行家舍入的二进制精确性
- 比对: `same_output`
- 源文件: [ci/cases/builtin_round.py](../../ci/cases/builtin_round.py)

### builtin_round_pow

- 职责: `round`/`pow`/`divmod` 内置函数
- 比对: `same_output`
- 源文件: [ci/cases/builtin_round_pow.py](../../ci/cases/builtin_round_pow.py)

### builtin_scan

- 职责: 数值方法、编码族、哈希不变量与两参 `iter`
- 比对: `same_output`
- 源文件: [ci/cases/builtin_scan.py](../../ci/cases/builtin_scan.py)

### builtin_sorted_zip

- 职责: 排序/反转/枚举/配对内置函数
- 比对: `same_output`
- 源文件: [ci/cases/builtin_sorted_zip.py](../../ci/cases/builtin_sorted_zip.py)

### builtin_type_dir

- 职责: `type` 三参建类/`dir`/`float.hex`
- 比对: `same_output`
- 源文件: [ci/cases/builtin_type_dir.py](../../ci/cases/builtin_type_dir.py)

### builtin_zip_strict

- 职责: `zip` `strict` 长度校验报错
- 比对: `same_output`
- 源文件: [ci/cases/builtin_zip_strict.py](../../ci/cases/builtin_zip_strict.py)

## 内置类型（type_*）

内建类型的构造、运算符语义（如负数整除取整）与方法。方法族较大时按方面拆分（`type_str_format`、`type_dict_view_live` 等）。

### type_bool_shortcircuit

- 职责: `and`/`or` 短路求值与操作数返回、真值判定
- 比对: `same_output`
- 源文件: [ci/cases/type_bool_shortcircuit.py](../../ci/cases/type_bool_shortcircuit.py)

### type_bytes_format

- 职责: `bytes` `%` 格式化占位符与对齐填充
- 比对: `same_output`
- 源文件: [ci/cases/type_bytes_format.py](../../ci/cases/type_bytes_format.py)

### type_bytearray

- 职责: bytearray 的构造/可变操作/算术/切片赋值与 bytes 互转
- 比对: `same_output`
- 源文件: [ci/cases/type_bytearray.py](../../ci/cases/type_bytearray.py)

bytearray 不可哈希 (字典键报 `unhashable type: 'bytearray'`), `bytes + bytearray` 得 bytes 而 `bytearray + bytes` 得 bytearray, 可变子类覆写 repr 前缀与方法工厂, 只读方法 (upper/decode/hex 等) 全量继承且返回 bytearray

### type_complex

- 职责: complex 类型与 `1j` 字面量的构造/算术/比较/字典键
- 比对: `same_output`
- 源文件: [ci/cases/type_complex.py](../../ci/cases/type_complex.py)

`1+0j` 与 `1` 为同键同哈希, 序比较报 `'<' not supported...`, 复数幂的整数指数走精确重复乘法, 非整数指数 (含 `**0.5`) 为 libm 极坐标路径, 比对须 `round(..., N)` (ci.md 规则 4)

### type_memoryview

- 职责: memoryview 的构造/下标/切片/只读与可写透传/tobytes/cast/release
- 比对: `same_output`
- 源文件: [ci/cases/type_memoryview.py](../../ci/cases/type_memoryview.py)

务实仅支持 B 格式一维视图, bytes 底层只读 (赋值报 `cannot modify read-only memory`), bytearray 底层可写透传, 释放后操作报 `operation forbidden on released memoryview object`

### type_bytes_methods

- 职责: `bytes` 构造形态与 `decode`/`hex`/`split` 等方法
- 比对: `same_output`
- 源文件: [ci/cases/type_bytes_methods.py](../../ci/cases/type_bytes_methods.py)

### type_bytes_range

- 职责: `bytes`/`range`/`dict` 视图类型行为
- 比对: `same_output`
- 源文件: [ci/cases/type_bytes_range.py](../../ci/cases/type_bytes_range.py)

### type_dict

- 职责: `dict` 构造与取值/遍历/增删方法
- 比对: `same_output`
- 源文件: [ci/cases/type_dict.py](../../ci/cases/type_dict.py)

### type_dict_iter_mutate

- 职责: 迭代中增删字典键触发可捕获 `RuntimeError`
- 比对: `same_output`
- 源文件: [ci/cases/type_dict_iter_mutate.py](../../ci/cases/type_dict_iter_mutate.py)

### type_dict_merge

- 职责: `dict` `|` 合并与 `**` 解包覆盖次序、`fromkeys`
- 比对: `same_output`
- 源文件: [ci/cases/type_dict_merge.py](../../ci/cases/type_dict_merge.py)

### type_dict_methods

- 职责: 字典 `pop`、`setdefault`、`update` 等
- 比对: `same_output`
- 源文件: [ci/cases/type_dict_methods.py](../../ci/cases/type_dict_methods.py)

### type_dict_none_key

- 职责: `None` 作字典键的存取与相等
- 比对: `same_output`
- 源文件: [ci/cases/type_dict_none_key.py](../../ci/cases/type_dict_none_key.py)

### type_dict_tuple_key

- 职责: 字典元组复合键 `d[1, 2]` 写法
- 比对: `same_output`
- 源文件: [ci/cases/type_dict_tuple_key.py](../../ci/cases/type_dict_tuple_key.py)

### type_dict_view_live

- 职责: 视图随字典实时变化、迭代中增删键报错
- 比对: `same_output`
- 源文件: [ci/cases/type_dict_view_live.py](../../ci/cases/type_dict_view_live.py)

### type_dict_view_types

- 职责: `dict` 视图类型名、`repr` 与相等比较
- 比对: `same_output`
- 源文件: [ci/cases/type_dict_view_types.py](../../ci/cases/type_dict_view_types.py)

### type_dunder_methods

- 职责: 内建容器 dunder 方法直调与元组不可删
- 比对: `same_output`
- 源文件: [ci/cases/type_dunder_methods.py](../../ci/cases/type_dunder_methods.py)

### type_frozenset

- 职责: `frozenset` 构造、集合运算、可哈希去重
- 比对: `same_output`
- 源文件: [ci/cases/type_frozenset.py](../../ci/cases/type_frozenset.py)

### type_function

- 职责: 函数与方法的类型类名及 `__name__`
- 比对: `same_output`
- 源文件: [ci/cases/type_function.py](../../ci/cases/type_function.py)

### type_generic_alias

- 职责: `list[int]` 等泛性别名对象与哈希相等
- 比对: `same_output`
- 源文件: [ci/cases/type_generic_alias.py](../../ci/cases/type_generic_alias.py)

### type_int_base

- 职责: `int(str, base)` 进制解析与 `base=0` 前缀
- 比对: `same_output`
- 源文件: [ci/cases/type_int_base.py](../../ci/cases/type_int_base.py)

### type_int_floordiv_mod

- 职责: 负数 // 与 % 向负无穷取整、余数符号随除数
- 比对: `same_output`
- 源文件: [ci/cases/type_int_floordiv_mod.py](../../ci/cases/type_int_floordiv_mod.py)

### type_int_intern

- 职责: 小整数 -5..256 驻留与 `bool` 单例
- 比对: `same_output`
- 源文件: [ci/cases/type_int_intern.py](../../ci/cases/type_int_intern.py)

### type_int_methods

- 职责: `int`/`float` 位方法与 `format()`
- 比对: `same_output`
- 源文件: [ci/cases/type_int_methods.py](../../ci/cases/type_int_methods.py)

### type_int_overflow

- 职责: 64 位整数边界、移位与溢出报错类型
- 比对: `same_output`
- 源文件: [ci/cases/type_int_overflow.py](../../ci/cases/type_int_overflow.py)

### type_list

- 职责: `list` 构造、增删改查方法与 `+`/`*` 运算
- 比对: `same_output`
- 源文件: [ci/cases/type_list.py](../../ci/cases/type_list.py)

### type_list_eq

- 职责: 嵌套容器递归相等与 `in`/`index`/`count`
- 比对: `same_output`
- 源文件: [ci/cases/type_list_eq.py](../../ci/cases/type_list_eq.py)

### type_list_sort

- 职责: `sort` 的 `key`/`reverse` 与 `sorted`
- 比对: `same_output`
- 源文件: [ci/cases/type_list_sort.py](../../ci/cases/type_list_sort.py)

### type_seq_compare

- 职责: `list`/`tuple` 字典序与 `sort` `key`
- 比对: `same_output`
- 源文件: [ci/cases/type_seq_compare.py](../../ci/cases/type_seq_compare.py)

### type_seq_concat

- 职责: 序列 `+`/`*` 的严格类型规则
- 比对: `same_output`
- 源文件: [ci/cases/type_seq_concat.py](../../ci/cases/type_seq_concat.py)

### type_set

- 职责: `set` 字面量/运算/子集/方法
- 比对: `same_output`
- 源文件: [ci/cases/type_set.py](../../ci/cases/type_set.py)

### type_set_methods

- 职责: 集合方法接受任意可迭代与原地更新族
- 比对: `same_output`
- 源文件: [ci/cases/type_set_methods.py](../../ci/cases/type_set_methods.py)

### type_slice

- 职责: `slice` 对象构造/属性/索引
- 比对: `same_output`
- 源文件: [ci/cases/type_slice.py](../../ci/cases/type_slice.py)

### type_str_format

- 职责: `str.format` 参数引用、对齐填充与转换标志
- 比对: `same_output`
- 源文件: [ci/cases/type_str_format.py](../../ci/cases/type_str_format.py)

### type_str_format_nested

- 职责: `format` 嵌套格式规格动态宽度与精度
- 比对: `same_output`
- 源文件: [ci/cases/type_str_format_nested.py](../../ci/cases/type_str_format_nested.py)

### type_str_format_thousands

- 职责: `format` 千位分隔符 `,` 与 `_` 及非法组合报错
- 比对: `same_output`
- 源文件: [ci/cases/type_str_format_thousands.py](../../ci/cases/type_str_format_thousands.py)

### type_str_identity

- 职责: 字符串驻留与 `is` 身份关系
- 比对: `same_output`
- 源文件: [ci/cases/type_str_identity.py](../../ci/cases/type_str_identity.py)

### type_str_methods

- 职责: `str` 常用方法：大小写/切分/查找等
- 比对: `same_output`
- 源文件: [ci/cases/type_str_methods.py](../../ci/cases/type_str_methods.py)

### type_str_methods2

- 职责: `splitlines`/`partition`/`is*` 方法
- 比对: `same_output`
- 源文件: [ci/cases/type_str_methods2.py](../../ci/cases/type_str_methods2.py)

### type_str_methods3

- 职责: `split`/`reversed`/`except as` 回归
- 比对: `same_output`
- 源文件: [ci/cases/type_str_methods3.py](../../ci/cases/type_str_methods3.py)

### type_str_methods_ext

- 职责: 字符串大小写/判定/填充等扩展方法
- 比对: `same_output`
- 源文件: [ci/cases/type_str_methods_ext.py](../../ci/cases/type_str_methods_ext.py)

### type_str_percent

- 职责: % 格式化: 宽度/符号/命名映射
- 比对: `same_output`
- 源文件: [ci/cases/type_str_percent.py](../../ci/cases/type_str_percent.py)

### type_str_split

- 职责: `split`/`rsplit` 的 `maxsplit` 行为
- 比对: `same_output`
- 源文件: [ci/cases/type_str_split.py](../../ci/cases/type_str_split.py)

### type_str_strip

- 职责: `strip`/`lstrip`/`rstrip` 带字符集参数
- 比对: `same_output`
- 源文件: [ci/cases/type_str_strip.py](../../ci/cases/type_str_strip.py)

### type_tuple

- 职责: 元组字面量各种书写形式与打印
- 比对: `same_output`
- 源文件: [ci/cases/type_tuple.py](../../ci/cases/type_tuple.py)

## 标准库模块（module_*）

PyGDS 内置的九个标准库模块（math/random/statistics/functools/itertools/collections/string/operator/time）。单一函数行为多到值得独立时拆出子文件（如 `module_math_sqrt`）。

### module_collections_deque

- 职责: collections.deque 的双向端操作/maxlen/rotate/索引与比较
- 比对: `same_output`
- 源文件: [ci/cases/module_collections_deque.py](../../ci/cases/module_collections_deque.py)

`maxlen` 溢出静默挤出一端, 不支持切片 (`sequence index must be integer, not 'slice'`), `pop`/`popleft` 空队列报 `pop from an empty deque`, `remove`/`index` 未命中报 `x is not in deque` (值 repr)

### module_collections_ordereddict

- 职责: collections.OrderedDict 的构造/顺序敏感相等/move_to_end/popitem
- 比对: `same_output`
- 源文件: [ci/cases/module_collections_ordereddict.py](../../ci/cases/module_collections_ordereddict.py)

OrderedDict 间相等比较按键序敏感, 与普通 dict 比较退化为键序无关 (CPython 同语义), `popitem(last=False)` 弹出首个键值对, 空字典报 `dictionary is empty`

### module_sys

- 职责: sys 模块基础面 (maxsize/version_info/byteorder/platform/intern/exit)
- 比对: `same_output`
- 源文件: [ci/cases/module_sys.py](../../ci/cases/module_sys.py)

`version`/`version_info` 固定为对齐目标 CPython 3.12 的形态 (platform 值随宿主 OS 映射, 比对用成员判定), `sys.exit` 抛 `SystemExit` (BaseException 子类), 未捕获时 PyGDS 无进程退出语义, 进入错误终态

### module_collections

- 职责: `Counter` 计数与 `defaultdict` 各工厂缺省
- 比对: `same_output`
- 源文件: [ci/cases/module_collections.py](../../ci/cases/module_collections.py)

### module_collections_defaultdict

- 职责: `defaultdict` 的 `repr` 与映射式构造
- 比对: `same_output`
- 源文件: [ci/cases/module_collections_defaultdict.py](../../ci/cases/module_collections_defaultdict.py)

### module_collections_most_common

- 职责: `most_common` 排序规则与前 `n` 截取
- 比对: `same_output`
- 源文件: [ci/cases/module_collections_most_common.py](../../ci/cases/module_collections_most_common.py)

### module_collections_namedtuple

- 职责: `namedtuple` 构造/`_make`/`_replace`
- 比对: `same_output`
- 源文件: [ci/cases/module_collections_namedtuple.py](../../ci/cases/module_collections_namedtuple.py)

### module_functools

- 职责: `reduce` 折叠与 `partial` 偏函数参数绑定
- 比对: `same_output`
- 源文件: [ci/cases/module_functools.py](../../ci/cases/module_functools.py)

### module_functools_cmp_to_key

- 职责: `cmp_to_key` 旧式比较函数接入排序
- 比对: `same_output`
- 源文件: [ci/cases/module_functools_cmp_to_key.py](../../ci/cases/module_functools_cmp_to_key.py)

### module_itertools

- 职责: `chain`/`product`/组合排列与 `islice`
- 比对: `same_output`
- 源文件: [ci/cases/module_itertools.py](../../ci/cases/module_itertools.py)

### module_itertools_accumulate

- 职责: `accumulate`/`pairwise`/`groupby`
- 比对: `same_output`
- 源文件: [ci/cases/module_itertools_accumulate.py](../../ci/cases/module_itertools_accumulate.py)

### module_itertools_groupby

- 职责: `groupby` 惰性 grouper 一次性与游标共享
- 比对: `same_output`
- 源文件: [ci/cases/module_itertools_groupby.py](../../ci/cases/module_itertools_groupby.py)

### module_itertools_infinite

- 职责: `repeat`/`cycle`/`count`/`takewhile`
- 比对: `same_output`
- 源文件: [ci/cases/module_itertools_infinite.py](../../ci/cases/module_itertools_infinite.py)

### module_itertools_tee

- 职责: `Counter`/`tee`/嵌套类/`%s` 回归
- 比对: `same_output`
- 源文件: [ci/cases/module_itertools_tee.py](../../ci/cases/module_itertools_tee.py)

### module_math

- 职责: `sqrt`/`floor`/三角/阶乘等基础函数
- 比对: `same_output`
- 源文件: [ci/cases/module_math.py](../../ci/cases/module_math.py)

### module_math_comb

- 职责: `comb`/`perm`/`prod`/`lcm` 计数函数
- 比对: `same_output`
- 源文件: [ci/cases/module_math_comb.py](../../ci/cases/module_math_comb.py)

### module_math_remainder

- 职责: `remainder`/`cbrt`/`quantiles` 分位数
- 比对: `same_output`
- 源文件: [ci/cases/module_math_remainder.py](../../ci/cases/module_math_remainder.py)

### module_operator

- 职责: `operator` 算术/比较/`itemgetter`
- 比对: `same_output`
- 源文件: [ci/cases/module_operator.py](../../ci/cases/module_operator.py)

### module_random

- 职责: `random` 结构性行为与 `seed` 复现
- 比对: `same_output`
- 源文件: [ci/cases/module_random.py](../../ci/cases/module_random.py)

### module_random_choices

- 职责: `random.choices` 对生成器取 `len` 报错
- 比对: `same_output`
- 源文件: [ci/cases/module_random_choices.py](../../ci/cases/module_random_choices.py)

### module_random_gauss

- 职责: `choices` 权重与 `gauss` 参数
- 比对: `same_output`
- 源文件: [ci/cases/module_random_gauss.py](../../ci/cases/module_random_gauss.py)

### module_random_types

- 职责: 抽样函数的序列类型拒绝规则
- 比对: `same_output`
- 源文件: [ci/cases/module_random_types.py](../../ci/cases/module_random_types.py)

### module_statistics

- 职责: `mean`/`median`/`stdev` 等统计量
- 比对: `same_output`
- 源文件: [ci/cases/module_statistics.py](../../ci/cases/module_statistics.py)

### module_string

- 职责: `string` 模块字符常量集
- 比对: `same_output`
- 源文件: [ci/cases/module_string.py](../../ci/cases/module_string.py)

### module_time

- 职责: `time.sleep` 挂起与时钟函数
- 比对: `same_output`
- 源文件: [ci/cases/module_time.py](../../ci/cases/module_time.py)

## 用户类系统（class_*）

类定义、继承与 MRO、`super()`、property/描述符、用户类实现的魔法方法协议（`__getitem__`/`__hash__`/`__int__` 等）。用户类实现协议测的是类系统本身，与内建类型行为区分。

### class_basic

- 职责: 类定义、类变量与类方法/静态方法
- 比对: `same_output`
- 源文件: [ci/cases/class_basic.py](../../ci/cases/class_basic.py)

### class_context_protocol

- 职责: 用户类上下文管理器协议语义 (退出参数形态, 抑制真值表, 异常取代与嵌套展开)
- 比对: `same_output`
- 源文件: [ci/cases/class_context_protocol.py](../../ci/cases/class_context_protocol.py)

### class_decorators

- 职责: 内建方法装饰器与任意装饰器叠加包装
- 比对: `same_output`
- 源文件: [ci/cases/class_decorators.py](../../ci/cases/class_decorators.py)

### class_descriptor

- 职责: `__get__`/`__set__` 描述符协议
- 比对: `same_output`
- 源文件: [ci/cases/class_descriptor.py](../../ci/cases/class_descriptor.py)

### class_diamond

- 职责: 菱形继承 `__init__` 链与 `super` 沿 MRO 协作
- 比对: `same_output`
- 源文件: [ci/cases/class_diamond.py](../../ci/cases/class_diamond.py)

### class_hooks

- 职责: 类创建钩子触发次序、链式调用与失败回滚
- 比对: `same_output`
- 源文件: [ci/cases/class_hooks.py](../../ci/cases/class_hooks.py)

### class_inherit

- 职责: 继承及类方法/静态方法被子类覆写
- 比对: `same_output`
- 源文件: [ci/cases/class_inherit.py](../../ci/cases/class_inherit.py)

### class_introspect

- 职责: 类与对象的内省属性及异常 traceback
- 比对: `same_output`
- 源文件: [ci/cases/class_introspect.py](../../ci/cases/class_introspect.py)

### class_magic_attr

- 职责: `__getattr__` 系列属性拦截
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_attr.py](../../ci/cases/class_magic_attr.py)

### class_magic_bool

- 职责: `__bool__`/`__len__` 真值协议与优先级
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_bool.py](../../ci/cases/class_magic_bool.py)

### class_magic_call

- 职责: 可调用对象 `__call__` 与 `callable`
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_call.py](../../ci/cases/class_magic_call.py)

### class_magic_eq_hash

- 职责: `__eq__`/`__hash__`/`__iter__` 用户协议
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_eq_hash.py](../../ci/cases/class_magic_eq_hash.py)

### class_magic_hash

- 职责: `hash()` 与自定义 `__hash__` 及不可哈希
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_hash.py](../../ci/cases/class_magic_hash.py)

### class_magic_order

- 职责: `__lt__`/`__gt__` 桥接排序与 `min`/`max`
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_order.py](../../ci/cases/class_magic_order.py)

### class_magic_protocol

- 职责: 用户类实现长度/成员/迭代协议
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_protocol.py](../../ci/cases/class_magic_protocol.py)

### class_magic_reflect

- 职责: `__radd__` 等反射运算与优先级
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_reflect.py](../../ci/cases/class_magic_reflect.py)

### class_magic_str_repr

- 职责: `__str__`/`__repr__` 定义与内置回退
- 比对: `same_output`
- 源文件: [ci/cases/class_magic_str_repr.py](../../ci/cases/class_magic_str_repr.py)

### class_mro

- 职责: 多继承 C3 线性化、`__mro__` 与属性查找
- 比对: `same_output`
- 源文件: [ci/cases/class_mro.py](../../ci/cases/class_mro.py)

### class_property

- 职责: `@property` 读写与只读拦截
- 比对: `same_output`
- 源文件: [ci/cases/class_property.py](../../ci/cases/class_property.py)

### class_property_slots

- 职责: 递归容器 `repr`、`property` 删除器与槽位限制
- 比对: `same_output`
- 源文件: [ci/cases/class_property_slots.py](../../ci/cases/class_property_slots.py)

### class_protocol_index

- 职责: `__index__` 协议下标、切片与错误传播
- 比对: `same_output`
- 源文件: [ci/cases/class_protocol_index.py](../../ci/cases/class_protocol_index.py)

### class_protocol_item

- 职责: 用户类 `__getitem__` 下标读写删协议
- 比对: `same_output`
- 源文件: [ci/cases/class_protocol_item.py](../../ci/cases/class_protocol_item.py)

### class_protocol_numconv

- 职责: 用户类 `__int__` 数值转换协议与错误类型
- 比对: `same_output`
- 源文件: [ci/cases/class_protocol_numconv.py](../../ci/cases/class_protocol_numconv.py)

### class_scope

- 职责: 类体作用域、类内推导式与 `property` 内 `super`
- 比对: `same_output`
- 源文件: [ci/cases/class_scope.py](../../ci/cases/class_scope.py)

### class_slots

- 职责: `__slots__` 白名单赋值与继承行为
- 比对: `same_output`
- 源文件: [ci/cases/class_slots.py](../../ci/cases/class_slots.py)

### class_star_bases

- 职责: 星参基类展开、重复与非类基类报错
- 比对: `same_output`
- 源文件: [ci/cases/class_star_bases.py](../../ci/cases/class_star_bases.py)

### class_super

- 职责: `super()` 零参与双参调用链
- 比对: `same_output`
- 源文件: [ci/cases/class_super.py](../../ci/cases/class_super.py)

### class_super_forms

- 职责: `super` 两参/类方法、异常多继承、`type` 三参建类与 `match` 捕获
- 比对: `same_output`
- 源文件: [ci/cases/class_super_forms.py](../../ci/cases/class_super_forms.py)

## 异常体系（exception_*）

异常层级与捕获语义（`BaseException`、继承捕获）、异常对象语义（str/repr/args）与运行期错误传播（生成器异常穿透、迭代器异常穿透）。语法类编译错误归 `syntax_*` 家族。

### exception_as_binding

- 职责: 除零异常经 `as` 绑定后取其消息
- 比对: `same_output`
- 源文件: [ci/cases/exception_as_binding.py](../../ci/cases/exception_as_binding.py)

### exception_attrs_internal

- 职责: 内部错误站点异常对象 `args`/`repr` 形态
- 比对: `same_output`
- 源文件: [ci/cases/exception_attrs_internal.py](../../ci/cases/exception_attrs_internal.py)

### exception_bare_except

- 职责: 裸 `except` 捕获任意类型异常
- 比对: `same_output`
- 源文件: [ci/cases/exception_bare_except.py](../../ci/cases/exception_bare_except.py)

### exception_base

- 职责: `BaseException` 捕获语义与自定义直接子类
- 比对: `same_output`
- 源文件: [ci/cases/exception_base.py](../../ci/cases/exception_base.py)

### exception_base_match

- 职责: `except` `Exception` 捕获子类异常
- 比对: `same_output`
- 源文件: [ci/cases/exception_base_match.py](../../ci/cases/exception_base_match.py)

### exception_divzero

- 职责: 裸 `except` 捕获除零异常
- 比对: `same_output`
- 源文件: [ci/cases/exception_divzero.py](../../ci/cases/exception_divzero.py)

### exception_err_shapes

- 职责: `format`/切片/幂/`setattr` 错误形态合集
- 比对: `same_output`
- 源文件: [ci/cases/exception_err_shapes.py](../../ci/cases/exception_err_shapes.py)

### exception_finally_after_except

- 职责: `except` 之后 `finally` 仍执行并改值
- 比对: `same_output`
- 源文件: [ci/cases/exception_finally_after_except.py](../../ci/cases/exception_finally_after_except.py)

### exception_finally_on_exc

- 职责: 异常被处理后外层 `finally` 仍执行
- 比对: `same_output`
- 源文件: [ci/cases/exception_finally_on_exc.py](../../ci/cases/exception_finally_on_exc.py)

### exception_finally_only

- 职责: 仅 `try`/`finally` 无 `except` 的流程
- 比对: `same_output`
- 源文件: [ci/cases/exception_finally_only.py](../../ci/cases/exception_finally_only.py)

### exception_gen_propagate

- 职责: 生成器中途异常经 `list`/`tuple`/`sorted` 传播
- 比对: `same_output`
- 源文件: [ci/cases/exception_gen_propagate.py](../../ci/cases/exception_gen_propagate.py)

### exception_hierarchy

- 职责: 内置异常继承捕获与捕获后状态隔离
- 比对: `same_output`
- 源文件: [ci/cases/exception_hierarchy.py](../../ci/cases/exception_hierarchy.py)

### exception_inherit_catch

- 职责: `ArithmeticError` 捕获除零异常
- 比对: `same_output`
- 源文件: [ci/cases/exception_inherit_catch.py](../../ci/cases/exception_inherit_catch.py)

### exception_iter_propagate

- 职责: 用户迭代器 `__next__` 异常穿透消费器
- 比对: `same_output`
- 源文件: [ci/cases/exception_iter_propagate.py](../../ci/cases/exception_iter_propagate.py)

### exception_multi_except

- 职责: 多个 `except` 子句按序命中正确分支
- 比对: `same_output`
- 源文件: [ci/cases/exception_multi_except.py](../../ci/cases/exception_multi_except.py)

### exception_nested_try

- 职责: 嵌套 `try` 由内层按类型捕获
- 比对: `same_output`
- 源文件: [ci/cases/exception_nested_try.py](../../ci/cases/exception_nested_try.py)

### exception_no_exc_path

- 职责: `try` 无异常时不进入 `except` 分支
- 比对: `same_output`
- 源文件: [ci/cases/exception_no_exc_path.py](../../ci/cases/exception_no_exc_path.py)

### exception_propagate

- 职责: 内层未匹配异常传播到外层捕获
- 比对: `same_output`
- 源文件: [ci/cases/exception_propagate.py](../../ci/cases/exception_propagate.py)

### exception_raise_basic

- 职责: `raise` 后经 `except` `as` 捕获并打印
- 比对: `same_output`
- 源文件: [ci/cases/exception_raise_basic.py](../../ci/cases/exception_raise_basic.py)

### exception_raise_in_handler

- 职责: `except` 内抛新异常被外层捕获
- 比对: `same_output`
- 源文件: [ci/cases/exception_raise_in_handler.py](../../ci/cases/exception_raise_in_handler.py)

### exception_repr

- 职责: 异常 `args`/`str`/`repr` 与 `repr` 引号选择
- 比对: `same_output`
- 源文件: [ci/cases/exception_repr.py](../../ci/cases/exception_repr.py)

### exception_reraise

- 职责: 裸 `raise` 重抛当前异常再次捕获
- 比对: `same_output`
- 源文件: [ci/cases/exception_reraise.py](../../ci/cases/exception_reraise.py)

### exception_specificity

- 职责: 多 `except` 按最具体类型命中
- 比对: `same_output`
- 源文件: [ci/cases/exception_specificity.py](../../ci/cases/exception_specificity.py)

### exception_str

- 职责: 异常 `str`/`args` 与 `KeyError` 文案特例
- 比对: `same_output`
- 源文件: [ci/cases/exception_str.py](../../ci/cases/exception_str.py)

### exception_tuple_except

- 职责: `except` 元组多类型命中其一
- 比对: `same_output`
- 源文件: [ci/cases/exception_tuple_except.py](../../ci/cases/exception_tuple_except.py)

### exception_tuple_mismatch

- 职责: 元组 `except` 不匹配时向外传播捕获
- 比对: `same_output`
- 源文件: [ci/cases/exception_tuple_mismatch.py](../../ci/cases/exception_tuple_mismatch.py)

### exception_tuple_multi

- 职责: 三类型元组 `except` 命中 `TypeError`
- 比对: `same_output`
- 源文件: [ci/cases/exception_tuple_multi.py](../../ci/cases/exception_tuple_multi.py)

### exception_type_mismatch

- 职责: 内层类型不匹配异常向外层传播
- 比对: `same_output`
- 源文件: [ci/cases/exception_type_mismatch.py](../../ci/cases/exception_type_mismatch.py)

### exception_uncaught_line

- 职责: 未捕获异常的行号报告（帧内报错行）
- 比对: `same_error`（并声明 `行号: same`，核对报错行号）
- 源文件: [ci/cases/exception_uncaught_line.py](../../ci/cases/exception_uncaught_line.py)

### exception_unbound_local

- 职责: `UnboundLocalError` 收集与层级
- 比对: `same_output`
- 源文件: [ci/cases/exception_unbound_local.py](../../ci/cases/exception_unbound_local.py)

## 挂起系统（suspend_*）

PyGDS 特有的挂起/恢复机制（`time.sleep` 触发 SLEEPING 挂起后的语句重放语义）。CPython 侧以阻塞式 sleep 为行为参照，双端最终产出一致的完整输出。

### suspend_call_replay

- 职责: 并列调用挂起重放副作用单次
- 比对: `same_output`
- 源文件: [ci/cases/suspend_call_replay.py](../../ci/cases/suspend_call_replay.py)

### suspend_comp_effect

- 职责: 推导式迭代源挂起的副作用单次
- 比对: `same_output`
- 源文件: [ci/cases/suspend_comp_effect.py](../../ci/cases/suspend_comp_effect.py)

### suspend_dunder

- 职责: 魔术方法内挂起的比较/真值与实参构造的重放
- 比对: `same_output`
- 源文件: [ci/cases/suspend_dunder.py](../../ci/cases/suspend_dunder.py)

### suspend_finally_raise

- 职责: `finally` 挂起时在途异常传播
- 比对: `same_output`
- 源文件: [ci/cases/suspend_finally_raise.py](../../ci/cases/suspend_finally_raise.py)

### suspend_groupby

- 职责: `groupby` 状态机跨语句存活与 `sleep` 重放
- 比对: `same_output`
- 源文件: [ci/cases/suspend_groupby.py](../../ci/cases/suspend_groupby.py)

### suspend_iter_consumers

- 职责: 生成器步内 `sleep` 后各内建消费器重放
- 比对: `same_output`
- 源文件: [ci/cases/suspend_iter_consumers.py](../../ci/cases/suspend_iter_consumers.py)

### suspend_lazy

- 职责: 推导式/生成器内 `sleep` 的惰性
- 比对: `same_output`
- 源文件: [ci/cases/suspend_lazy.py](../../ci/cases/suspend_lazy.py)

### suspend_match

- 职责: `match` 主题/守卫/体内挂起重放
- 比对: `same_output`
- 源文件: [ci/cases/suspend_match.py](../../ci/cases/suspend_match.py)

### suspend_nested

- 职责: 嵌套生成器挂起与异常传播
- 比对: `same_output`
- 源文件: [ci/cases/suspend_nested.py](../../ci/cases/suspend_nested.py)

### suspend_sideeffect

- 职责: 消费含 `sleep` 生成器的副作用
- 比对: `same_output`
- 源文件: [ci/cases/suspend_sideeffect.py](../../ci/cases/suspend_sideeffect.py)

### suspend_with_replay

- 职责: `with` 体与 `__exit__` 内挂起的重放 (进入标记不重复执行, P0-22 暂存叠加)
- 比对: `same_output`
- 源文件: [ci/cases/suspend_with_replay.py](../../ci/cases/suspend_with_replay.py)

