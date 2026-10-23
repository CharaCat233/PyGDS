# Behavioral Tests Reference

Per-case documentation for every test in `ci/cases/`: each entry maps to one case file and states its responsibility and comparison semantics. For the verdict matrix, naming registry, case authoring rules and the workflow for adding cases, see [ci.md](ci.md).

Comparison values: `same_output` = both ends complete and stdout matches verbatim after normalization; `same_exception` = both ends error with the exact same exception class; `same_error` = both ends error with the same class and message; `diverge` = a documented known divergence, only requiring both ends to agree on erroring vs completing.

## Syntax and Grammar (`syntax_*`)

Grammar constructs (statements and expressions) and their compile-time `SyntaxError`s. Boundary rule: a case belongs to the construct that introduces the behavior — unpacking inside a `for` target belongs to `syntax_for`, while the `for` inside a comprehension belongs to the comprehension family; compile-time checks such as duplicate `match` bindings live under `syntax_match_*`.

### syntax_annotation

- Responsibility: Type annotations on function parameters, return values and variables
- Comparison: `same_output`
- Source: [ci/cases/syntax_annotation.py](../../ci/cases/syntax_annotation.py)

### syntax_annotation_eval

- Responsibility: Annotation evaluation on variables and functions, annotation dicts and union types
- Comparison: `same_output`
- Source: [ci/cases/syntax_annotation_eval.py](../../ci/cases/syntax_annotation_eval.py)

### syntax_arithmetic

- Responsibility: Arithmetic operators and precedence
- Comparison: `same_output`
- Source: [ci/cases/syntax_arithmetic.py](../../ci/cases/syntax_arithmetic.py)

### syntax_assert

- Responsibility: `assert` error messages and `AssertionError`
- Comparison: `same_output`
- Source: [ci/cases/syntax_assert.py](../../ci/cases/syntax_assert.py)

### syntax_assign_aug

- Responsibility: Augmented assignment target forms, in-place methods and parenthesized `del` targets
- Comparison: `same_output`
- Source: [ci/cases/syntax_assign_aug.py](../../ci/cases/syntax_assign_aug.py)

### syntax_async_await_chain

- Responsibility: `await` evaluation semantics (nested synchronous coroutine driving, user `__await__` delegation, non-awaitable and invalid-iterator messages)
- Comparison: `same_output`
- Source: [ci/cases/syntax_async_await_chain.py](../../ci/cases/syntax_async_await_chain.py)

### syntax_async_def

- Responsibility: `async def` coroutine-object lifecycle (created unstarted, send/throw/close, reuse and non-None first-send messages)
- Comparison: `same_output`
- Source: [ci/cases/syntax_async_def.py](../../ci/cases/syntax_async_def.py)

### syntax_async_for_outside

- Responsibility: Top-level `async for` raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_async_for_outside.py](../../ci/cases/syntax_async_for_outside.py)

### syntax_async_gen

- Responsibility: async generator driving protocol (asend / athrow / aclose, manual `__anext__`, exhaustion after close)
- Comparison: `same_output`
- Source: [ci/cases/syntax_async_gen.py](../../ci/cases/syntax_async_gen.py)

### syntax_async_gen_return

- Responsibility: `return` with a value inside an async generator raises a parse error (CPython message)
- Comparison: `same_error`
- Source: [ci/cases/syntax_async_gen_return.py](../../ci/cases/syntax_async_gen_return.py)

### syntax_async_name_reserved

- Responsibility: `async` used as a variable name raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_async_name_reserved.py](../../ci/cases/syntax_async_name_reserved.py)

### syntax_async_never_awaited

- Responsibility: never-awaited warning (unstarted coroutines; CPython emits at GC, PyGDS at script end — an established shape difference)
- Comparison: `same_output`
- Source: [ci/cases/syntax_async_never_awaited.py](../../ci/cases/syntax_async_never_awaited.py)

### syntax_async_with_outside

- Responsibility: Top-level `async with` raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_async_with_outside.py](../../ci/cases/syntax_async_with_outside.py)

### syntax_augassign

- Responsibility: Augmented assignment operator evaluation
- Comparison: `same_output`
- Source: [ci/cases/syntax_augassign.py](../../ci/cases/syntax_augassign.py)

### syntax_async_yield

- Responsibility: `yield` inside `async def` legalized as an async generator (type, repr, async for, bare return, yielded values not auto-awaited)
- Comparison: `same_output`
- Source: [ci/cases/syntax_async_yield.py](../../ci/cases/syntax_async_yield.py)

### syntax_async_yieldfrom

- Responsibility: `yield from` inside an async function raises a parse error (CPython message)
- Comparison: `same_error`
- Source: [ci/cases/syntax_async_yieldfrom.py](../../ci/cases/syntax_async_yieldfrom.py)

### syntax_await_nonasync_fn

- Responsibility: `await` inside a non-async function raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_await_nonasync_fn.py](../../ci/cases/syntax_await_nonasync_fn.py)

### syntax_await_outside

- Responsibility: `await` outside a function raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_await_outside.py](../../ci/cases/syntax_await_outside.py)

### syntax_bitwise

- Responsibility: Bitwise and/or/xor/not and shift operations
- Comparison: `same_output`
- Source: [ci/cases/syntax_bitwise.py](../../ci/cases/syntax_bitwise.py)

### syntax_break_outside

- Responsibility: `break` outside a loop raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_break_outside.py](../../ci/cases/syntax_break_outside.py)

### syntax_call_err1

- Responsibility: `SyntaxError` for a positional argument after a keyword argument at a call site
- Comparison: `same_error`
- Source: [ci/cases/syntax_call_err1.py](../../ci/cases/syntax_call_err1.py)

### syntax_chain_assign

- Responsibility: chained subscript/attribute assignment parsing (`d["a"]=d["b"]=5`, I1-40); value evaluated once, targets assigned left-to-right
- Comparison: `same_output`
- Source: [ci/cases/syntax_chain_assign.py](../../ci/cases/syntax_chain_assign.py)

### syntax_closure

- Responsibility: Closure capture, `nonlocal`, and multiple closures sharing an environment
- Comparison: `same_output`
- Source: [ci/cases/syntax_closure.py](../../ci/cases/syntax_closure.py)

### syntax_compare

- Responsibility: Comparison/logical/membership/identity operators and short-circuiting
- Comparison: `same_output`
- Source: [ci/cases/syntax_compare.py](../../ci/cases/syntax_compare.py)

### syntax_compare_chain

- Responsibility: Chained comparison `a<b<c` evaluation
- Comparison: `same_output`
- Source: [ci/cases/syntax_compare_chain.py](../../ci/cases/syntax_compare_chain.py)

### syntax_compile_line

- Responsibility: line propagation and message shape of compile/exec syntax errors (the `(<file>, line N)` suffix carries the actual error line, a missing indented block raises `IndentationError: unexpected indent`, unclosed brackets report the opening line, and the line state resets across compiles)
- Comparison: `same_output`
- Source: [ci/cases/syntax_compile_line.py](../../ci/cases/syntax_compile_line.py)

Line assertions extract the `line N` message suffix (PyGDS has no re module, so plain string search is used); the full message of the missing-indent shape matches CPython (`IndentationError: unexpected indent (<t>, line 2)`), while other parse errors keep PyGDS's own wording (SyntaxError family types) and the dual-end assertions cover only the exception class and line

### syntax_continue_outside

- Responsibility: `continue` outside a loop raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_continue_outside.py](../../ci/cases/syntax_continue_outside.py)

### syntax_decorator

- Responsibility: Function/class decorators, stacked parameterized decorators and evaluation order
- Comparison: `same_output`
- Source: [ci/cases/syntax_decorator.py](../../ci/cases/syntax_decorator.py)

### syntax_def

- Responsibility: Positional-only, variadic and keyword-only parameter matching
- Comparison: `same_output`
- Source: [ci/cases/syntax_def.py](../../ci/cases/syntax_def.py)

### syntax_def_default

- Responsibility: Default parameters evaluated at definition time and the mutable default pitfall
- Comparison: `same_output`
- Source: [ci/cases/syntax_def_default.py](../../ci/cases/syntax_def_default.py)

### syntax_def_error

- Responsibility: `TypeError` for argument count/shape mismatch
- Comparison: `same_output`
- Source: [ci/cases/syntax_def_error.py](../../ci/cases/syntax_def_error.py)

### syntax_del

- Responsibility: `del` on variables/list elements/dict keys/attributes
- Comparison: `same_output`
- Source: [ci/cases/syntax_del.py](../../ci/cases/syntax_del.py)

### syntax_ellipsis

- Responsibility: `...` literal, truthiness, default values and annotation positions
- Comparison: `same_output`
- Source: [ci/cases/syntax_ellipsis.py](../../ci/cases/syntax_ellipsis.py)

### syntax_error_wording

- Responsibility: Parse errors unified to SyntaxError class (literal assignment / bare else / incomplete expr / illegal del target etc., I2-1)
- Comparison: `same_output`
- Source: [ci/cases/syntax_error_wording.py](../../ci/cases/syntax_error_wording.py)

### syntax_except_star

- Responsibility: `return` inside an `except*` block triggers compile-time `SyntaxError`
- Comparison: `same_error`
- Source: [ci/cases/syntax_except_star.py](../../ci/cases/syntax_except_star.py)

### syntax_except_star_mixed

- Responsibility: mixing `except` and `except*` on one try raises a parse error (CPython message)
- Comparison: `same_error`
- Source: [ci/cases/syntax_except_star_mixed.py](../../ci/cases/syntax_except_star_mixed.py)

### syntax_except_star_bare

- Responsibility: bare `except*:` without exception types raises a parse error (CPython message)
- Comparison: `same_error`
- Source: [ci/cases/syntax_except_star_bare.py](../../ci/cases/syntax_except_star_bare.py)

### syntax_expected_colon

- Responsibility: Parse error text alignment for a missing colon (CPython: `expected ':'`)
- Comparison: `same_error`
- Source: [ci/cases/syntax_expected_colon.py](../../ci/cases/syntax_expected_colon.py)

### syntax_escape

- Responsibility: `str`/`bytes` escape sequence decoding and `\N` named escapes
- Comparison: `same_output`
- Source: [ci/cases/syntax_escape.py](../../ci/cases/syntax_escape.py)

### syntax_float_literals

- Responsibility: `.5` and `1.` float literals with an omitted part, in all positions
- Comparison: `same_output`
- Source: [ci/cases/syntax_float_literals.py](../../ci/cases/syntax_float_literals.py)

### syntax_flow

- Responsibility: Branch/loop combinations with `break`/`continue`
- Comparison: `same_output`
- Source: [ci/cases/syntax_flow.py](../../ci/cases/syntax_flow.py)

### syntax_flow_scan

- Responsibility: `finally` control flow, local name errors, PEP 479 and recursion limits
- Comparison: `same_output`
- Source: [ci/cases/syntax_flow_scan.py](../../ci/cases/syntax_flow_scan.py)

### syntax_for

- Responsibility: `for` targets: starred, nested, subscript/attribute, and unpacking error messages
- Comparison: `same_output`
- Source: [ci/cases/syntax_for.py](../../ci/cases/syntax_for.py)

### syntax_for_else

- Responsibility: `for...else` on normal completion vs `break`
- Comparison: `same_output`
- Source: [ci/cases/syntax_for_else.py](../../ci/cases/syntax_for_else.py)

### syntax_fstring

- Responsibility: f-string interpolation, format specifiers, conversions and nesting (with explicit alignment the `0` flag becomes the fill character, explicit fill wins)
- Comparison: `same_output`
- Source: [ci/cases/syntax_fstring.py](../../ci/cases/syntax_fstring.py)

### syntax_fstring_debug

- Responsibility: f-string `=` debug specifier and nested dynamic width
- Comparison: `same_output`
- Source: [ci/cases/syntax_fstring_debug.py](../../ci/cases/syntax_fstring_debug.py)

### syntax_fstring_pep701

- Responsibility: PEP 701 forms: same-quote nesting, multi-line fields and comments
- Comparison: `same_output`
- Source: [ci/cases/syntax_fstring_pep701.py](../../ci/cases/syntax_fstring_pep701.py)

### syntax_future

- Responsibility: `_Feature` binding for `from __future__` imports (repr tuple form / attributes / `as` aliases / multi-feature imports / docstring position exemption)
- Comparison: `same_output`
- Source: [ci/cases/syntax_future.py](../../ci/cases/syntax_future.py)

### syntax_future_docstring

- Responsibility: the docstring exemption covers only the first string statement, a future import after a second string statement raises the position error
- Comparison: `same_error`
- Source: [ci/cases/syntax_future_docstring.py](../../ci/cases/syntax_future_docstring.py)

### syntax_future_names

- Responsibility: `all_feature_names` is a module inventory helper, not an importable feature (raises `future feature all_feature_names is not defined`)
- Comparison: `same_error`
- Source: [ci/cases/syntax_future_names.py](../../ci/cases/syntax_future_names.py)

### syntax_future_nested

- Responsibility: a `from __future__` import nested inside a function body raises the position error as well
- Comparison: `same_error`
- Source: [ci/cases/syntax_future_nested.py](../../ci/cases/syntax_future_nested.py)

### syntax_future_position

- Responsibility: a mid-file `from __future__` import raises `SyntaxError: from __future__ imports must occur at the beginning of the file`
- Comparison: `same_error`
- Source: [ci/cases/syntax_future_position.py](../../ci/cases/syntax_future_position.py)

### syntax_generic

- Responsibility: PEP 695 `type` aliases and generic class/function syntax acceptance
- Comparison: `same_output`
- Source: [ci/cases/syntax_generic.py](../../ci/cases/syntax_generic.py)

### syntax_global

- Responsibility: `global` and `nonlocal` declarations across scopes
- Comparison: `same_output`
- Source: [ci/cases/syntax_global.py](../../ci/cases/syntax_global.py)

### syntax_global_prior

- Responsibility: `global` declared after a name is used triggers compile-time `SyntaxError`
- Comparison: `same_error`
- Source: [ci/cases/syntax_global_prior.py](../../ci/cases/syntax_global_prior.py)

### syntax_if

