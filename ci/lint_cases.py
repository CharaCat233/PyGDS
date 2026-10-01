"""
ci/cases 用例体系的结构检查

检查项:

1. 头注元数据完整且合法 (duty/职责 非空, compare/比对 值为四种之一, 键中英并存)
2. 文件名符合家族注册表 (见 docs/zh-CN/ci.md)
3. same_output 用例必须能通过 CPython 编译 (报错用例允许编译失败)
4. docs/zh-CN/behavioral.md 与 docs/en/behavioral.md 与用例一一对应:
   每个用例在两份文档中都有 `### <用例名>` 条目, 文档中形似用例名的条目
   不得指向不存在的文件

家族注册表与判定矩阵见 docs/zh-CN/ci.md

用法:
    python ci/lint_cases.py
"""

import re
import sys
import warnings
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CASES_DIR = ROOT / "ci" / "cases"
DOC_PATHS = [
    ROOT / "docs" / "zh-CN" / "behavioral.md",
    ROOT / "docs" / "en" / "behavioral.md",
]

MATCH_MODES = {"same_output", "same_exception", "same_error", "diverge"}

FAMILY_PREFIXES = (
    "syntax_",
    "comprehension_",
    "builtin_",
    "type_",
    "module_",
    "class_",
    "exception_",
    "suspend_",
    "misc_",
)
CASE_NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")
DOC_ENTRY_RE = re.compile(r"^### ([a-z][a-z0-9_]*)\s*$")

HEADER_KEY_ALIASES = {
    "duty": "duty",
    "职责": "duty",
    "compare": "compare",
    "比对": "compare",
    "anchor": "anchor",
    "锚定": "anchor",
    "ref": "ref",
    "关联": "ref",
    "lines": "lines",
    "行号": "lines",
    "skip": "skip",
    "跳过": "skip",
}


def parse_header(source: str) -> dict:
    """解析头注元数据; 键中英并存归一化为英文键, 值中 " # " 起为尾注释被剥离。"""
    meta = {}
    for line in source.splitlines():
        t = line.strip()
        if t == "":
            continue
        if not t.startswith("#"):
            break
        body = t[1:].strip()
        idx = body.find(":")
        if idx > 0:
            key = body[:idx].strip().lower()
            key = HEADER_KEY_ALIASES.get(key, key)
            value = body[idx + 1 :].strip()
            comment = value.find(" # ")
            if comment != -1:
                value = value[:comment].strip()
            meta[key] = value
    return meta


def name_ok(name: str) -> bool:
    return name.startswith(FAMILY_PREFIXES)


def main() -> int:
    problems = []

    case_files = sorted(p for p in CASES_DIR.glob("*.py") if not p.name.startswith("_"))
    case_names = set()

    for path in case_files:
        name = path.stem
        case_names.add(name)

        if not name_ok(name):
            problems.append(
                f"{path.name}: 文件名不符合家族注册表 (见 docs/zh-CN/ci.md)"
            )

        source = path.read_text(encoding="utf-8")
        meta = parse_header(source)

        duty = meta.get("duty", "")
        if not duty:
            problems.append(f"{path.name}: 缺少「# 职责:」头注")
        mode = meta.get("compare", "same_output")
        if mode not in MATCH_MODES:
            problems.append(
                f"{path.name}: 「比对/compare」值非法: {mode} (应为 {' / '.join(sorted(MATCH_MODES))})"
            )

        if mode == "same_output":
            # 用例本身可能在测转义序列等会触发编译期警告的写法, 屏蔽警告只看能否编译
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                try:
                    compile(source, name, "exec")
                except SyntaxError as e:
                    problems.append(
                        f"{path.name}: 声明 same_output 但源码无法编译: {e}"
                    )

    doc_names_by_doc = {}
    for doc_path in DOC_PATHS:
        doc_names = set()
        if doc_path.exists():
            for line in doc_path.read_text(encoding="utf-8").splitlines():
                m = DOC_ENTRY_RE.match(line.strip())
                if m:
                    doc_names.add(m.group(1))
        else:
            problems.append(f"缺少文档: {doc_path.relative_to(ROOT)}")
        doc_names_by_doc[doc_path] = doc_names

    for doc_path, doc_names in doc_names_by_doc.items():
        lang = doc_path.parent.name
        for name in sorted(case_names - doc_names):
            problems.append(f"{name}: 缺少文档条目 ({lang}: 没有 ### {name})")
        for name in sorted(doc_names - case_names):
            problems.append(f"文档条目悬空 ({lang}): ### {name} 没有对应的用例文件")

    if problems:
        print(f"lint: {len(problems)} 个问题")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(f"lint: OK ({len(case_names)} 个用例, 文档条目一一对应)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
