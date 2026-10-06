# Behavior Test System

All behavior tests of PyGDS live in `ci/cases/`, using **dual-end live comparison**: each run executes CPython and PyGDS once, side by side, and verifies that both behave identically according to the semantics declared per case — no frozen expected output is used

## Layout

| File | Responsibility |
| :--- | :--- |
| [cases/](../../ci/cases/) | All cases; one `.py` file = one responsibility, the file name is the responsibility statement |
| [run_cases.gd](../../ci/run_cases.gd) | Dual-end runner: runs PyGDS in-process, drives CPython via `_pyrun.py`, verdicts per the matrix below |
| [_pyrun.py](../../ci/_pyrun.py) | CPython execution shim: runs one case and hands back stdout/stderr/exit code as a JSON file (executes only, never judges) |
| [lint_cases.py](../../ci/lint_cases.py) | Structure checks: header metadata, naming registry, one-to-one doc entries |
| [lint_md.py](../../ci/lint_md.py) | Markdown mechanical checks (hard line breaks/fence pairing/MD038), run from the repository root |
| [lint_gd.py](../../ci/lint_gd.py) | GDScript mechanical checks (inline multi-statements/code semicolons/`[br]` rules), run from the repository root |

## Running

```bash
# Full run (same as CI)
godot --headless --path . --script res://ci/run_cases.gd

# Only cases whose name contains math
godot --headless --path . --script res://ci/run_cases.gd -- --filter=math

# Structure checks
python ci/lint_cases.py

# Markdown / GDScript mechanical checks
python ci/lint_md.py
python ci/lint_gd.py

# Suspension system suite (PyGDS-specific, 24 cases)
godot --headless --path . --script res://demo/test_suspend_all.gd

# Drive sandbox suite (PyGDS-specific, 48 checks)
godot --headless --path . --script res://demo/test_sandbox.gd
```

The runner auto-detects the CPython command (`python` first on Windows, `python3` first on Linux)

PyGDS-specific capabilities (suspension / sandbox) have no CPython counterpart to compare against, so they stay out of the `ci/cases/` dual-end comparison system and are covered by standalone suites under `demo/` that run in CI (`test_suspend_all.gd` and `test_sandbox.gd`), judged against self-contained expected outputs

File-based cases (open / user import and their fixtures) run inside the `CI` drive sandbox: the runner instantiates `PyGDS.new("CI", true)`, wipes `user://<base_path>/CI/` at startup and copies the `ci/cases/files/` fixtures into the drive; the CPython shim uses the drive root's real path as its working directory, so bare relative paths on both ends land in the same physical directory (data-file leftovers stay inside the drive instead of polluting the project root)

## Naming Registry

The file name is the responsibility statement; family prefixes:

| Prefix | Domain | Examples |
| :--- | :--- | :--- |
| `syntax_*` | Statement and expression grammar constructs, including their compile-time `SyntaxError`s | `syntax_for`, `syntax_try`, `syntax_match_dup_bind` |
| `comprehension_*` | Comprehension family, distinct from `syntax_for`; may carry `_<aspect>` extensions | `comprehension_list`, `comprehension_multi`, `comprehension_genexp` |
| `builtin_*` | Built-in functions | `builtin_print`, `builtin_isinstance` |
| `type_*` | Built-in types: construction, operator behavior and methods | `type_str_methods`, `type_int` |
| `module_*` | Standard library modules | `module_math`, `module_statistics` |
| `class_*` | User class system (definition/inheritance/MRO/magic methods/descriptors) | `class_mro`, `class_descriptor` |
| `exception_*` | Exception system and runtime error semantics | `exception_hierarchy`, `exception_attrs` |
| `suspend_*` | Suspension system (PyGDS-specific; the CPython side serves as behavioral reference with blocking sleeps) | `suspend_sleep_replay` |
| `misc_*` | Fallback: cases that cannot be placed in any family above | - |

**Boundary rules** (a case belongs to the construct that introduces the behavior):

1. The `for` statement and its direct derivatives (target unpacking `for x, y in xxx:`, `for...else`) belong to the `syntax_for` family; a `for` inside a comprehension belongs to the comprehension family — `[for i in range(10)]` is the responsibility of `comprehension_list`, not `syntax_for`
2. Type-method behavior belongs to `type_*`, built-in functions to `builtin_*`, standard library modules to `module_*`; a single function like `math.sqrt` is split into its own `module_math_sqrt` when its behavior grows large enough (rule of thumb: ≥3 independent behaviors or a known-fragile area)
3. Protocols implemented on user classes (`__getitem__`/`__iter__`/`__hash__` etc.) belong to `class_*` — they test the class system, not the emulated built-in types
4. Syntax-error cases are named after the construct that fails: `match` duplicate-binding compile errors → `syntax_match_dup_bind`; runtime catching semantics belong to `exception_*`
5. `misc_*` is the last resort: prefer placing a new case in a family above by semantics; only fall back to `misc_*` when there is truly no home, and explain why in the doc entry

## Case Header Metadata

Every case file must start with line comments in the following form (parsed by both the runner and the lint; the default comparison value is `same_output`):