- Responsibility: Consecutive `if`/`elif` conditions evaluated independently
- Comparison: `same_output`
- Source: [ci/cases/syntax_if.py](../../ci/cases/syntax_if.py)

### syntax_illegal_source2

- Responsibility: batch of missing compile-time constraints (illegal parameter forms / illegal del targets / empty paren import / unary not after comparison / yield from tuple / break in else body / bare lambda in conditional, I1-44)
- Comparison: `same_output`
- Source: [ci/cases/syntax_illegal_source2.py](../../ci/cases/syntax_illegal_source2.py)

### syntax_import

- Responsibility: Import aliases, star imports and `ImportError`
- Comparison: `same_output`
- Source: [ci/cases/syntax_import.py](../../ci/cases/syntax_import.py)

### syntax_import_dotted

- Responsibility: Error categories for dotted imports and relative imports (runtime ModuleNotFoundError / ImportError)
- Comparison: `same_output`
- Source: [ci/cases/syntax_import_dotted.py](../../ci/cases/syntax_import_dotted.py)

### syntax_import_future

- Responsibility: `__future__` imports must lead the file; no-op semantics
- Comparison: `same_output`
- Source: [ci/cases/syntax_import_future.py](../../ci/cases/syntax_import_future.py)

### syntax_index_neg

- Responsibility: Negative indexing and out-of-range errors on `list`/`str`/`tuple`
- Comparison: `same_output`
- Source: [ci/cases/syntax_index_neg.py](../../ci/cases/syntax_index_neg.py)

### syntax_int_max_str_config_order

- Responsibility: `int_max_str_digits` compilation precedes configuration (setting the limit then writing an overlong decimal literal in the same script still raises a compile-time SyntaxError)
- Comparison: `same_error`
- Source: [ci/cases/syntax_int_max_str_config_order.py](../../ci/cases/syntax_int_max_str_config_order.py)

A main module is fully compiled before it runs, so `sys.set_int_max_str_digits(4301)` in the same script cannot affect its own already-compiled literals — an overlong decimal literal (non-power-of-2 base) still raises the CPython `SyntaxError: Exceeds the limit (4300 digits)...` at compile time (the compile-time limit is the default 4300)

### syntax_int_max_str_literal

- Responsibility: Compile-time SyntaxError for overlong decimal literals (`int_max_str_digits`)
- Comparison: `same_error`
- Source: [ci/cases/syntax_int_max_str_literal.py](../../ci/cases/syntax_int_max_str_literal.py)

A decimal literal beyond the limit (default 4300) raises `SyntaxError: Exceeds the limit (4300 digits) for integer string conversion: value has 4301 digits; use sys.set_int_max_str_digits() to increase the limit - Consider hexadecimal for huge integer literals to avoid decimal conversion limits.` at compile time (power-of-2 literals are exempt at compile time, see module_sys_int_max_str)

### syntax_inline_compound

- Responsibility: Semicolon attribution in inline compound statements and `else` continuation
- Comparison: `same_output`
- Source: [ci/cases/syntax_inline_compound.py](../../ci/cases/syntax_inline_compound.py)

### syntax_invalid_escape

- Responsibility: Unrecognized escapes (`\8` `\9` `\p` etc.) emit SyntaxWarning (first occurrence per literal) while the literal is preserved; same for bytes (including `\u` and over-range octal)
- Comparison: `same_output`
- Source: [ci/cases/syntax_invalid_escape.py](../../ci/cases/syntax_invalid_escape.py)

Each literal warns at most once, with the first offending escape deciding the message (`invalid escape sequence '\X'` for unrecognized escapes, `invalid octal escape sequence '\400'` for over-range octal); adjacent literals warn independently. PyGDS has no warnings module, so the warning goes through the print channel (CPython routes it through the warnings machinery to stderr)

### syntax_lambda

- Responsibility: `lambda` definitions, default parameters, closures and `sort` `key`
- Comparison: `same_output`
- Source: [ci/cases/syntax_lambda.py](../../ci/cases/syntax_lambda.py)

### syntax_leading_zero

- Responsibility: Leading-zero decimal literal triggers compile-time `SyntaxError`
- Comparison: `same_error`
- Source: [ci/cases/syntax_leading_zero.py](../../ci/cases/syntax_leading_zero.py)

### syntax_line_cont

- Responsibility: Implicit line joining inside brackets and backslash continuation
- Comparison: `same_output`
- Source: [ci/cases/syntax_line_cont.py](../../ci/cases/syntax_line_cont.py)

### syntax_match

- Responsibility: `match` literal/capture/wildcard/guard/or patterns
- Comparison: `same_output`
- Source: [ci/cases/syntax_match.py](../../ci/cases/syntax_match.py)

### syntax_match_as_wildcard

- Responsibility: Pattern `as` binding to the wildcard `_` raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_as_wildcard.py](../../ci/cases/syntax_match_as_wildcard.py)

### syntax_match_case_bare

- Responsibility: Empty `case` missing a pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_case_bare.py](../../ci/cases/syntax_match_case_bare.py)

### syntax_match_case_toplevel

- Responsibility: `case` at top level raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_case_toplevel.py](../../ci/cases/syntax_match_case_toplevel.py)

### syntax_match_class

- Responsibility: Class patterns: `__match_args__`, value patterns, errors
- Comparison: `same_output`
- Source: [ci/cases/syntax_match_class.py](../../ci/cases/syntax_match_class.py)

### syntax_match_double_colon

- Responsibility: `case 1::` double colon raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_double_colon.py](../../ci/cases/syntax_match_double_colon.py)

### syntax_match_dstar_bare

- Responsibility: `{**}` missing a capture name raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_dstar_bare.py](../../ci/cases/syntax_match_dstar_bare.py)

### syntax_match_dstar_mixed

- Responsibility: `**rest` mixed with other keys raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_dstar_mixed.py](../../ci/cases/syntax_match_dstar_mixed.py)

### syntax_match_dstar_wildcard

- Responsibility: `{**_}` wildcard rest raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_dstar_wildcard.py](../../ci/cases/syntax_match_dstar_wildcard.py)

### syntax_match_dup_bind

- Responsibility: Duplicate name binding in a sequence pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_dup_bind.py](../../ci/cases/syntax_match_dup_bind.py)

### syntax_match_dup_key

- Responsibility: Mapping pattern treats `1` and `1.0` as duplicate keys and errors
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_dup_key.py](../../ci/cases/syntax_match_dup_key.py)

### syntax_match_extra_token

- Responsibility: Extra token after a pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_extra_token.py](../../ci/cases/syntax_match_extra_token.py)

### syntax_match_guard_missing

- Responsibility: `if` guard missing an expression raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_guard_missing.py](../../ci/cases/syntax_match_guard_missing.py)

### syntax_match_kw_dup

- Responsibility: Duplicate keyword argument in a class pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_kw_dup.py](../../ci/cases/syntax_match_kw_dup.py)

### syntax_match_kw_pos

- Responsibility: Keyword pattern after a positional pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_kw_pos.py](../../ci/cases/syntax_match_kw_pos.py)

### syntax_match_map

- Responsibility: Mapping patterns: keys/rest/nesting/exclusion rules
- Comparison: `same_output`
- Source: [ci/cases/syntax_match_map.py](../../ci/cases/syntax_match_map.py)

### syntax_match_multi_star

- Responsibility: Multiple stars in a sequence pattern raise a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_multi_star.py](../../ci/cases/syntax_match_multi_star.py)

### syntax_match_noncase

- Responsibility: A non-`case` statement inside a `match` body errors
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_noncase.py](../../ci/cases/syntax_match_noncase.py)

### syntax_match_or_bind

- Responsibility: Inconsistent bindings across or-pattern branches error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_or_bind.py](../../ci/cases/syntax_match_or_bind.py)

### syntax_match_pattern_unclosed

- Responsibility: Unclosed bracket in a pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_pattern_unclosed.py](../../ci/cases/syntax_match_pattern_unclosed.py)

### syntax_match_reach_capture

- Responsibility: Capture pattern making a later `case` unreachable errors
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_reach_capture.py](../../ci/cases/syntax_match_reach_capture.py)

### syntax_match_reach_wildcard

- Responsibility: Wildcard pattern making a later `case` unreachable errors
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_reach_wildcard.py](../../ci/cases/syntax_match_reach_wildcard.py)

### syntax_match_seq

- Responsibility: Sequence patterns: star captures, no parentheses, nesting
- Comparison: `same_output`
- Source: [ci/cases/syntax_match_seq.py](../../ci/cases/syntax_match_seq.py)

### syntax_match_star_bare

- Responsibility: Bare `*` star pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_star_bare.py](../../ci/cases/syntax_match_star_bare.py)

### syntax_match_star_toplevel

- Responsibility: Top-level `*a` star pattern raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_match_star_toplevel.py](../../ci/cases/syntax_match_star_toplevel.py)

### syntax_name_main

- Responsibility: `__name__`/`__file__` and the main guard
- Comparison: `same_output`
- Source: [ci/cases/syntax_name_main.py](../../ci/cases/syntax_name_main.py)

### syntax_nonlocal_unbound

- Responsibility: Unbound `nonlocal` and module-level declarations raise a compile-time `SyntaxError` (message aligned with CPython)
- Comparison: `same_output`
- Source: [ci/cases/syntax_nonlocal_unbound.py](../../ci/cases/syntax_nonlocal_unbound.py)

### syntax_number_literal

- Responsibility: Numeric literals: bases, underscores, scientific notation
- Comparison: `same_output`
- Source: [ci/cases/syntax_number_literal.py](../../ci/cases/syntax_number_literal.py)

### syntax_octal_escape

- Responsibility: Out-of-range octal escapes emit SyntaxWarning (I2-14; value still decoded, -W error upgrades to SyntaxError)
- Comparison: `same_output`
- Source: [ci/cases/syntax_octal_escape.py](../../ci/cases/syntax_octal_escape.py)

### syntax_one_line_stmt

- Responsibility: `if`/`while`/`def`/`class` one-line compound statements
- Comparison: `same_output`
- Source: [ci/cases/syntax_one_line_stmt.py](../../ci/cases/syntax_one_line_stmt.py)

### syntax_operator_matrix

- Responsibility: Operator support matrix, reflected right operands, messages
- Comparison: `same_output`
- Source: [ci/cases/syntax_operator_matrix.py](../../ci/cases/syntax_operator_matrix.py)

### syntax_paren_unclosed

- Responsibility: Unclosed left parenthesis raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_paren_unclosed.py](../../ci/cases/syntax_paren_unclosed.py)

### syntax_pass

- Responsibility: `pass` as a placeholder in classes/functions/branches/loops/`try`
- Comparison: `same_output`
- Source: [ci/cases/syntax_pass.py](../../ci/cases/syntax_pass.py)

### syntax_raise_from

- Responsibility: `raise from` exception chaining and `__cause__`
- Comparison: `same_output`
- Source: [ci/cases/syntax_raise_from.py](../../ci/cases/syntax_raise_from.py)

### syntax_raise_from_missing

- Responsibility: `raise from` missing the left-hand expression raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_raise_from_missing.py](../../ci/cases/syntax_raise_from_missing.py)

### syntax_recursion

- Responsibility: Fibonacci recursion
- Comparison: `same_output`
- Source: [ci/cases/syntax_recursion.py](../../ci/cases/syntax_recursion.py)

### syntax_recursion_mutual

- Responsibility: Factorial recursion and is_even/is_odd mutual recursion
- Comparison: `same_output`
- Source: [ci/cases/syntax_recursion_mutual.py](../../ci/cases/syntax_recursion_mutual.py)

### syntax_return_outside

- Responsibility: `return` outside a function raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_return_outside.py](../../ci/cases/syntax_return_outside.py)

### syntax_scope

- Responsibility: `global` and `nonlocal` declarations rebinding outer variables
- Comparison: `same_output`
- Source: [ci/cases/syntax_scope.py](../../ci/cases/syntax_scope.py)

### syntax_shortcircuit

- Responsibility: `and`/`or` short-circuit returning operands, and `not`
- Comparison: `same_output`
- Source: [ci/cases/syntax_shortcircuit.py](../../ci/cases/syntax_shortcircuit.py)

### syntax_slice

- Responsibility: Slicing on `list`/`str`/`tuple` with steps and negative bounds
- Comparison: `same_output`
- Source: [ci/cases/syntax_slice.py](../../ci/cases/syntax_slice.py)

### syntax_slice_assign

- Responsibility: Slice assignment and slice deletion, including extended steps
- Comparison: `same_output`
- Source: [ci/cases/syntax_slice_assign.py](../../ci/cases/syntax_slice_assign.py)

### syntax_str_concat

- Responsibility: Implicit concatenation of adjacent string literals
- Comparison: `same_output`
- Source: [ci/cases/syntax_str_concat.py](../../ci/cases/syntax_str_concat.py)

### syntax_subscript_tuple_slice

- Responsibility: mixed tuple + slice forms in subscripts (`M()[0, 1:3]` / `a[:, 1]` / `d[*a, 1]`, I1-41)
- Comparison: `same_output`
- Source: [ci/cases/syntax_subscript_tuple_slice.py](../../ci/cases/syntax_subscript_tuple_slice.py)

### syntax_tab_mix

- Responsibility: Inconsistent tab/space indentation triggers compile-time `TabError`
- Comparison: `same_error`
- Source: [ci/cases/syntax_tab_mix.py](../../ci/cases/syntax_tab_mix.py)

### syntax_ternary

- Responsibility: Conditional expressions: basic and nested forms
- Comparison: `same_output`
- Source: [ci/cases/syntax_ternary.py](../../ci/cases/syntax_ternary.py)

### syntax_ternary_nest

- Responsibility: Conditional expression right-associativity and lazy evaluation
- Comparison: `same_output`
- Source: [ci/cases/syntax_ternary_nest.py](../../ci/cases/syntax_ternary_nest.py)

### syntax_ternary_no_else

- Responsibility: Conditional expression missing `else` raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_ternary_no_else.py](../../ci/cases/syntax_ternary_no_else.py)

### syntax_trailing_comma

- Responsibility: Trailing commas in `def`/`lambda` parameter lists
- Comparison: `same_output`
- Source: [ci/cases/syntax_trailing_comma.py](../../ci/cases/syntax_trailing_comma.py)

