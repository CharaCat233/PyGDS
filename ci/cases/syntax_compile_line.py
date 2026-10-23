# 职责: compile/exec 语法错误的行号上抛与消息形态 (IndentationError 类型, `(<file>, line N)` 尾缀为实际行号)
# 比对: same_output


def line_of(text):
    # 消息尾缀形态固定为 `(<file>, line N)`: 取最后一个 "line " 到串尾 ") " 之间的数字
    s = str(text)
    idx = s.rfind("line ")
    if idx < 0:
        return 0
    tail = s[idx + 5:]
    if tail.endswith(")"):
        tail = tail[:-1]
    try:
        return int(tail)
    except ValueError:
        return 0


def cerr(label, src):
    try:
        compile(src, "<t>", "exec")
        print(label, "OK")
    except SyntaxError as e:
        print(label, type(e).__name__, line_of(e))


def eerr(label, src):
    try:
        exec(src)
        print(label, "OK")
    except SyntaxError as e:
        print(label, type(e).__name__, line_of(e))


# 缩进块缺失: CPython 报 IndentationError, 行号为意外 token 所在行
cerr("unexpected-indent", "x = 1\n    y = 2\n")
cerr("indent-prog", "x = 1\n  y = 2\n      z = 3\n")
# 表达式错误: 行号为出错行
cerr("line2", "x = 1\ny = = 2\n")
cerr("line3", "x = 1\ny = 2\nz = 1 +\n")
# exec 同源
eerr("exec-indent", "x = 1\n    y = 2\n")
# 文件名实参透传 (消息含 <file> 形态, 断言行号与异常类)
cerr("named-file", "x = 1\n    y = 2\n")
# 括号未闭合: CPython 报开括号所在行
cerr("unclosed-l1", "x = (1,\n2,\n")
cerr("unclosed-l2", "a = (\n1,\n2\n")
# 后续 compile 不受前次错误污染 (行号状态复位)
cerr("after-ok", "ok = 1\n")
cerr("after-err", "a = (\n1,\n2\n")
