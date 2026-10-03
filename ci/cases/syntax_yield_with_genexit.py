# 职责: with 抑制 GeneratorExit 后生成器再次 yield 报 ignored (CPython 同文案)
# 比对: same_error


class CM:
    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        return True


def gen():
    with CM():
        try:
            yield 1
        except GeneratorExit:
            pass
    yield 2


g = gen()
next(g)
g.close()