### syntax_try_else

- Responsibility: `try`/`else`/`finally` execution timing
- Comparison: `same_output`
- Source: [ci/cases/syntax_try_else.py](../../ci/cases/syntax_try_else.py)

### syntax_type_alias

- Responsibility: `type X = ...` alias statement
- Comparison: `same_output`
- Source: [ci/cases/syntax_type_alias.py](../../ci/cases/syntax_type_alias.py)

### syntax_unpack

- Responsibility: Multi-level and starred unpacking assignment, and loop unpacking
- Comparison: `same_output`
- Source: [ci/cases/syntax_unpack.py](../../ci/cases/syntax_unpack.py)

### syntax_unpack_args

- Responsibility: Error paths of call-site unpacking (argument count and key mismatches)
- Comparison: `same_output`
- Source: [ci/cases/syntax_unpack_args.py](../../ci/cases/syntax_unpack_args.py)

### syntax_unpack_call

- Responsibility: `*`/`**` argument unpacking at call sites
- Comparison: `same_output`
- Source: [ci/cases/syntax_unpack_call.py](../../ci/cases/syntax_unpack_call.py)

### syntax_unpack_nested

- Responsibility: Nested unpacking, variable swapping and multiple assignment targets (subscript/attribute/key)
- Comparison: `same_output`
- Source: [ci/cases/syntax_unpack_nested.py](../../ci/cases/syntax_unpack_nested.py)

### syntax_unpack_pep448

- Responsibility: Multiple `*`/`**` mixed at call sites and evaluation order
- Comparison: `same_output`
- Source: [ci/cases/syntax_unpack_pep448.py](../../ci/cases/syntax_unpack_pep448.py)

### syntax_unpack_pep448_err

- Responsibility: Iterable unpacking after keyword unpacking at a call site raises a `SyntaxError`
- Comparison: `same_error`
- Source: [ci/cases/syntax_unpack_pep448_err.py](../../ci/cases/syntax_unpack_pep448_err.py)

### syntax_unterminated_string

- Responsibility: Parse error text alignment for an unterminated single-quoted string (detected-at is the start line)
- Comparison: `same_error`
- Source: [ci/cases/syntax_unterminated_string.py](../../ci/cases/syntax_unterminated_string.py)

### syntax_unterminated_triple

- Responsibility: Parse error text alignment for an unterminated triple-quoted string (detected-at is the scan-end line)
- Comparison: `same_error`
- Source: [ci/cases/syntax_unterminated_triple.py](../../ci/cases/syntax_unterminated_triple.py)

### syntax_unpack_star

- Responsibility: `*` unpacking in list/tuple/set literals
- Comparison: `same_output`
- Source: [ci/cases/syntax_unpack_star.py](../../ci/cases/syntax_unpack_star.py)

### syntax_walrus

- Responsibility: `:=` assignment expression scope binding
- Comparison: `same_output`
- Source: [ci/cases/syntax_walrus.py](../../ci/cases/syntax_walrus.py)

### syntax_walrus_attr

- Responsibility: Assignment expression with an attribute target raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_walrus_attr.py](../../ci/cases/syntax_walrus_attr.py)

### syntax_walrus_bare

- Responsibility: Bare assignment expression as a statement raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_walrus_bare.py](../../ci/cases/syntax_walrus_bare.py)

### syntax_walrus_comp_iter

- Responsibility: Assignment expression in a comprehension's iterable errors
- Comparison: `same_error`
- Source: [ci/cases/syntax_walrus_comp_iter.py](../../ci/cases/syntax_walrus_comp_iter.py)

### syntax_walrus_del

- Responsibility: `del` on an assignment expression raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_walrus_del.py](../../ci/cases/syntax_walrus_del.py)

### syntax_walrus_rebind

- Responsibility: Assignment expression rebinding a comprehension loop variable errors
- Comparison: `same_error`
- Source: [ci/cases/syntax_walrus_rebind.py](../../ci/cases/syntax_walrus_rebind.py)

### syntax_walrus_subscript

- Responsibility: Assignment expression with a subscript target raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_walrus_subscript.py](../../ci/cases/syntax_walrus_subscript.py)

### syntax_with_parenthesized

- Responsibility: parenthesized manager lists (3.10) and tuple-ambiguity fallback (as after the closing paren / nested tuples)
- Comparison: `same_output`
- Source: [ci/cases/syntax_with_parenthesized.py](../../ci/cases/syntax_with_parenthesized.py)

### syntax_while_else

- Responsibility: `while...else` on normal exit vs `break`
- Comparison: `same_output`
- Source: [ci/cases/syntax_while_else.py](../../ci/cases/syntax_while_else.py)

### syntax_with

- Responsibility: `with` statement grammar core, multi-manager ordering, control-flow traversal and try/finally cross-check
- Comparison: `same_output`
- Source: [ci/cases/syntax_with.py](../../ci/cases/syntax_with.py)

### syntax_with_as_target

- Responsibility: all `as` target forms (tuple/nested/starred/attribute/subscript) and manager still exited on unpack failure
- Comparison: `same_output`
- Source: [ci/cases/syntax_with_as_target.py](../../ci/cases/syntax_with_as_target.py)

### syntax_with_bare_as

- Responsibility: `with x as:` missing target raises a parse error (invalid syntax)
- Comparison: `same_error`
- Source: [ci/cases/syntax_with_bare_as.py](../../ci/cases/syntax_with_bare_as.py)

### syntax_with_missing_colon

- Responsibility: `with` header missing colon raises a parse error (expected ':')
- Comparison: `same_error`
- Source: [ci/cases/syntax_with_missing_colon.py](../../ci/cases/syntax_with_missing_colon.py)

### syntax_with_starred_as

- Responsibility: bare starred target in `with x as *a:` raises a parse error (same rule as for targets)
- Comparison: `same_error`
- Source: [ci/cases/syntax_with_starred_as.py](../../ci/cases/syntax_with_starred_as.py)

### syntax_with_trailing_comma

- Responsibility: trailing comma in the manager list raises a parse error (invalid syntax)
- Comparison: `same_error`
- Source: [ci/cases/syntax_with_trailing_comma.py](../../ci/cases/syntax_with_trailing_comma.py)

### syntax_yield

- Responsibility: Generator `next`, laziness and `return` values
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield.py](../../ci/cases/syntax_yield.py)

### syntax_yield_closure

- Responsibility: Generators combined with closures/default parameters/class methods
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_closure.py](../../ci/cases/syntax_yield_closure.py)

### syntax_yield_consumers

- Responsibility: `sum`/`sorted`/`zip` and friends consuming generators
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_consumers.py](../../ci/cases/syntax_yield_consumers.py)

### syntax_yield_control

- Responsibility: `send`/`throw`/`close` and `yield from`
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_control.py](../../ci/cases/syntax_yield_control.py)

### syntax_yield_controlflow

- Responsibility: `yield` embedded in branches/loops/`try` and delegation
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_controlflow.py](../../ci/cases/syntax_yield_controlflow.py)

### syntax_yield_dictcomp

- Responsibility: `yield` inside a dict comprehension raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_yield_dictcomp.py](../../ci/cases/syntax_yield_dictcomp.py)

### syntax_yield_errprop

- Responsibility: Generator exception propagation and `return` value wrapping
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_errprop.py](../../ci/cases/syntax_yield_errprop.py)

### syntax_yield_expr

- Responsibility: `yield`/`yield from` inside expressions: evaluation and propagation
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_expr.py](../../ci/cases/syntax_yield_expr.py)

### syntax_yield_from

- Responsibility: `yield from` forwarding `send`/`throw` and memoization
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_from.py](../../ci/cases/syntax_yield_from.py)

### syntax_yield_lambda

- Responsibility: `yield` generators inside `lambda`
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_lambda.py](../../ci/cases/syntax_yield_lambda.py)

### syntax_yield_listcomp

- Responsibility: Bare `yield` inside a list comprehension raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_yield_listcomp.py](../../ci/cases/syntax_yield_listcomp.py)

### syntax_yield_nested_call

- Responsibility: Nested calls in `yield` subexpressions are not replayed
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_nested_call.py](../../ci/cases/syntax_yield_nested_call.py)

### syntax_yield_outside

- Responsibility: `yield` outside a function raises a parse error
- Comparison: `same_error`
- Source: [ci/cases/syntax_yield_outside.py](../../ci/cases/syntax_yield_outside.py)

### syntax_yield_paren_comp

- Responsibility: Parenthesized `yield` as a comprehension element errors
- Comparison: `same_error`
- Source: [ci/cases/syntax_yield_paren_comp.py](../../ci/cases/syntax_yield_paren_comp.py)

### syntax_yield_with

- Responsibility: generator and `with` interaction (yield in body, `as` binding across steps, close and throw through the exit path)
- Comparison: `same_output`
- Source: [ci/cases/syntax_yield_with.py](../../ci/cases/syntax_yield_with.py)

### syntax_yield_with_genexit

- Responsibility: yielding again after `with` suppresses GeneratorExit raises ignored (CPython message)
- Comparison: `same_error`
- Source: [ci/cases/syntax_yield_with_genexit.py](../../ci/cases/syntax_yield_with_genexit.py)

## Comprehensions (`comprehension_*`)

List, dict and set comprehensions and generator expressions. Boundary with `syntax_for`: comprehensions are their own constructs, so their inner `for`/`if`, multi-`for` nesting (`comprehension_multi`) and similar behavior belong here.

### comprehension_await

- Responsibility: await inside comprehensions (element / key-value / condition / nested comprehension / first-clause iterable await legal within async functions, sync contexts report `asynchronous comprehension outside of an asynchronous function`, sleep suspend replay)
- Comparison: `same_output`
- Source: [ci/cases/comprehension_await.py](../../ci/cases/comprehension_await.py)

### comprehension_dict

- Responsibility: Dict comprehension key/value construction, filtering and multi-for
- Comparison: `same_output`
- Source: [ci/cases/comprehension_dict.py](../../ci/cases/comprehension_dict.py)

### comprehension_genexp

- Responsibility: Generator expression laziness and consumption via `next`/`sum`/`zip`
- Comparison: `same_output`
- Source: [ci/cases/comprehension_genexp.py](../../ci/cases/comprehension_genexp.py)

### comprehension_genexp_tuple

- Responsibility: Generator expressions yielding tuple elements and `*args` consumption
- Comparison: `same_output`
- Source: [ci/cases/comprehension_genexp_tuple.py](../../ci/cases/comprehension_genexp_tuple.py)

### comprehension_list

- Responsibility: List comprehensions and generator expressions with filters
- Comparison: `same_output`
- Source: [ci/cases/comprehension_list.py](../../ci/cases/comprehension_list.py)

### comprehension_multi

- Responsibility: Multiple `for`/`if` across list, set, dict comprehensions and generator expressions
- Comparison: `same_output`
- Source: [ci/cases/comprehension_multi.py](../../ci/cases/comprehension_multi.py)

### comprehension_set

- Responsibility: Set comprehension `{x for ...}` with conditions
- Comparison: `same_output`
- Source: [ci/cases/comprehension_set.py](../../ci/cases/comprehension_set.py)

## Built-in Functions (`builtin_*`)

Functions in the built-in namespace: print/len/isinstance/getattr/iter/min/max/sorted and friends. Their error paths (e.g. out-of-range `chr`) are covered here too.

### builtin_abs_minmax

- Responsibility: All forms of the `abs`/`min`/`max`/`sum` built-ins
- Comparison: `same_output`
- Source: [ci/cases/builtin_abs_minmax.py](../../ci/cases/builtin_abs_minmax.py)

### builtin_error_text

- Responsibility: min/max/round/math error texts, `print>>` hint and function repr alignment
- Comparison: `same_output`
- Source: [ci/cases/builtin_error_text.py](../../ci/cases/builtin_error_text.py)

### builtin_ascii

- Responsibility: `ascii()` non-ASCII escaping and repr forms of various types
- Comparison: `same_output`
- Source: [ci/cases/builtin_ascii.py](../../ci/cases/builtin_ascii.py)

### builtin_bigint_fastpath

- Responsibility: Big integer fast-path consistency regression safety net (I2-13 confirmed item)
- Comparison: `same_output`
- Source: [ci/cases/builtin_bigint_fastpath.py](../../ci/cases/builtin_bigint_fastpath.py)

Big integers as dict keys (in/get/equality bucketing), `10**40`/`10**400`-scale arithmetic/mod/shift/bitwise/radix/divmod/round, negatives and mixed signs, int/str conversion round-trips — identical on both ends

### builtin_open

- Responsibility: `open()` text/binary read-write, line iteration, seek and error texts
- Comparison: `same_output`
- Source: [ci/cases/builtin_open.py](../../ci/cases/builtin_open.py)

Binary read/write operate on `bytes`; text reads use a lazy buffer; the binary comparison segment writes via `wb` to avoid CPython's text-mode newline translation on disk

### builtin_wrappers

- Responsibility: functional `staticmethod` / `classmethod` / `property` and `operator.index`
- Comparison: `same_output`
- Source: [ci/cases/builtin_wrappers.py](../../ci/cases/builtin_wrappers.py)

A functional property assigned in a class body gets its attribute name via the class-creation hook (CPython `__set_name__` semantics); `property.fget` / `fset` are introspectable; `operator.index` routes through the `__index__` protocol (including user classes) with CPython texts for float/str

### builtin_any_all

- Responsibility: `any`/`all` across truthiness combinations and empty containers
- Comparison: `same_output`
- Source: [ci/cases/builtin_any_all.py](../../ci/cases/builtin_any_all.py)

### builtin_chr

- Responsibility: Error types when `chr` and `%c` go out of range
- Comparison: `same_output`
- Source: [ci/cases/builtin_chr.py](../../ci/cases/builtin_chr.py)

### builtin_convert

- Responsibility: `int`/`float`/`bool` conversions and mixed-operation result types
- Comparison: `same_output`
- Source: [ci/cases/builtin_convert.py](../../ci/cases/builtin_convert.py)

### builtin_enumerate_start

- Responsibility: enumerate bigint start and bool start (I0-42): arbitrary-precision counting (verified against CPython 3.12)
- Comparison: `same_output`
- Source: [ci/cases/builtin_enumerate_start.py](../../ci/cases/builtin_enumerate_start.py)