```python
# duty: <Describe the content being tested in the file>
# compare: same_output | same_exception | same_error | diverge
# anchor: CPython 3.12      # optional: CPython version the message was verified against
# ref: P2-2                 # optional: known-issue number or doc reference
# lines: same               # optional: extra line-number comparison for error cases (see below)
# skip: <reason>            # optional: skip, excluded from verdicts
```

Keys accept both English (`duty` / `compare` / `anchor` / `ref` / `lines` / `lines`) and Chinese aliases (`职责` / `比对` / `锚定` / `关联` / `行号` / `跳过`), the parser normalizes them to the English keys. Everything from `" # "` (space-hash-space) inside a value is a trailing comment and is stripped — `lines: same   # raised inside the loop` is equivalent to `lines: same`. Avoid `" # "` inside duty prose

Inside the body, precede each case section with a comment stating the CPython behavior being verified and the alignment point. Subtle behavior (evaluation order, boundary values, standing divergences) must state "what CPython does and why PyGDS must match"

## Verdict Matrix

| Comparison | Precondition | Pass condition |
| :--- | :--- | :--- |
| `same_output` | both ends complete | stdout matches verbatim after normalization |
| `same_exception` | both ends error | exception class matches exactly (**no subclass tolerance**: `ValueError` vs `Exception` is not a match) |
| `same_error` | both ends error | class and message both match (after stripping the `" (line N)"` suffix and normalizing) |
| `diverge` | documented standing divergence | only requires both ends to agree on erroring vs completing |

**One-sided errors** (one end errors while the other completes) FAIL regardless of the declared value — it means code that works under CPython errors in PyGDS (or vice versa), the most glaring kind of regression

**Line-number comparison**: error cases may declare `# lines: same` (Chinese alias `# 行号: same`) (runtime uncaught exceptions only; parse errors have different line semantics on the two ends). The runner checks the `(line N)` suffix of the PyGDS error against the last `File ..., line N` frame of the CPython traceback; a mismatch is `LINE`, a missing number on either side is `LINE-UNKNOWN`. Runtime error line numbers are a feature claimed in the README compatibility matrix, guarded by this mechanism

Failure kinds: `ONESIDED` (one-sided error) / `ERRTYPE` (class differs) / `ERRMSG` (message differs) / `OUT` (stdout differs) / `UNEXPECTED-ERR` (declared same_output but both error) / `NO-ERR` (declared error but both complete) / `CASE-ERR` (shim/case failure) / `META` (unknown comparison value)

The `same_exception` → `same_error` upgrade path doubles as the message-alignment tracker: cases with unaligned messages start at `same_exception` (referencing P2-2 etc.), upgrade to `same_error` once aligned, and CI then guards the message against regressions

## Normalization (same rules on both ends)

- CRLF converted to LF
- Default object repr: strips `" at 0x…>"` (memory addresses differ per run) and the `<__main__.` module prefix — PyGDS's default object repr is the simplified form `<Foo object>`, a standing divergence absorbed by normalization for now, removable once aligned
- The `"Line N, Column M: "` prefix of unaligned PyGDS parser messages (P2-2) is normalized to the `"SyntaxError: "` prefix during extraction — it is a `SyntaxError` in substance, only the message format is unaligned; such cases should declare `same_exception` (class names align) and upgrade to `same_error` once the message is aligned

The normalization set must stay tiny; any case needing "its own normalization rule" is a smell — rewrite the case

## Case Authoring Rules (Determinism)

Dual-end comparison requires cases to be stable **across two runs on the same end**:

1. Do not print raw memory addresses (default repr excepted, already normalized), raw `time.time()` values, or raw `random` values; test random behavior through invariants ("same `seed` yields the same sequence", "zero-weight elements are never drawn")
2. Keep `time.sleep` at the `0.05` scale — the CPython side blocks for real, so large values slow the whole suite; and intervals below the Windows timer quantum (~0.0156s) may not advance at all, making monotonic-clock assertions non-deterministic
3. Do not use `sys.exit` / `input` / file IO
4. Float results of non-IEEE-correctly-rounded libm functions (`cbrt` / `pow` / `exp` / `log` / trig family) must be compared after `round(..., N)` — glibc and the Windows CRT round differently; `sqrt` / `remainder` are correctly rounded and compare directly
5. Do not test `is` identity of runtime-constructed strings — the single-char cache and strip self-return are CPython version-specific implementation details (3.12.8 and 3.13 differ); test compile-time literal identity and `==` semantics
6. Error cases: scripts ending in an uncaught exception use `same_error`/`same_exception`; `try`-caught-and-printed ones are plain `same_output`

## Workflow for Adding a Case

1. Create `<family>_<topic>.py` in `ci/cases/`: header metadata + commented case body
2. `python ci/lint_cases.py` — it will point out missing documentation
3. Add an entry in the matching family section of [behavioral.md](behavioral.md) (responsibility/comparison/source link; add prose for subtle behavior)
4. Verify with `godot --headless --path . --script res://ci/run_cases.gd -- --filter=<case>`, then run the full suite
