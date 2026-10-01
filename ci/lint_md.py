"""
Markdown 机械自查

检查:
  1. 非 `tests/提交文本.md` 的文档是否存在主动换行 (段落/列表项被拆成多行)
  2. 代码围栏是否配对 (每个文档的围栏数为偶数)
  3. 行内代码内容不以空格开头或结尾 (MD038/no-space-in-code, 需展示前导空格时用 repr 引号形态锚定)
"""

import glob
import re
import sys

SKIP_HARDLINE = {"tests/提交文本.md"}

# 有序列表项: 1. / 1) / 1、
LIST_ITEM = re.compile(r"^\d+[.)、]")

# 行内代码 span: 成对的反引号 (粗略扫描, 不处理跨行 span)
_CODE_SPAN = re.compile(r"`([^`]+)`")


def _check_code_spans(rel, lines):
    """
    行内代码内容以空格开头或结尾时报 MD038 (no-space-in-code)

    CommonMark 会剥掉首尾各一个空格, 使空格数失真, 需要展示前导
    空格时用 repr 引号形态锚定首尾
    分隔符游程配对: 反引号连续段长度为 N 时, 闭合段亦须为 N, 以正确处理历史内容中的双反引号分隔符
    """
    issues = []
    in_fence = False
    for n, ln in enumerate(lines):
        if ln.strip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        body = ln.rstrip()
        i = 0
        while i < len(body):
            if body[i] != "`":
                i += 1
                continue
            run = i
            while i < len(body) and body[i] == "`":
                i += 1
            n_len = i - run
            close = body.find("`" * n_len, i)
            if close == -1:
                continue
            content = body[i:close]
            i = close + n_len
            if content != content.strip(" "):
                issues.append((rel, n + 1, content[:40]))
    return issues


def main():
    files = sorted(
        f
        for f in glob.glob("**/*.md", recursive=True)
        if "addons" not in f.replace("\\", "/")
    )
    wrap_issues = []
    fence_issues = []
    span_issues = []
    for path in files:
        rel = path.replace("\\", "/")
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
        fences = sum(1 for ln in lines if ln.strip().startswith("```"))
        if fences % 2 != 0:
            fence_issues.append((rel, fences))
        span_issues.extend(_check_code_spans(rel, lines))
        if rel in SKIP_HARDLINE:
            continue
        in_fence = False
        for n, ln in enumerate(lines):
            if ln.strip().startswith("```"):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            s = ln.rstrip("\r")
            if not s.strip():
                continue
            # 主动换行的启发式: 上一行是正文 (不是列表项), 本行也是正文续行
            # 连续的列表项各占一行是正常写法, 不算主动换行
            if n == 0:
                continue
            prev = lines[n - 1].rstrip("\r")
            if not prev.strip():
                continue
            if prev.strip().startswith(("#", "|", ">", "```", "-", "*", " ", "\t")):
                continue
            if LIST_ITEM.match(prev.strip()):
                continue
            if prev.rstrip().endswith(
                ("。", "；", "：", "！", "？", ".", ";", ":", "!", "?", "|")
            ):
                continue
            if s.strip().startswith(("#", "|", ">", "```")):
                continue
            wrap_issues.append((rel, n + 1, prev.strip()[:70], s.strip()[:70]))
    print(f"files scanned: {len(files)}")
    print(f"围栏配对问题: {len(fence_issues)}")
    for it in fence_issues:
        print(f"    {it[0]}: {it[1]} 个围栏")
    print(f"疑似主动换行: {len(wrap_issues)}")
    for it in wrap_issues[:20]:
        print(f"    {it[0]}:{it[1]}\n        上一行: {it[2]}\n        本行:   {it[3]}")
    print(f"行内代码首尾空格: {len(span_issues)}")
    for it in span_issues[:20]:
        print(f"    {it[0]}:{it[1]}  内容: {it[2]!r}")
    return 1 if (fence_issues or wrap_issues or span_issues) else 0


if __name__ == "__main__":
    sys.exit(main())