### builtin_getattr

- Responsibility: `getattr`/`setattr`/`delattr` attribute operations
- Comparison: `same_output`
- Source: [ci/cases/builtin_getattr.py](../../ci/cases/builtin_getattr.py)

### builtin_globals

- Responsibility: globals() live-view four methods and deletion (I0-52): get/pop/setdefault/update write live dict, del by string key
- Comparison: `same_output`
- Source: [ci/cases/builtin_globals.py](../../ci/cases/builtin_globals.py)

### builtin_hasattr

- Responsibility: `hasattr` checks and `getattr` defaults and errors
- Comparison: `same_output`
- Source: [ci/cases/builtin_hasattr.py](../../ci/cases/builtin_hasattr.py)

### builtin_hash_identity

- Responsibility: mode-independent identity-hash invariants: same-object hash stability / equal values hash equally / objects as dict and set keys
- Comparison: `same_output`
- Source: [ci/cases/builtin_hash_identity.py](../../ci/cases/builtin_hash_identity.py)

The identity hash uses CPython 3.12-style process randomisation by default (the host can set `stable_identity_hash` to `true` to switch back to the stable model), so dual-end comparison covers only the mode-independent invariants; a user class defining `__eq__` without `__hash__` is unhashable and one defining neither hashes by identity, matching CPython

### builtin_isinstance

- Responsibility: `isinstance`/`issubclass` type checks
- Comparison: `same_output`
- Source: [ci/cases/builtin_isinstance.py](../../ci/cases/builtin_isinstance.py)

### builtin_issubclass

- Responsibility: `issubclass`/`isinstance` with nested tuples and short-circuiting
- Comparison: `same_output`
- Source: [ci/cases/builtin_issubclass.py](../../ci/cases/builtin_issubclass.py)

### builtin_iter_gen

- Responsibility: `iter` returns self for generators; exhausted generators cannot re-iterate
- Comparison: `same_output`
- Source: [ci/cases/builtin_iter_gen.py](../../ci/cases/builtin_iter_gen.py)

### builtin_iter_type

- Responsibility: `iter` type names per container, live views, exhaustion
- Comparison: `same_output`
- Source: [ci/cases/builtin_iter_type.py](../../ci/cases/builtin_iter_type.py)

### builtin_len_bad_args

- Responsibility: Wrong argument count for `len` raises a catchable `TypeError`
- Comparison: `same_output`
- Source: [ci/cases/builtin_len_bad_args.py](../../ci/cases/builtin_len_bad_args.py)

### builtin_map_filter

- Responsibility: `map`/`filter` combined with `lambda` and named functions
- Comparison: `same_output`
- Source: [ci/cases/builtin_map_filter.py](../../ci/cases/builtin_map_filter.py)

### builtin_minmax_getitem

- Responsibility: `min`/`max` default and legacy `__getitem__` iteration
- Comparison: `same_output`
- Source: [ci/cases/builtin_minmax_getitem.py](../../ci/cases/builtin_minmax_getitem.py)

### builtin_numeric_convert

- Responsibility: Strict `int`/`float` parsing and error messages
- Comparison: `same_output`
- Source: [ci/cases/builtin_numeric_convert.py](../../ci/cases/builtin_numeric_convert.py)

### builtin_ord_chr_radix

- Responsibility: `ord`/`chr` and `hex`/`oct`/`bin` base conversions
- Comparison: `same_output`
- Source: [ci/cases/builtin_ord_chr_radix.py](../../ci/cases/builtin_ord_chr_radix.py)

### builtin_print_type

- Responsibility: `print` `sep`/`end` and `type()` queries
- Comparison: `same_output`
- Source: [ci/cases/builtin_print_type.py](../../ci/cases/builtin_print_type.py)

### builtin_repr

- Responsibility: `repr(None)` and built-in type `repr`
- Comparison: `same_output`
- Source: [ci/cases/builtin_repr.py](../../ci/cases/builtin_repr.py)

### builtin_round

- Responsibility: `round` banker's rounding, exact in binary
- Comparison: `same_output`
- Source: [ci/cases/builtin_round.py](../../ci/cases/builtin_round.py)

### builtin_round_pow

- Responsibility: `round`/`pow`/`divmod` built-ins
- Comparison: `same_output`
- Source: [ci/cases/builtin_round_pow.py](../../ci/cases/builtin_round_pow.py)

### builtin_scan

- Responsibility: Numeric methods, encoding families, hash invariants and two-argument `iter`
- Comparison: `same_output`
- Source: [ci/cases/builtin_scan.py](../../ci/cases/builtin_scan.py)

### builtin_sorted_zip

- Responsibility: Sorting/reversing/enumerating/pairing built-ins
- Comparison: `same_output`
- Source: [ci/cases/builtin_sorted_zip.py](../../ci/cases/builtin_sorted_zip.py)

### builtin_sum_start

- Responsibility: sum() start= keyword argument and type checks (I0-41): keyword takes effect, string start rejected, type errors propagate
- Comparison: `same_output`
- Source: [ci/cases/builtin_sum_start.py](../../ci/cases/builtin_sum_start.py)

### builtin_type_dir

- Responsibility: Three-argument `type` class creation, `dir`, `float.hex`
- Comparison: `same_output`
- Source: [ci/cases/builtin_type_dir.py](../../ci/cases/builtin_type_dir.py)

### builtin_zip_strict

- Responsibility: `zip` `strict` length validation errors
- Comparison: `same_output`
- Source: [ci/cases/builtin_zip_strict.py](../../ci/cases/builtin_zip_strict.py)

## Built-in Types (`type_*`)

Construction, operator semantics (e.g. floor-division rounding on negatives) and methods of built-in types. Large method families are split by aspect (`type_str_format`, `type_dict_view_live`, ...).

### type_augassign_inplace

- Responsibility: in-place augmented assignment alias semantics for builtin containers (I0-38): dict |= / set |= / bytearray += mutate in place, list += extends
- Comparison: `same_output`
- Source: [ci/cases/type_augassign_inplace.py](../../ci/cases/type_augassign_inplace.py)

### type_bool_bigint

- Responsibility: bool vs bigint comparison/equality (I0-26) and bool pow/shift boundaries (I0-35): bigint dispatch, trivial results for |base|<=1, shifts promote to bigint, >>64 is 0
- Comparison: `same_output`
- Source: [ci/cases/type_bool_bigint.py](../../ci/cases/type_bool_bigint.py)

### type_bool_shortcircuit

- Responsibility: `and`/`or` short-circuit evaluation, operand return and truth testing
- Comparison: `same_output`
- Source: [ci/cases/type_bool_shortcircuit.py](../../ci/cases/type_bool_shortcircuit.py)

### type_bytes_format

- Responsibility: bytes % formatting placeholders, alignment/padding and numeric-conversion argument validation
- Comparison: `same_output`
- Source: [ci/cases/type_bytes_format.py](../../ci/cases/type_bytes_format.py)

### type_bytearray

- Responsibility: bytearray construction, mutation, arithmetic, slice assignment and bytes interop
- Comparison: `same_output`
- Source: [ci/cases/type_bytearray.py](../../ci/cases/type_bytearray.py)

bytearray is unhashable (dict keys raise `unhashable type: 'bytearray'`); `bytes + bytearray` yields bytes while `bytearray + bytes` yields bytearray; the mutable subclass overrides the repr prefix and the type factory, inheriting all read-only methods (upper/decode/hex etc.) which return bytearray

### type_class_repr

- Responsibility: class-object repr matches str as `<class 'X'>` (covering container elements and formatting paths)
- Comparison: `same_output`
- Source: [ci/cases/type_class_repr.py](../../ci/cases/type_class_repr.py)

### type_complex

- Responsibility: complex type and `1j` literals — construction, arithmetic, comparison, dict keys
- Comparison: `same_output`
- Source: [ci/cases/type_complex.py](../../ci/cases/type_complex.py)

`1+0j` shares key and hash with `1`; ordering raises `'<' not supported...`; complex power uses exact repeated multiplication for integer exponents and the libm polar path for non-integer ones (including `**0.5`) — compare with `round(..., N)` (ci.md rule 4)

### type_complex_bigint

- Responsibility: complex with bigint mixing/comparison and division overflow (I0-29/I0-36): bigint operand rounded to double, OverflowError on overflow, Smith-scaled division
- Comparison: `same_output`
- Source: [ci/cases/type_complex_bigint.py](../../ci/cases/type_complex_bigint.py)

### type_ctor_three_args

- Responsibility: type() 3-arg error messages aligned to `type.__new__()`
- Comparison: `same_output`
- Source: [ci/cases/type_ctor_three_args.py](../../ci/cases/type_ctor_three_args.py)

### type_descriptor_repr

- Responsibility: method_descriptor / wrapper_descriptor repr owning type name
- Comparison: `same_output`
- Source: [ci/cases/type_descriptor_repr.py](../../ci/cases/type_descriptor_repr.py)

### type_magic_class_access

- Responsibility: Magic method descriptors accessible and callable on builtin type classes (incl. bool/bytes/bytearray/set/frozenset and method-descriptor forms)
- Comparison: `same_output`
- Source: [ci/cases/type_magic_class_access.py](../../ci/cases/type_magic_class_access.py)

### type_matmul

- Responsibility: the `@` matrix-multiply operator (P2-16, syntax level): `TypeError: unsupported operand type(s) for @` on builtin types, user `__matmul__` / `__rmatmul__` cross-type reflection, same precedence as `*`, `@=` augmented assignment and `operator.matmul`
- Comparison: `same_output`
- Source: [ci/cases/type_matmul.py](../../ci/cases/type_matmul.py)

### type_memoryview

- Responsibility: memoryview construction, indexing, slicing, read-only vs writable passthrough, tobytes/cast/release
- Comparison: `same_output`
- Source: [ci/cases/type_memoryview.py](../../ci/cases/type_memoryview.py)

Pragmatic support covers one-dimensional B-format views only; bytes-backed views are read-only (assignment raises `cannot modify read-only memory`) while bytearray-backed views write through; operations after release raise `operation forbidden on released memoryview object`

### type_bytes_methods

- Responsibility: `bytes` construction forms and `decode`/`hex`/`split` methods
- Comparison: `same_output`
- Source: [ci/cases/type_bytes_methods.py](../../ci/cases/type_bytes_methods.py)

### type_bytes_range

- Responsibility: `bytes`/`range`/`dict` view type behaviors
- Comparison: `same_output`
- Source: [ci/cases/type_bytes_range.py](../../ci/cases/type_bytes_range.py)

### type_ctor_args

