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
