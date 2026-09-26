# Lang: raise ... from 异常链 (__cause__ / __suppress_context__)

base = ValueError("root")
try:
    raise TypeError("top") from base
except TypeError as e:
    print("cause is base:", e.__cause__ is base)
    print("cause msg:", str(e.__cause__))
    print("suppress:", e.__suppress_context__)

try:
    raise KeyError("k") from None
except KeyError as e2:
    print("cause none:", e2.__cause__)
    print("suppress none:", e2.__suppress_context__)

try:
    raise OSError("plain")
except OSError as e3:
    print("plain cause:", e3.__cause__, e3.__suppress_context__)

try:
    raise ValueError("v") from 5
except TypeError as t:
    print("bad cause:", t)

try:
    raise TypeError("t1") from ValueError("v1")
except TypeError as e4:
    e4.__cause__ = None
    print("reassigned:", e4.__cause__, e4.__suppress_context__)


class MyErr(Exception):
    pass


src = Exception("b")
try:
    raise MyErr("m") from src
except MyErr as m:
    print("user cause is src:", m.__cause__ is src)

try:
    raise MyErr
except MyErr as mn:
    print("bare class args:", mn.args)

try:
    raise LookupError
except LookupError as lc:
    print("bare builtin:", str(lc))


def parse(v):
    if v == "":
        raise KeyError("empty") from None
    return v


try:
    parse("")
except KeyError as ke:
    print("from none inside func:", ke.__cause__, ke.__suppress_context__)

try:
    raise GeneratorExit()
except GeneratorExit:
    print("gexit raisable")