- Responsibility: builtin type constructor argument-count / keyword / base validation (int's `takes at most` counting message and `base` keyword, float/bool/list/tuple keyword rejection, indexability and the 0-or-2..36 legal domain of base, subclass constructors sharing the same validation)
- Comparison: `same_output`
- Source: [ci/cases/type_ctor_args.py](../../ci/cases/type_ctor_args.py)

### type_ctor_kwargs

- Responsibility: remaining builtin type constructor kwargs and deque maxlen semantics (set/frozenset/slice keyword rejection and argument counting, explicit None iterable argument error, deque maxlen keyword and positional effectiveness / overflow trimming / type and negative and bignum validation / concatenation and repetition and augmented assignment keeping the cap / repr and read-only attribute and insert and ordered comparison)
- Comparison: `same_output`
- Source: [ci/cases/type_ctor_kwargs.py](../../ci/cases/type_ctor_kwargs.py)

### type_dict

- Responsibility: `dict` construction and access/iteration/mutation methods
- Comparison: `same_output`
- Source: [ci/cases/type_dict.py](../../ci/cases/type_dict.py)

### type_dict_iter_mutate

- Responsibility: Adding/removing keys during iteration raises a catchable `RuntimeError`
- Comparison: `same_output`
- Source: [ci/cases/type_dict_iter_mutate.py](../../ci/cases/type_dict_iter_mutate.py)

### type_dict_merge

- Responsibility: `dict` `|` merge and `**` unpacking override order, `fromkeys`
- Comparison: `same_output`
- Source: [ci/cases/type_dict_merge.py](../../ci/cases/type_dict_merge.py)

### type_dict_methods

- Responsibility: Dict `pop`, `setdefault`, `update` and friends
- Comparison: `same_output`
- Source: [ci/cases/type_dict_methods.py](../../ci/cases/type_dict_methods.py)

### type_dict_none_key

- Responsibility: `None` as a dict key: storage and equality
- Comparison: `same_output`
- Source: [ci/cases/type_dict_none_key.py](../../ci/cases/type_dict_none_key.py)

### type_dict_tuple_key

- Responsibility: Dict tuple compound keys `d[1, 2]`
- Comparison: `same_output`
- Source: [ci/cases/type_dict_tuple_key.py](../../ci/cases/type_dict_tuple_key.py)

### type_dict_view_live

- Responsibility: Views reflect the live dict; mutating keys during iteration errors
- Comparison: `same_output`
- Source: [ci/cases/type_dict_view_live.py](../../ci/cases/type_dict_view_live.py)

### type_dict_view_types

- Responsibility: `dict` view type names, `repr` and equality
- Comparison: `same_output`
- Source: [ci/cases/type_dict_view_types.py](../../ci/cases/type_dict_view_types.py)

### type_dunder_methods

- Responsibility: Direct dunder calls on built-in containers; tuples cannot delete items
- Comparison: `same_output`
- Source: [ci/cases/type_dunder_methods.py](../../ci/cases/type_dunder_methods.py)

### type_float_mod

- Responsibility: double-rounding fixes for float mod/floordiv (I0-27): exact fmod then sign correction, quotient via Python-style mod then single rounding, negative zero
- Comparison: `same_output`
- Source: [ci/cases/type_float_mod.py](../../ci/cases/type_float_mod.py)

### type_float_parse

- Responsibility: correctly-rounded float string parsing: hard literals / float() syntax validation and underscores / subnormals and inf boundaries / shortest repr round-trip
- Comparison: `same_output`
- Source: [ci/cases/type_float_parse.py](../../ci/cases/type_float_parse.py)

Float literals and `float()` strings go through a self-produced correctly-rounded parser (big-integer ratio + round-half-to-even); hard cases (`9007199254740993.0` / `1e23` / the subnormal `5e-324`) match CPython bit for bit; the repr shortest-round-trip check uses the same parser, so subnormals no longer fall back to 17 digits; `math.copysign` gained negative-zero sign-bit semantics

### type_float_ratio

- Responsibility: float.as_integer_ratio big scaling and is_integer boundaries (I0-31/I0-34): bigint-backed scaling, zero is (0,1), NaN/inf error types, inf not integer
- Comparison: `same_output`
- Source: [ci/cases/type_float_ratio.py](../../ci/cases/type_float_ratio.py)

### type_frozenset

- Responsibility: `frozenset` construction, set operations, hashability, dedup
- Comparison: `same_output`
- Source: [ci/cases/type_frozenset.py](../../ci/cases/type_frozenset.py)

### type_function

- Responsibility: Type class names of functions/methods and `__name__`
- Comparison: `same_output`
- Source: [ci/cases/type_function.py](../../ci/cases/type_function.py)

### type_functools_types

- Responsibility: type identity and repr shapes of the functools.cache/lru_cache factories and the wrapped object
- Comparison: `same_output`
- Source: [ci/cases/type_functools_types.py](../../ci/cases/type_functools_types.py)

### type_generic_alias

- Responsibility: `list[int]` generic alias objects, hashing and equality
- Comparison: `same_output`
- Source: [ci/cases/type_generic_alias.py](../../ci/cases/type_generic_alias.py)

### type_int_base

- Responsibility: `int(str, base)` base parsing and `base=0` prefixes
- Comparison: `same_output`
- Source: [ci/cases/type_int_base.py](../../ci/cases/type_int_base.py)

### type_int_bytes

- Responsibility: int.to_bytes two's-complement and from_bytes bigint (I0-32/I0-43): two's-complement for negatives, boundary values allowed, byteorder/length checks, >8 bytes exact
- Comparison: `same_output`
- Source: [ci/cases/type_int_bytes.py](../../ci/cases/type_int_bytes.py)

### type_int_floordiv_mod

- Responsibility: Negative `//` and `%` floor toward negative infinity; remainder sign follows the divisor
- Comparison: `same_output`
- Source: [ci/cases/type_int_floordiv_mod.py](../../ci/cases/type_int_floordiv_mod.py)

### type_int_intern

- Responsibility: Small-integer -5..256 interning and `bool` singletons
- Comparison: `same_output`
- Source: [ci/cases/type_int_intern.py](../../ci/cases/type_int_intern.py)

### type_int_dunder

- Responsibility: int/bool numeric-protocol and conversion dunder direct calls, as_integer_ratio / is_integer
- Comparison: `same_output`
- Source: [ci/cases/type_int_dunder.py](../../ci/cases/type_int_dunder.py)

`__index__`/`__int__`/`__floor__`/`__ceil__`/`__trunc__` return self (bool via the equal-value integer), `__float__` rounds big integers through 53-bit rounding, `__hash__` matches `hash()` (modulo `2^61-1`, equal values hash equally), `__abs__` takes the magnitude of big integers, `as_integer_ratio` returns `(self, 1)`, `is_integer` is always true; float has no `__index__` (`hasattr` is False)

### type_int_methods

- Responsibility: `int`/`float` bit methods and `format()`
- Comparison: `same_output`
- Source: [ci/cases/type_int_methods.py](../../ci/cases/type_int_methods.py)

### type_int_fold

- Responsibility: integer constant-expression folding and interning (gates matching the CPython optimizer): identical literal expressions share one object (`is` is True), per-operator gates (multiply by operand bit sum / power by bits(base)×exponent / shift by bits(left)+shift, over 128 refuses) verified both ways, folded value matrix (including negative floor semantics), evaluation errors (division by zero / negative shift / huge shift) keep runtime raising, string concat folding coexists
- Comparison: `same_output`
- Source: [ci/cases/type_int_fold.py](../../ci/cases/type_int_fold.py)

### type_int_overflow

- Responsibility: integer boundaries, shifts and negative-exponent power semantics (after P0-13 the overflow errors are replaced by automatic promotion; this case asserts dual-end identical results)
- Comparison: `same_output`
- Source: [ci/cases/type_int_overflow.py](../../ci/cases/type_int_overflow.py)

### type_int_big

- Responsibility: arbitrary-precision int operation matrix with mixed fast/slow paths (P0-13): literal promotion, augmented assignment, bool shared paths, exact comparison with float, divmod signs, big modular exponentiation, truediv overflow
- Comparison: `same_output`
- Source: [ci/cases/type_int_big.py](../../ci/cases/type_int_big.py)

### type_int_big_bits

- Responsibility: arbitrary-precision int negative bitwise ops (infinite two's complement), cross-limb shifts, floor-toward-negative-infinity right shift, CPython mod 2^61-1 hashing, big dict/set keys, base strings and bit methods
- Comparison: `same_output`
- Source: [ci/cases/type_int_big_bits.py](../../ci/cases/type_int_big_bits.py)

### type_int_big_convert

- Responsibility: arbitrary-precision int literal forms (bases/underscores) and conversions: int() string parsing (per-base big accumulation), exact decimal expansion for float truncation, round half-to-even on bigs, float() overflow, to_bytes
- Comparison: `same_output`
- Source: [ci/cases/type_int_big_convert.py](../../ci/cases/type_int_big_convert.py)

### type_int_big_index

- Responsibility: arbitrary-precision int convergence at index positions (CPython Py_ssize_t isomorphism): subscript IndexError, slice component clamping, repeat/width/chr/bytes OverflowError, huge shift too-many-digits, to_bytes short buffer
- Comparison: `same_output`
- Source: [ci/cases/type_int_big_index.py](../../ci/cases/type_int_big_index.py)

Note: `range(10**30)` constructs lazily in CPython, while PyGDS converges range arguments to int64 raising `OverflowError` — a documented limitation (see usage.md and the known-issues list).

### type_int_format_big

- Responsibility: formatting big ints (> int64) in the numeric branches of f-string / `format` / `str.format` (x/X/o/b/c/d/f/e/g/%, exception classes compared)
- Comparison: `same_output`
- Source: [ci/cases/type_int_format_big.py](../../ci/cases/type_int_format_big.py)

The `x`/`X`/`o`/`b` (incl. `#` alternate form and `_` grouping), `c`, and `f`/`e`/`g`/`%` branches previously read the fast-path `value` (always 0 for big ints) and silently printed `"0"` or `chr(0)`; they now produce the correct base/fixed output or raise as in CPython (`c` and beyond-double-range raise `OverflowError`; class-name comparison sidesteps the C-long platform boundary). Also fixes `_fixed_format_parts` zero-padding for fixed-point formatting beyond int64 (previously `f"{1e30:f}"` went out of bounds) and `format()` swallowing `last_error` instead of propagating it.

### type_int_repr

- Responsibility: bigint repr rendering in exception messages/KeyError (I0-33): bigint value 0 rendered as 0, now full decimal string
- Comparison: `same_output`
- Source: [ci/cases/type_int_repr.py](../../ci/cases/type_int_repr.py)

### type_int_truediv

- Responsibility: single-rounding int/int true division and division by zero (I0-28/I0-30): 54-55 bit quotient plus sticky remainder, bigint / 0 raises ZeroDivisionError
- Comparison: `same_output`
- Source: [ci/cases/type_int_truediv.py](../../ci/cases/type_int_truediv.py)

### type_inplace_dunder

- Responsibility: in-place dunder (`__iadd__`/`__imul__`) direct calls on list/bytearray and the `+=`/`*=` statements
- Comparison: `same_output`
- Source: [ci/cases/type_inplace_dunder.py](../../ci/cases/type_inplace_dunder.py)

The non-int argument message of direct `__imul__` uses the operator-layer shape (CPython's slot-wrapper direct call has a separate ssize_t conversion message - the two paths disagree inside CPython itself)

### type_list

- Responsibility: `list` construction, CRUD methods and `+`/`*` operations
- Comparison: `same_output`
- Source: [ci/cases/type_list.py](../../ci/cases/type_list.py)

### type_list_eq

- Responsibility: Recursive equality of nested containers and `in`/`index`/`count`
- Comparison: `same_output`
- Source: [ci/cases/type_list_eq.py](../../ci/cases/type_list_eq.py)

### type_list_sort

- Responsibility: `sort` `key`/`reverse` and `sorted`
- Comparison: `same_output`
- Source: [ci/cases/type_list_sort.py](../../ci/cases/type_list_sort.py)

### type_nan_compare

- Responsibility: NaN in ordered comparisons always yields False (I0-25): the unordered sentinel was used as a comparison result so `1 < nan` was True, now follows IEEE/CPython semantics
- Comparison: `same_output`
- Source: [ci/cases/type_nan_compare.py](../../ci/cases/type_nan_compare.py)

### type_range_len

- Responsibility: range bigint length ceil tail, fast-path len wraparound and True in range (I0-57/58/65)
- Comparison: `same_output`
- Source: [ci/cases/type_range_len.py](../../ci/cases/type_range_len.py)

### type_seq_compare

- Responsibility: `list`/`tuple` lexicographic ordering and `sort` `key`
- Comparison: `same_output`
- Source: [ci/cases/type_seq_compare.py](../../ci/cases/type_seq_compare.py)

### type_seq_concat

- Responsibility: Strict type rules for sequence `+`/`*`
- Comparison: `same_output`
- Source: [ci/cases/type_seq_concat.py](../../ci/cases/type_seq_concat.py)

### type_set

- Responsibility: `set` literals/operations/subsets/methods
- Comparison: `same_output`
- Source: [ci/cases/type_set.py](../../ci/cases/type_set.py)

### type_set_methods

- Responsibility: Set methods accepting any iterable; the in-place update family
- Comparison: `same_output`
- Source: [ci/cases/type_set_methods.py](../../ci/cases/type_set_methods.py)

### type_range_big

- Responsibility: arbitrary-precision semantics of big range: lazy construction / len OverflowError / big subscripts and negative subscripts / membership / slicing / reversed / equality and truthiness / start-stop-step attributes
- Comparison: `same_output`
- Source: [ci/cases/type_range_big.py](../../ci/cases/type_range_big.py)

range arguments keep arbitrary precision instead of converging to the index width, matching CPython's lazy semantics; materialisation of lengths beyond the index width (list / tuple / sorted) and len raise OverflowError with CPython's message; out-of-range big slices of small ranges clamp identically and the read-only `start` / `stop` / `step` attributes are aligned

### type_setitem_dunder

- Responsibility: `__setitem__` dunder direct-call slice assignment and type/out-of-range validation (I0-8): the statement path worked while dunder direct calls silently no-op'd, now both share the statement implementation
- Comparison: `same_output`
- Source: [ci/cases/type_setitem_dunder.py](../../ci/cases/type_setitem_dunder.py)

### type_slice

- Responsibility: `slice` object construction, attributes, indexing
- Comparison: `same_output`
- Source: [ci/cases/type_slice.py](../../ci/cases/type_slice.py)

### type_str_classification

- Responsibility: str character classification across full Unicode code-point ranges (isdecimal/isdigit/isnumeric/isprintable/isspace)
- Comparison: `same_output`
- Source: [ci/cases/type_str_classification.py](../../ci/cases/type_str_classification.py)

### type_str_decode

- Responsibility: the `str(object, encoding, errors)` decoding path (bytes and bytearray decoding / str input rejection / bytes-like message / encoding and errors type validation / argument counting and name-position duplicate binding / subclass decoding)
- Comparison: `same_output`
- Source: [ci/cases/type_str_decode.py](../../ci/cases/type_str_decode.py)

### type_str_format

- Responsibility: `str.format` argument referencing, alignment/padding, conversion flags (with explicit alignment the `0` flag becomes the fill character, explicit fill wins)
- Comparison: `same_output`
- Source: [ci/cases/type_str_format.py](../../ci/cases/type_str_format.py)

### type_str_format_nested

- Responsibility: `format` nested format specs with dynamic width and precision
- Comparison: `same_output`
- Source: [ci/cases/type_str_format_nested.py](../../ci/cases/type_str_format_nested.py)

### type_str_format_numbering

- Responsibility: str.format manual/automatic field numbering mixing raises ValueError
- Comparison: `same_output`
- Source: [ci/cases/type_str_format_numbering.py](../../ci/cases/type_str_format_numbering.py)

### type_str_format_thousands

- Responsibility: `format` thousands separators `,` and `_`; invalid combinations error
- Comparison: `same_output`
- Source: [ci/cases/type_str_format_thousands.py](../../ci/cases/type_str_format_thousands.py)

### type_str_format_validation

- Responsibility: format/f-string type-vs-spec validation and numeric edge cases (inf/nan / -0.0 / bool as numeric), `str.rsplit`/`title`/`istitle` digit-separator semantics
- Comparison: `same_output`
- Source: [ci/cases/type_str_format_validation.py](../../ci/cases/type_str_format_validation.py)

`format(int, 's')` / `format(float, 'd'/'x'/'o'/'b'/'c')` / `format(str, numeric)` raise CPython's `ValueError: Unknown format code`; containers reject any non-empty spec (including width-only) with `TypeError: unsupported format string passed to X.__format__`; `inf`/`nan` format as `inf`/`nan` under `f`/`e`/`g`/`%` (uppercase for E/F/G, `%` suffix), `-0.0` keeps its sign under `e`/`g`; `bool` participates as a number in sign/alternate-form/alignment/zero-padding; `str.rsplit` splits on whitespace by default keeping left-to-right order (the maxsplit prefix is preserved verbatim), and `title`/`istitle` treat digits/punctuation as word separators (`'a1b'.title()` == `'A1B'`)

### type_str_identity

- Responsibility: String interning and `is` identity
- Comparison: `same_output`
- Source: [ci/cases/type_str_identity.py](../../ci/cases/type_str_identity.py)

### type_str_methods

- Responsibility: Common `str` methods: casing/splitting/searching etc.
- Comparison: `same_output`
- Source: [ci/cases/type_str_methods.py](../../ci/cases/type_str_methods.py)

### type_str_methods2

- Responsibility: `splitlines`/`partition`/`is*` methods
- Comparison: `same_output`
- Source: [ci/cases/type_str_methods2.py](../../ci/cases/type_str_methods2.py)

### type_str_methods3

- Responsibility: `split`/`reversed`/`except as` regression sweep
- Comparison: `same_output`
- Source: [ci/cases/type_str_methods3.py](../../ci/cases/type_str_methods3.py)

### type_str_methods_ext

- Responsibility: Extended string methods: casing, predicates, padding etc.
- Comparison: `same_output`
- Source: [ci/cases/type_str_methods_ext.py](../../ci/cases/type_str_methods_ext.py)

### type_str_percent

- Responsibility: `%` formatting: width/sign/named mapping
- Comparison: `same_output`
- Source: [ci/cases/type_str_percent.py](../../ci/cases/type_str_percent.py)

### type_str_split

- Responsibility: `split`/`rsplit` `maxsplit` behavior
- Comparison: `same_output`
- Source: [ci/cases/type_str_split.py](../../ci/cases/type_str_split.py)

### type_str_strip

- Responsibility: `strip`/`lstrip`/`rstrip` with character-set arguments
- Comparison: `same_output`
- Source: [ci/cases/type_str_strip.py](../../ci/cases/type_str_strip.py)

### type_tuple

- Responsibility: Tuple literal forms and printing
- Comparison: `same_output`
- Source: [ci/cases/type_tuple.py](../../ci/cases/type_tuple.py)

### type_type_alias_type

- Responsibility: type(type alias instance) returns TypeAliasType
- Comparison: `same_output`
- Source: [ci/cases/type_type_alias_type.py](../../ci/cases/type_type_alias_type.py)

## Standard Library Modules (`module_*`)

PyGDS's built-in standard library modules (`math` / `random` / `statistics` / `functools` / `itertools` / `collections` / `string` / `operator` / `sys` / `time` / `contextlib` / `bisect` / `heapq` / `base64` / `json` / `logging`); the full list is in [builtin.md](./builtin.md). A single function with enough behavior of its own is split into a sub-file (e.g. `module_math_sqrt`).

### module_base64

- Responsibility: `base64` Base16/Base64 encoding/decoding (standard/urlsafe/altchars/line-wrapped, padding validation)
- Comparison: `same_output`
- Source: [ci/cases/module_base64.py](../../ci/cases/module_base64.py)

`b64encode`/`b64decode`/`standard_*`/`urlsafe_*`/`b16*`/`encodebytes`/`decodebytes` take and return bytes; padding validation follows CPython (data length mod 4 == 1 raises `Invalid... 1 more than a multiple of 4`, non-multiple-of-4 total or data after `=` raises `Incorrect padding`; the error type is `ValueError`, with the `binascii.Error` subclass difference documented)

### module_bisect_heapq

- Responsibility: `bisect` binary search and insertion, `heapq` heap operations
- Comparison: `same_output`
- Source: [ci/cases/module_bisect_heapq.py](../../ci/cases/module_bisect_heapq.py)

`bisect_left`/`bisect_right`/`insort_*` (incl. lo/hi bounds) and `heappush`/`heappop`/`heapify`/`heapreplace`/`heappushpop` follow CPython semantics; incomparable items raise `TypeError: '<' not supported between instances of ...`

### module_collections_deque

- Responsibility: collections.deque two-ended operations, maxlen, rotate, indexing and comparison
- Comparison: `same_output`
- Source: [ci/cases/module_collections_deque.py](../../ci/cases/module_collections_deque.py)

`maxlen` overflow silently drops from the opposite end; slicing is unsupported (`sequence index must be integer, not 'slice'`); `pop`/`popleft` on an empty deque raise `pop from an empty deque`; failed `remove`/`index` raise `x is not in deque` (value repr)

### module_collections_ordereddict

- Responsibility: collections.OrderedDict construction, order-sensitive equality, move_to_end, popitem
- Comparison: `same_output`
- Source: [ci/cases/module_collections_ordereddict.py](../../ci/cases/module_collections_ordereddict.py)

Equality between two OrderedDicts is key-order sensitive, while comparison against a plain dict falls back to order-insensitive dict equality (CPython semantics); `popitem(last=False)` pops the first pair and an empty dict raises `dictionary is empty`

### module_collections_wrappers

- Responsibility: protocol surface of ChainMap/UserDict/UserList (parents attribute/get/pop/copy/data attribute/mapping equality/repr shapes/UserList method family)
- Comparison: `same_output`
- Source: [ci/cases/module_collections_wrappers.py](../../ci/cases/module_collections_wrappers.py)

ChainMap's iteration key order is the dict order of "updating from the last map" (keys of the last map come first, values decided by the nearest map holding the key); a missing key in `pop`/`del` on the first map raises `KeyError("Key not found in the first mapping: 'x'")` (str(e) is the repr form of the message string, double-quoted); equality of ChainMap/UserDict against a dict uses mapping semantics (True when the key-value sets match); UserDict/UserList repr is the wrapped object's own dict/list shape, and the `.data` attribute exposes the underlying container

### module_sys

- Responsibility: sys module basics (maxsize/version_info/byteorder/platform/intern/exit)
- Comparison: `same_output`
- Source: [ci/cases/module_sys.py](../../ci/cases/module_sys.py)

`version`/`version_info` are pinned to the aligned CPython 3.12 form (the platform value maps to the host OS, compared via membership); `sys.exit` raises `SystemExit` (a BaseException subclass); uncaught, PyGDS has no process-exit semantics and enters the error state

### module_sys_int_max_str

- Responsibility: `sys.set_int_max_str_digits` decimal conversion limit (default 4300 / setting 0 removes it / power-of-2 bases exempt / invalid-argument checks / dynamic `compile()` uses the live limit)
- Comparison: `same_output`
- Source: [ci/cases/module_sys_int_max_str.py](../../ci/cases/module_sys_int_max_str.py)

Decimal `int`/`str` conversion is limited to 4300 digits by default (aligned with CPython 3.11+); `str()`/`repr()`/f-string output and `int()` parsing beyond the limit raise `ValueError`; bases 2/4/8/16/32 are exempt (including `0b`/`0o`/`0x` overlong literals at compile time, while decimal `print` of them raises `ValueError`); `sys.set_int_max_str_digits(0)` removes the limit and invalid arguments (non-zero values below 640 / negatives / non-integers) raise the CPython error; dynamic `compile()` uses the live limit at compile time (setting 4302 then compiling a 4302-digit literal succeeds)

### module_random_mt

- Responsibility: MT19937 alignment of the random module (int-seed init_by_array path / random / randint / randrange / choice / shuffle / sample / uniform / gauss / getrandbits / getstate / setstate matching CPython sequences value by value, engine random source for no-arg seed, string-seed sha512 difference documented)
- Comparison: `same_output`
- Source: [ci/cases/module_random_mt.py](../../ci/cases/module_random_mt.py)

### module_dynamic_eval

- Responsibility: eval / exec / compile dynamic evaluation and globals / locals / vars / sys.modules (single-expression check and SyntaxError message / exec-mode code passthrough / code metadata / globals argument snapshot writeback / globals() live view and function-local locals snapshot / vars instance dict / dynamic top-level cannot suspend while functions defined via exec suspend normally)
- Comparison: `same_output`
- Source: [ci/cases/module_dynamic_eval.py](../../ci/cases/module_dynamic_eval.py)

### module_user_import

- Responsibility: user file `import` (sys.path resolution and module cache idempotency / member and `as` alias binding / `__name__` / class and function definitions inside modules / miss `ImportError`) and the CPython message for partially initialized modules on circular import (terminal error)
- Comparison: `same_error`
- Source: [ci/cases/module_user_import.py](../../ci/cases/module_user_import.py)

### module_contextlib

- Responsibility: the contextlib module (contextmanager decorator generator driving and exception injection / `generator didn't yield` / `didn't stop` / `didn't stop after throw()` / exception passthrough and suppression, closing, suppress with multiple exceptions and missed-type propagation, ExitStack callback ordering / enter_context / pop_all / close, nullcontext, suspend replay across generator sleep stages)
- Comparison: `same_output`
- Source: [ci/cases/module_contextlib.py](../../ci/cases/module_contextlib.py)

### module_collections

- Responsibility: `Counter` counting and `defaultdict` factory defaults
- Comparison: `same_output`
- Source: [ci/cases/module_collections.py](../../ci/cases/module_collections.py)

### module_collections_counter

- Responsibility: Counter construction preserving counts/kwargs/equality/most_common fidelity (I0-50): negative/float/bigint counts kept, kwargs effective, compares by underlying mapping
- Comparison: `same_output`
- Source: [ci/cases/module_collections_counter.py](../../ci/cases/module_collections_counter.py)

### module_collections_defaultdict

- Responsibility: `defaultdict` `repr` and mapping-style construction
- Comparison: `same_output`
- Source: [ci/cases/module_collections_defaultdict.py](../../ci/cases/module_collections_defaultdict.py)

### module_collections_most_common

- Responsibility: `most_common` ordering rules and top-`n` truncation
- Comparison: `same_output`
- Source: [ci/cases/module_collections_most_common.py](../../ci/cases/module_collections_most_common.py)

### module_collections_namedtuple

- Responsibility: `namedtuple` construction/`_make`/`_replace`
- Comparison: `same_output`
- Source: [ci/cases/module_collections_namedtuple.py](../../ci/cases/module_collections_namedtuple.py)

### module_functools

- Responsibility: `reduce` folding and `partial` argument binding
- Comparison: `same_output`
- Source: [ci/cases/module_functools.py](../../ci/cases/module_functools.py)

### module_functools_cmp_to_key

- Responsibility: `cmp_to_key` legacy comparison functions in sorting
- Comparison: `same_output`
- Source: [ci/cases/module_functools_cmp_to_key.py](../../ci/cases/module_functools_cmp_to_key.py)

### module_import_star

- Responsibility: `from m import *` honors module `__all__` export surface
- Comparison: `same_output`
- Source: [ci/cases/module_import_star.py](../../ci/cases/module_import_star.py)

### module_itertools

- Responsibility: `chain`/`product`/combinatorics and `islice`
- Comparison: `same_output`
- Source: [ci/cases/module_itertools.py](../../ci/cases/module_itertools.py)

### module_itertools_accumulate

- Responsibility: `accumulate`/`pairwise`/`groupby`
- Comparison: `same_output`
- Source: [ci/cases/module_itertools_accumulate.py](../../ci/cases/module_itertools_accumulate.py)

### module_itertools_groupby

- Responsibility: `groupby` lazy grouper one-shot semantics and cursor sharing
- Comparison: `same_output`
- Source: [ci/cases/module_itertools_groupby.py](../../ci/cases/module_itertools_groupby.py)

### module_itertools_infinite

- Responsibility: `repeat`/`cycle`/`count`/`takewhile`
- Comparison: `same_output`
- Source: [ci/cases/module_itertools_infinite.py](../../ci/cases/module_itertools_infinite.py)

### module_itertools_lazy

- Responsibility: itertools lazy-iterator type names / empty-pool guard / infinite-source laziness
- Comparison: `same_output`
- Source: [ci/cases/module_itertools_lazy.py](../../ci/cases/module_itertools_lazy.py)

### module_itertools_tee

- Responsibility: `Counter`/`tee`/nested class/`%s` regression sweep
- Comparison: `same_output`
- Source: [ci/cases/module_itertools_tee.py](../../ci/cases/module_itertools_tee.py)

### module_json

- Responsibility: `json` serialization and deserialization (dumps/loads, indent/sort/separators/ensure_ascii/big ints, JSONDecodeError)
- Comparison: `same_output`
- Source: [ci/cases/module_json.py](../../ci/cases/module_json.py)

`dumps` supports `indent`/`sort_keys`/`separators`/`ensure_ascii` (floats via shortest-roundtrip repr, arbitrary-precision big ints, non-string keys escaped by their literal, unserializable types raise `TypeError`); `loads` fully parses (string escapes/leading-zero validation/nesting), invalid JSON raises `JSONDecodeError` (a ValueError subclass); bool dict keys serialize as `"1"` instead of `"true"` because DSLDict collapses bool/int keys (documented edge)

### module_logging

- Responsibility: `logging` module info/warn/warning/error calls and bare-name removal
- Comparison: `same_output`
- Source: [ci/cases/module_logging.py](../../ci/cases/module_logging.py)

`info`/`warn`/`warning`/`error` write to console_output subject to log-level filtering and return None (the singleton, so `is None` holds), `warn` is an alias of `warning`

### module_math

- Responsibility: `sqrt`/`floor`/trigonometry/factorial and other basic functions
- Comparison: `same_output`
- Source: [ci/cases/module_math.py](../../ci/cases/module_math.py)

### module_math_comb

- Responsibility: `comb`/`perm`/`prod`/`lcm` counting functions
- Comparison: `same_output`
- Source: [ci/cases/module_math_comb.py](../../ci/cases/module_math_comb.py)

### module_math_remainder

- Responsibility: `remainder`/`cbrt`/`quantiles`
- Comparison: `same_output`
- Source: [ci/cases/module_math_remainder.py](../../ci/cases/module_math_remainder.py)

### module_operator

- Responsibility: `operator` arithmetic/comparison/`itemgetter`
- Comparison: `same_output`
- Source: [ci/cases/module_operator.py](../../ci/cases/module_operator.py)

### module_random

- Responsibility: `random` structural behavior and `seed` reproducibility
- Comparison: `same_output`
- Source: [ci/cases/module_random.py](../../ci/cases/module_random.py)

### module_random_choices

- Responsibility: `random.choices` on a generator raising for `len`
- Comparison: `same_output`
- Source: [ci/cases/module_random_choices.py](../../ci/cases/module_random_choices.py)

### module_random_gauss

- Responsibility: `choices` weights and `gauss` parameters
- Comparison: `same_output`
- Source: [ci/cases/module_random_gauss.py](../../ci/cases/module_random_gauss.py)

### module_random_types

- Responsibility: Sampling functions' sequence-type rejection rules
- Comparison: `same_output`
- Source: [ci/cases/module_random_types.py](../../ci/cases/module_random_types.py)

### module_repr

- Responsibility: Module repr form `(built-in <module 'x' (built-in)>)`
- Comparison: `same_output`
- Source: [ci/cases/module_repr.py](../../ci/cases/module_repr.py)

### module_statistics

- Responsibility: `mean`/`median`/`stdev` statistics
- Comparison: `same_output`
- Source: [ci/cases/module_statistics.py](../../ci/cases/module_statistics.py)

### module_stdlib_members

- Responsibility: Stdlib module member surface extension (math/operator/functools/collections/string/itertools/base64/random/statistics)
- Comparison: `same_output`
- Source: [ci/cases/module_stdlib_members.py](../../ci/cases/module_stdlib_members.py)

math's hyperbolic/error-function/float-decomposition families plus `isclose`/`fsum`/`sumprod`/`gamma` (integer inputs return int, invalid domains raise `ValueError`), operator's in-place family (`i*` mutates mutable containers in place and returns them) plus `call`/`inv`, functools's `cache`/`cached_property`/`total_ordering`/`update_wrapper`/`get_cache_token`, collections's `ChainMap` (chained lookup, writes go to the first map, `new_child`/`parents`) and the `UserDict`/`UserList`/`UserString` wrappers, string's `Template` (`$` placeholders/`${}` braces/`$$` escape/`safe_substitute` missing-key skip) and `Formatter`, itertools's `compress`/`combinations_with_replacement` (lexicographic order), base64's Base32 (standard and extended hex alphabets) plus Ascii85/Base85 families (`z` zero compression/`adobe` framing), random's distribution variates and `SystemRandom` (value sequences are a documented difference, callability and domains asserted), statistics's `median_low`/`median_high`/`median_grouped`/`multimode`/`correlation`/`covariance`/`linear_regression`/`NormalDist` (insufficient samples/constant inputs raise `StatisticsError`)

### module_string

- Responsibility: `string` module character constant sets
- Comparison: `same_output`
- Source: [ci/cases/module_string.py](../../ci/cases/module_string.py)

### module_time

- Responsibility: `time.sleep` suspension and clock functions
- Comparison: `same_output`
- Source: [ci/cases/module_time.py](../../ci/cases/module_time.py)

## User Class System (`class_*`)

Class definitions, inheritance and the MRO, `super()`, property/descriptors, and magic-method protocols implemented on user classes (`__getitem__`/`__hash__`/`__int__` etc.). Protocols implemented by user classes test the class system itself, distinct from built-in type behavior.

### class_async_protocol

- Responsibility: user-class async protocols (`__aiter__`/`__anext__`/`__aenter__`/`__aexit__`, async for/with driving) and the `aiter`/`anext` builtins
- Comparison: `same_output`
- Source: [ci/cases/class_async_protocol.py](../../ci/cases/class_async_protocol.py)

### class_basic

- Responsibility: Class definitions, class variables and class/static methods
- Comparison: `same_output`
- Source: [ci/cases/class_basic.py](../../ci/cases/class_basic.py)

### class_body_methods

- Responsibility: in-statement method assembly (P0-25): def statements complete method_type assembly and decorator chains immediately; property / setter / deleter / classmethod / staticmethod semantics; `Class.method` qualified names; `__set_name__` → `__init_subclass__` order; class and method decorators; super() positioning
- Comparison: `same_output`
- Source: [ci/cases/class_body_methods.py](../../ci/cases/class_body_methods.py)

### class_body_scope

- Responsibility: class-body scope rules (P0-25): method closures skip class scopes (method bodies cannot see class-body names, nested classes alike); method defaults and class-body comprehensions read class attributes at definition time; nested class binding; nonlocal in class bodies (skipping class scopes for function bindings); walrus landing in the class dict
- Comparison: `same_output`
- Source: [ci/cases/class_body_scope.py](../../ci/cases/class_body_scope.py)

### class_body_statements

- Responsibility: full class-body statement execution (P0-25): expression call side effects, if / for / while control flow and bindings, augmented assignment, del, try / except / finally, import, annotations into `__annotations__`, global writing module globals, assert, match
- Comparison: `same_output`
- Source: [ci/cases/class_body_statements.py](../../ci/cases/class_body_statements.py)

### class_body_suspend

- Responsibility: class-body suspension replay (P0-25): completed-statement side effects not repeated after in-body sleep suspension; loops / try / with / generator consumers suspending inside class bodies; class bodies inside functions and base-class evaluation replay; class bodies stepped inside generator functions
- Comparison: `same_output`
- Source: [ci/cases/class_body_suspend.py](../../ci/cases/class_body_suspend.py)

### class_base_kwargs

- Responsibility: class definition base keyword arguments (P1-72, PEP 487): `kw=` and `**` unpacking forwarded to `__init_subclass__` in source order (including the `type()` three-arg form), default object hook rejecting kw, runtime-duplicate `__build_class__` message, `metaclass=type` legality and the custom-metaclass boundary, super chain forwarding
- Comparison: `same_output`
- Source: [ci/cases/class_base_kwargs.py](../../ci/cases/class_base_kwargs.py)

### class_dup_kw

- Responsibility: compile-time SyntaxError for duplicate class-header keywords (P1-72, CPython message `keyword argument repeated: k`)
- Comparison: `same_error`
- Source: [ci/cases/class_dup_kw.py](../../ci/cases/class_dup_kw.py)

### class_metaclass

- Responsibility: custom metaclass mechanics (metaclass= `__new__` / `__init__` class-creation hooks with ns mutation writeback / `__call__` instance-creation override / metaclass methods and attributes resolved via type(cls) / instance attribute access not leaking through the metaclass / two-metaclass conflict / `__prepare__` call side effects / implicit `__module__` and `__qualname__` in the namespace)
- Comparison: `same_output`
- Source: [ci/cases/class_metaclass.py](../../ci/cases/class_metaclass.py)

### class_builtin_init

- Responsibility: user `__init__` of builtin type subclasses and constructor layering (mutable subclasses allocate empty in `__new__` and fill via init, immutable subclasses strictly consume args in `__new__` then still call init, init signature errors carry the `L.__init__` qualified name, subclass instance dicts and attribute access, set/deque subclass repr with class name, deque via `super().__init__` forwarding, bool/range/slice/memoryview/NoneType not subclassable, suspend replay inside init without duplicated side effects); strict message for user `__iter__` returning a non-iterator (for / iter() / comprehension / list() / star expansion / sorted / genexp consumption share the message, `in` uses the argument-of-type message, suspend replay falls back leniently without looping)
- Comparison: `same_output`
- Source: [ci/cases/class_builtin_init.py](../../ci/cases/class_builtin_init.py)

### class_reflect_same_type

- Responsibility: same-type reflection skip rule (CPython invokes the slot once for identical operand types, so a same-type operation with only `__r*__` defined raises TypeError without reflection; cross-type, subclass and sibling-class reflection are unaffected; augmented-assignment failure messages use the `+=` form)
- Comparison: `same_output`
- Source: [ci/cases/class_reflect_same_type.py](../../ci/cases/class_reflect_same_type.py)

### class_star_base_error

- Responsibility: metaclass-candidate resolution and call messages for non-class bases (CPython uses the base value's type as a metaclass candidate, the winner is invoked with three arguments producing its own message; direct and star forms agree, mixing class and non-class bases or distinct candidates raises `metaclass conflict` without calling, a non-callable explicit metaclass reports the call error first; a star-unpacked genuine class base still builds normally; int and str bases report their type-specialized messages)
- Comparison: `same_output`
- Source: [ci/cases/class_star_base_error.py](../../ci/cases/class_star_base_error.py)

### class_binding_errors

- Responsibility: qualified names in function binding-error messages (methods as `Class.name`, nested as `outer.<locals>.inner`, plain and lambda unqualified)
- Comparison: `same_output`
- Source: [ci/cases/class_binding_errors.py](../../ci/cases/class_binding_errors.py)

### class_context_protocol

- Responsibility: user-class context manager protocol semantics (exit argument shapes, suppression truth table, exception replacement and nested unwinding)
- Comparison: `same_output`
- Source: [ci/cases/class_context_protocol.py](../../ci/cases/class_context_protocol.py)

### class_decorators

- Responsibility: Built-in method decorators and stacked arbitrary decorators
- Comparison: `same_output`
- Source: [ci/cases/class_decorators.py](../../ci/cases/class_decorators.py)

### class_descriptor

- Responsibility: `__get__`/`__set__` descriptor protocol
- Comparison: `same_output`
- Source: [ci/cases/class_descriptor.py](../../ci/cases/class_descriptor.py)

### class_diamond

- Responsibility: Diamond inheritance `__init__` chains and `super` cooperating along the MRO
- Comparison: `same_output`
- Source: [ci/cases/class_diamond.py](../../ci/cases/class_diamond.py)

### class_dict_key_eq

- Responsibility: hash-plus-equality bucketing for user-class dict/set keys (I0-44): same-hash slots distinguished by __eq__, bigint __hash__ no longer collapses all keys
- Comparison: `same_output`
- Source: [ci/cases/class_dict_key_eq.py](../../ci/cases/class_dict_key_eq.py)

### class_hooks

- Responsibility: Class creation hooks: ordering, chained calls, failure rollback
- Comparison: `same_output`
- Source: [ci/cases/class_hooks.py](../../ci/cases/class_hooks.py)

### class_inherit

- Responsibility: Inheritance and subclass overriding of class/static methods
- Comparison: `same_output`
- Source: [ci/cases/class_inherit.py](../../ci/cases/class_inherit.py)

### class_introspect

- Responsibility: Introspection attributes of classes/objects and exception tracebacks
- Comparison: `same_output`
- Source: [ci/cases/class_introspect.py](../../ci/cases/class_introspect.py)

### class_len_eq_protocol

- Responsibility: user __len__ returning bool and __eq__ returning int protocol checks (I0-37): bool as int subclass, int truthiness, negative len raises ValueError
- Comparison: `same_output`
- Source: [ci/cases/class_len_eq_protocol.py](../../ci/cases/class_len_eq_protocol.py)

### class_magic_attr

- Responsibility: `__getattr__` attribute interception family
- Comparison: `same_output`
- Source: [ci/cases/class_magic_attr.py](../../ci/cases/class_magic_attr.py)

### class_magic_bool

- Responsibility: `__bool__`/`__len__` truthiness protocol and precedence
- Comparison: `same_output`
- Source: [ci/cases/class_magic_bool.py](../../ci/cases/class_magic_bool.py)

### class_magic_call

- Responsibility: Callable objects: `__call__` and `callable`
- Comparison: `same_output`
- Source: [ci/cases/class_magic_call.py](../../ci/cases/class_magic_call.py)

### class_magic_eq_hash

- Responsibility: `__eq__`/`__hash__`/`__iter__` user protocols
- Comparison: `same_output`
- Source: [ci/cases/class_magic_eq_hash.py](../../ci/cases/class_magic_eq_hash.py)

### class_magic_hash

- Responsibility: `hash()` with custom `__hash__` and unhashable types
- Comparison: `same_output`
- Source: [ci/cases/class_magic_hash.py](../../ci/cases/class_magic_hash.py)

### class_magic_order

- Responsibility: `__lt__`/`__gt__` bridging into sorting and `min`/`max`
- Comparison: `same_output`
- Source: [ci/cases/class_magic_order.py](../../ci/cases/class_magic_order.py)

### class_magic_protocol

- Responsibility: User classes implementing length/membership/iteration protocols
- Comparison: `same_output`
- Source: [ci/cases/class_magic_protocol.py](../../ci/cases/class_magic_protocol.py)

### class_magic_reflect

- Responsibility: `__radd__` and other reflected operators with precedence
- Comparison: `same_output`
- Source: [ci/cases/class_magic_reflect.py](../../ci/cases/class_magic_reflect.py)

### class_magic_str_repr

- Responsibility: `__str__`/`__repr__` definitions and the built-in fallback
- Comparison: `same_output`
- Source: [ci/cases/class_magic_str_repr.py](../../ci/cases/class_magic_str_repr.py)

### class_mro

- Responsibility: Multiple inheritance C3 linearization, `__mro__` and attribute lookup
- Comparison: `same_output`
- Source: [ci/cases/class_mro.py](../../ci/cases/class_mro.py)

### class_property

- Responsibility: `@property` read/write and read-only interception
- Comparison: `same_output`
- Source: [ci/cases/class_property.py](../../ci/cases/class_property.py)

### class_property_slots

- Responsibility: Recursive container `repr`, `property` deleters and slot restrictions
- Comparison: `same_output`
- Source: [ci/cases/class_property_slots.py](../../ci/cases/class_property_slots.py)

### class_protocol_index

- Responsibility: `__index__` protocol for subscripts, slices and error propagation
- Comparison: `same_output`
- Source: [ci/cases/class_protocol_index.py](../../ci/cases/class_protocol_index.py)

### class_protocol_item

- Responsibility: User-class `__getitem__` read/write/delete protocol
- Comparison: `same_output`
- Source: [ci/cases/class_protocol_item.py](../../ci/cases/class_protocol_item.py)

### class_protocol_numconv

- Responsibility: User-class `__int__` numeric conversion protocol and error types
- Comparison: `same_output`
- Source: [ci/cases/class_protocol_numconv.py](../../ci/cases/class_protocol_numconv.py)

### class_protocol_validate

- Responsibility: User-class magic method return type validation (invalid `__len__`/`__bool__`/`__init__`/`__repr__`/`__str__` return raises TypeError/ValueError)
- Comparison: `same_output`
- Source: [ci/cases/class_protocol_validate.py](../../ci/cases/class_protocol_validate.py)

### class_scope

- Responsibility: Class body scope, comprehensions in class bodies and `super` in `property`
- Comparison: `same_output`
- Source: [ci/cases/class_scope.py](../../ci/cases/class_scope.py)

### class_slots

- Responsibility: `__slots__` whitelist assignment and inheritance behavior
- Comparison: `same_output`
- Source: [ci/cases/class_slots.py](../../ci/cases/class_slots.py)

### class_star_bases

- Responsibility: Starred base expansion, duplicate and non-class base errors
- Comparison: `same_output`
- Source: [ci/cases/class_star_bases.py](../../ci/cases/class_star_bases.py)

### class_stopiteration

- Responsibility: user __next__ raising StopIteration subclass ends iteration (I0-61): subclass treated as exhaustion, PEP 479 for generators
- Comparison: `same_output`
- Source: [ci/cases/class_stopiteration.py](../../ci/cases/class_stopiteration.py)

### class_super

- Responsibility: `super()` zero-arg and two-arg call chains
- Comparison: `same_output`
- Source: [ci/cases/class_super.py](../../ci/cases/class_super.py)

### class_super_forms

- Responsibility: `super` two-arg/class-method forms, exception multiple inheritance, three-arg `type`, `match` capture
- Comparison: `same_output`
- Source: [ci/cases/class_super_forms.py](../../ci/cases/class_super_forms.py)

## Exception System (`exception_*`)

Exception hierarchy and catching semantics (`BaseException`, inheritance-based catching), exception object semantics (str/repr/args) and runtime error propagation (through generators and iterators). Grammar-level compile errors belong to the `syntax_*` family.

### exception_as_binding

- Responsibility: Divide-by-zero exception bound with `as`, then reading its message
- Comparison: `same_output`
- Source: [ci/cases/exception_as_binding.py](../../ci/cases/exception_as_binding.py)

### exception_attrs_internal

- Responsibility: `args`/`repr` shapes of exception objects from internal error sites
- Comparison: `same_output`
- Source: [ci/cases/exception_attrs_internal.py](../../ci/cases/exception_attrs_internal.py)

### exception_bare_except

- Responsibility: Bare `except` catching any exception type
- Comparison: `same_output`
- Source: [ci/cases/exception_bare_except.py](../../ci/cases/exception_bare_except.py)

### exception_base

- Responsibility: `BaseException` catching semantics and custom direct subclasses
- Comparison: `same_output`
- Source: [ci/cases/exception_base.py](../../ci/cases/exception_base.py)

### exception_base_match

- Responsibility: `except` `Exception` catching subclass exceptions
- Comparison: `same_output`
- Source: [ci/cases/exception_base_match.py](../../ci/cases/exception_base_match.py)

### exception_bool_rare

- Responsibility: `__bool__` non-bool error propagation in rare paths (exception-group filter validation / lazy predicates / operator / any / all)
- Comparison: `same_output`
- Source: [ci/cases/exception_bool_rare.py](../../ci/cases/exception_bool_rare.py)

### exception_divzero

- Responsibility: Bare `except` catching divide-by-zero
- Comparison: `same_output`
- Source: [ci/cases/exception_divzero.py](../../ci/cases/exception_divzero.py)

### exception_err_shapes

- Responsibility: `format`/slicing/power/`setattr` error shape collection
- Comparison: `same_output`
- Source: [ci/cases/exception_err_shapes.py](../../ci/cases/exception_err_shapes.py)

### exception_except_bad_type

- Responsibility: except clause with a non-BaseException-subclass type raises TypeError
- Comparison: `same_output`
- Source: [ci/cases/exception_except_bad_type.py](../../ci/cases/exception_except_bad_type.py)

### exception_finally_after_except

- Responsibility: `finally` runs after `except` and can change values
- Comparison: `same_output`
- Source: [ci/cases/exception_finally_after_except.py](../../ci/cases/exception_finally_after_except.py)

### exception_finally_on_exc

- Responsibility: Outer `finally` runs after the exception has been handled
- Comparison: `same_output`
- Source: [ci/cases/exception_finally_on_exc.py](../../ci/cases/exception_finally_on_exc.py)

### exception_finally_only

- Responsibility: `try`/`finally` without `except` control flow
- Comparison: `same_output`
- Source: [ci/cases/exception_finally_only.py](../../ci/cases/exception_finally_only.py)

### exception_gen_propagate

- Responsibility: Exceptions raised mid-generator propagate through `list`/`tuple`/`sorted`
- Comparison: `same_output`
- Source: [ci/cases/exception_gen_propagate.py](../../ci/cases/exception_gen_propagate.py)

### exception_group

- Responsibility: `ExceptionGroup` and `BaseExceptionGroup` (construction validation, attributes, str/repr, subgroup/split)
- Comparison: `same_output`
- Source: [ci/cases/exception_group.py](../../ci/cases/exception_group.py)

### exception_except_star

- Responsibility: `except*` semantics (subgroup matching and shape, auto-wrapping, multi-clause remainder consumption, else/finally, handler exceptions)
- Comparison: `same_output`
- Source: [ci/cases/exception_except_star.py](../../ci/cases/exception_except_star.py)

### exception_hierarchy

- Responsibility: Built-in exception inheritance catching and post-catch state isolation
- Comparison: `same_output`
- Source: [ci/cases/exception_hierarchy.py](../../ci/cases/exception_hierarchy.py)

### exception_inherit_catch

- Responsibility: `ArithmeticError` catching divide-by-zero
- Comparison: `same_output`
- Source: [ci/cases/exception_inherit_catch.py](../../ci/cases/exception_inherit_catch.py)

### exception_iter_propagate

- Responsibility: User-iterator `__next__` exceptions propagate through consumers
- Comparison: `same_output`
- Source: [ci/cases/exception_iter_propagate.py](../../ci/cases/exception_iter_propagate.py)

### exception_multi_except

- Responsibility: Multiple `except` clauses hit the right branch in order
- Comparison: `same_output`
- Source: [ci/cases/exception_multi_except.py](../../ci/cases/exception_multi_except.py)

### exception_nested_try

- Responsibility: Nested `try` caught by the inner handler by type
- Comparison: `same_output`
- Source: [ci/cases/exception_nested_try.py](../../ci/cases/exception_nested_try.py)

### exception_no_exc_path

- Responsibility: `try` with no exception does not enter the `except` branch
- Comparison: `same_output`
- Source: [ci/cases/exception_no_exc_path.py](../../ci/cases/exception_no_exc_path.py)

### exception_propagate

- Responsibility: Unmatched inner exceptions propagate to an outer catch
- Comparison: `same_output`
- Source: [ci/cases/exception_propagate.py](../../ci/cases/exception_propagate.py)

### exception_raise_basic

- Responsibility: `raise`, then catching and printing via `except` `as`
- Comparison: `same_output`
- Source: [ci/cases/exception_raise_basic.py](../../ci/cases/exception_raise_basic.py)

### exception_raise_in_handler

- Responsibility: A new exception raised inside `except` is caught by the outer handler
- Comparison: `same_output`
- Source: [ci/cases/exception_raise_in_handler.py](../../ci/cases/exception_raise_in_handler.py)

### exception_repr

- Responsibility: Exception `args`/`str`/`repr` and `repr` quote selection
- Comparison: `same_output`
- Source: [ci/cases/exception_repr.py](../../ci/cases/exception_repr.py)

### exception_reraise

- Responsibility: Bare `raise` re-raising the current exception, caught again
- Comparison: `same_output`
- Source: [ci/cases/exception_reraise.py](../../ci/cases/exception_reraise.py)

### exception_specificity

- Responsibility: Multiple `except` clauses hit the most specific type
- Comparison: `same_output`
- Source: [ci/cases/exception_specificity.py](../../ci/cases/exception_specificity.py)

### exception_str

- Responsibility: Exception `str`/`args` and the `KeyError` message special case
- Comparison: `same_output`
- Source: [ci/cases/exception_str.py](../../ci/cases/exception_str.py)

### exception_str_uninit

- Responsibility: Custom exception without `super().__init__` formats `str(e)` from `args`
- Comparison: `same_output`
- Source: [ci/cases/exception_str_uninit.py](../../ci/cases/exception_str_uninit.py)

### exception_tuple_except

- Responsibility: `except` tuple with multiple types hits one of them
- Comparison: `same_output`
- Source: [ci/cases/exception_tuple_except.py](../../ci/cases/exception_tuple_except.py)

### exception_tuple_mismatch

- Responsibility: A non-matching tuple `except` propagates outward and is caught
- Comparison: `same_output`
- Source: [ci/cases/exception_tuple_mismatch.py](../../ci/cases/exception_tuple_mismatch.py)

### exception_tuple_multi

- Responsibility: Three-type tuple `except` hits `TypeError`
- Comparison: `same_output`
- Source: [ci/cases/exception_tuple_multi.py](../../ci/cases/exception_tuple_multi.py)

### exception_type_mismatch

- Responsibility: Inner type-mismatch exception propagates outward
- Comparison: `same_output`
- Source: [ci/cases/exception_type_mismatch.py](../../ci/cases/exception_type_mismatch.py)

### exception_uncaught_line

- Responsibility: Line-number reporting for uncaught exceptions (in-frame raising line)
- Comparison: `same_error` (declares `行号: same`; the raising line number is verified)
- Source: [ci/cases/exception_uncaught_line.py](../../ci/cases/exception_uncaught_line.py)

### exception_unbound_local

- Responsibility: `UnboundLocalError` collection and layering
- Comparison: `same_output`
- Source: [ci/cases/exception_unbound_local.py](../../ci/cases/exception_unbound_local.py)

## Suspension System (`suspend_*`)

PyGDS-specific suspend/resume mechanics (statement replay after a `time.sleep`-triggered SLEEPING suspend). The CPython side serves as the behavioral reference with blocking sleeps; both ends must produce the same complete output.

### suspend_async_replay

- Responsibility: suspension and replay inside coroutine bodies (sleep in await chains / async for / async with, interleaved multi-coroutine driving)
- Comparison: `same_output`
- Source: [ci/cases/suspend_async_replay.py](../../ci/cases/suspend_async_replay.py)

### suspend_call_replay

- Responsibility: Side effects run once when a suspend replays adjacent calls
- Comparison: `same_output`
- Source: [ci/cases/suspend_call_replay.py](../../ci/cases/suspend_call_replay.py)

### suspend_close_order

- Responsibility: statement-level replay of a close()-driven suspension inside the finally body (output inside the finally precedes the close return value, matching CPython's synchronous close): basic form, expression chains, for-loop exhaustion cleanup, close inside with `__exit__`, RuntimeError for catch-sleep-yield after GeneratorExit, two-level delegation close, multi-sleep continuation
- Comparison: `same_output`
- Source: [ci/cases/suspend_close_order.py](../../ci/cases/suspend_close_order.py)

### suspend_comp_effect

- Responsibility: Side effects run once when a comprehension's iterable suspends
- Comparison: `same_output`
- Source: [ci/cases/suspend_comp_effect.py](../../ci/cases/suspend_comp_effect.py)

### suspend_dunder

- Responsibility: Suspension inside magic methods: comparison/truthiness, and replay of argument-constructing calls
- Comparison: `same_output`
- Source: [ci/cases/suspend_dunder.py](../../ci/cases/suspend_dunder.py)

### suspend_finally_raise

- Responsibility: In-flight exception propagation when `finally` suspends
- Comparison: `same_output`
- Source: [ci/cases/suspend_finally_raise.py](../../ci/cases/suspend_finally_raise.py)

### suspend_getitem_iter

- Responsibility: Suspension replay of the legacy `__getitem__` iteration protocol
- Comparison: `same_output`
- Source: [ci/cases/suspend_getitem_iter.py](../../ci/cases/suspend_getitem_iter.py)

When `__getitem__` suspends on `sleep` mid-body, the index iterator raises its `suspended` flag for consumers to propagate and hands control to statement replay instead of treating it as end of iteration; the replay round resumes the interrupted `__getitem__` via frame reuse, with sleep deduplication preventing repeated waits. Covers list / comprehension / sum / for and zip dual-argument parallel consumption (I2-62)

### suspend_groupby

- Responsibility: `groupby` state machine surviving across statements with `sleep` replay
- Comparison: `same_output`
- Source: [ci/cases/suspend_groupby.py](../../ci/cases/suspend_groupby.py)

### suspend_iter_consumers

- Responsibility: Built-in consumers replaying generators that `sleep` mid-step
- Comparison: `same_output`
- Source: [ci/cases/suspend_iter_consumers.py](../../ci/cases/suspend_iter_consumers.py)

### suspend_lazy

- Responsibility: Laziness of `sleep` inside comprehensions/generators
- Comparison: `same_output`
- Source: [ci/cases/suspend_lazy.py](../../ci/cases/suspend_lazy.py)

### suspend_match

- Responsibility: `match` subject/guard/body suspend replay
- Comparison: `same_output`
- Source: [ci/cases/suspend_match.py](../../ci/cases/suspend_match.py)

### suspend_nested

- Responsibility: Nested generator suspension and exception propagation
- Comparison: `same_output`
- Source: [ci/cases/suspend_nested.py](../../ci/cases/suspend_nested.py)

### suspend_sideeffect

- Responsibility: Side effects of consuming generators containing `sleep`
- Comparison: `same_output`
- Source: [ci/cases/suspend_sideeffect.py](../../ci/cases/suspend_sideeffect.py)

### suspend_user_iter

- Responsibility: Suspension replay of user iterators whose `__iter__` returns `self`
- Comparison: `same_output`
- Source: [ci/cases/suspend_user_iter.py](../../ci/cases/suspend_user_iter.py)

Suspension on `sleep` inside `__next__` propagates to consumers via the iterator's `suspended` flag; a user iterator is a one-shot iterator, so produced values are logged and join the statement consumption window — the replay round re-reads delivered elements from the log and drives `__next__` only for new elements, converging as instance state advances across replay rounds in step with sleep deduplication (I2-60). Includes an `__iter__` returning `iter(generator)` comparison form

### suspend_with_replay

- Responsibility: suspension and replay of the `with` body and `__exit__` (enter marker prevents re-entry, P0-22 parking stack-up)
- Comparison: `same_output`
- Source: [ci/cases/suspend_with_replay.py](../../ci/cases/suspend_with_replay.py)

### suspend_zip_multi_arg

- Responsibility: Suspension replay of `zip` consuming wrapper iterator classes across multiple arguments
- Comparison: `same_output`
- Source: [ci/cases/suspend_zip_multi_arg.py](../../ci/cases/suspend_zip_multi_arg.py)

zip consumes argument by argument; when one argument's consumption suspends mid-way it propagates the suspension immediately and abandons the call instead of fetching the next argument's iterator while `_suspended` is set (the user `__iter__` would spuriously suspend and return null, misreported as `zip() arg is not iterable`); replay rounds reuse each argument's generator via the generator memo in occurrence order (I2-61). Includes single-argument comparison plus fielded instances, three arguments, and mixed sequence forms; protocol-driven `__iter__` / `__next__` calls no longer borrow the ambient call node for retired completion records
