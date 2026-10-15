# duty: json 模块序列化与反序列化 (dumps/loads, 缩进/排序/分隔符/ensure_ascii, JSONDecodeError)
# 比对: same_output
import json


def show(label, fn):
    try:
        print(label, "OK", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__)


d = {"a": 1, "b": [1, 2.5, "x", True, None], "c": {"n": 3}}
print("jd", json.dumps(d))
print("jd2", json.dumps(d, indent=2))
print("jd3", json.dumps(d, sort_keys=True))
print("jd4", json.dumps(d, separators=(",", ":")))
print("jd5", json.dumps("héllo"))
print("jd6", json.dumps("héllo", ensure_ascii=False))
print("jd7", json.dumps([1, 2.0, "s", None, True]))
print("jd8", json.dumps(10**40))
print("jdc", json.dumps({"k": 1}, sort_keys=True, indent=4))
print("jdintkey", json.dumps({1: 2}))
s = '{"a": 1, "b": [true, null, 2.5, "x"], "c": {"d": 3}}'
print("jl", json.loads(s))
print("jl2", json.loads('[1, 2.5, "x", true, null]'))
print("jl3", json.loads('{"a\\u00e9": 1}'))
print("jl4", json.loads("42"))
print("jl5", json.loads("-3.5e2"))
print("jl6", json.loads('"\\n\\t\\u0041"'))
print("jl7", json.loads("  [1, 2]  "))
show("jerr", lambda: json.loads('{"a": }'))
show("jerr2", lambda: json.loads("[1, 2"))
show("jerr3", lambda: json.loads("hello"))
show("jerr4", lambda: json.loads("01"))
show("jdump nonjson", lambda: json.dumps({1: 2}))
print("isExc", issubclass(json.JSONDecodeError, ValueError))

# allow_nan=False 报 ValueError; bool 键序列化为 true/false; default= 钩子支持不可序列化对象
try:
    print(json.dumps(float("nan"), allow_nan=False))
except ValueError as e:
    print("VE:", e)
try:
    print(json.dumps(float("inf"), allow_nan=False))
except ValueError as e:
    print("VE2:", e)
print(json.dumps(float("nan")))
print(json.dumps({True: 1}))
print(json.dumps({False: 0}))
print(json.dumps({True: 1, 1: 2}))
print(json.dumps({1, 2}, default=list))


def j88_default(o):
    return {"custom": sorted(o)}


print(json.dumps({3, 1}, default=j88_default))

# 合法代理对转义 / json.loads("-") / sort_keys 跨型 TypeError / indent+separators 元素分隔符
print(json.dumps("\U0001f600"))
print(json.dumps("\U0001f600", ensure_ascii=False))
try:
    print(json.loads("-"))
except Exception as e:
    print(type(e).__name__, e)
try:
    print(json.loads("."))
except Exception as e:
    print(type(e).__name__, e)
try:
    print(json.dumps({1: "a", "b": 2}, sort_keys=True))
except TypeError as e:
    print("TE:", e)
print(json.dumps({"b": 1, "a": 2}, sort_keys=True))
print(repr(json.dumps([1, 2], indent=2, separators=(";", ": "))))
print(repr(json.dumps({"a": 1, "b": [2, 3]}, indent=2, separators=(";", ": "))))
print(json.dumps({1.0: "a"}))


# NaN/Infinity 字面量默认接受; "01" 前导零报错位置对齐
print(json.loads("NaN"))
print(json.loads("Infinity"))
print(json.loads("-Infinity"))
try:
    json.loads("01")
except Exception as e:
    print(type(e).__name__, str(e))
try:
    json.loads("[01]")
except Exception as e:
    print(type(e).__name__, str(e))
try:
    json.loads("nan")
except Exception as e:
    print(type(e).__name__, str(e))
print(json.loads("0.5"))

# json.loads BOM 文案
try:
    json.loads('\ufeff{"a": 1}')
except json.JSONDecodeError as e:
    print("BOM:", str(e)[:45])
print(json.dumps(float("nan")))


# json.loads 接受 bytes (UTF-8 解码)
try:
    json.loads(123)
except Exception as e:
    print("jb-err:", type(e).__name__, str(e))
except Exception as e:
    print("jb-err:", type(e).__name__)


# json.loads 遇 UTF-8 BOM 报 CPython 文案 (提示用 utf-8-sig 解码)
try:
    json.loads("\ufeff{}")
except Exception as e:
    print("jb-bom:", type(e).__name__, str(e))
print("jb-ok:", json.loads('{"a":1}'))
