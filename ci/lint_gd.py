"""GDScript 机械自查

检查三类问题:
  1. 行内多语句 (冒号后同行还有语句)
  2. 代码区出现分号 `;`
  3. 文档注释 [br] 规则

判定前先剥离字符串与注释, 避免误判
"""

import glob
import re
import sys

BACKSLASH = chr(92)


def strip_code(line, in_triple):
    """返回 (代码部分, 是否仍在三引号串内)"""
    if in_triple:
        if '"""' in line:
            return "", False
        return "", True
    out = []
    i = 0
    quote = None
    while i < len(line):
        ch = line[i]
        if quote is not None:
            if ch == BACKSLASH:
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue
        if line[i : i + 3] == '"""':
            rest = line[i + 3 :]
            if '"""' in rest:
                i += 3 + rest.index('"""') + 3
                continue
            return "".join(out), True
        if ch in ('"', "'"):
            quote = ch
            i += 1
            continue
        if ch == "#":
            break
        out.append(ch)
        i += 1
    return "".join(out), False


def main():
    files = sorted(
        f
        for f in glob.glob("**/*.gd", recursive=True)
        if "addons" not in f.replace("\\", "/")
    )
    inline_multi = []
    semicolons = []
    br_issues = []
    for path in files:
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
        in_triple = False
        for n, line in enumerate(lines, 1):
            code, in_triple = strip_code(line, in_triple)
            stripped = code.strip()
            if stripped:
                m = re.match(
                    r"^(if|elif|else|for|while|def|class|try|except|finally|with)\b",
                    stripped,
                )
                if m:
                    head = stripped[len(m.group(1)) :]
                    if ":" in head:
                        after = head[head.index(":") + 1 :].strip()
                        if (
                            after
                            and not after.startswith("=")
                            and "lambda" not in stripped
                        ):
                            inline_multi.append((path, n, stripped[:110]))
                if ";" in code:
                    semicolons.append((path, n, stripped[:110]))
            # [br] 规则: 仅当下一行也是文档注释时才能带 [br]
            s = line.rstrip("\r")
            if s.lstrip().startswith("##") and s.rstrip().endswith("[br]"):
                nxt = lines[n].rstrip("\r") if n < len(lines) else ""
                if not nxt.lstrip().startswith("##"):
                    br_issues.append((path, n, s.strip()[:110]))
    print(f"files scanned: {len(files)}")
    for name, items in (
        ("行内多语句", inline_multi),
        ("代码区分号", semicolons),
        ("[br] 规则", br_issues),
    ):
        print(f"{name}: {len(items)}")
        for it in items[:15]:
            print(f"    {it[0]}:{it[1]}  {it[2]}")
    return 0 if not (inline_multi or semicolons or br_issues) else 1


if __name__ == "__main__":
    sys.exit(main())
