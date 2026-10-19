# duty: sys 模块基础面(maxsize/version_info/byteorder/platform/intern/exit)
# 比对: same_output
import sys
import math as _m
import string as _s

print(sys.maxsize == 9223372036854775807)
print(sys.version_info[:2] >= (3, 12))
print(sys.byteorder)
print(sys.platform in ("win32", "linux", "darwin"))
print(isinstance(sys.argv, list))
print(sys.version_info[0], sys.version_info[1] >= 12)
s = sys.intern("a" + "bc")
print(s == "abc")
try:
    sys.intern(1)
except TypeError as e:
    print("TE:", e)
try:
    sys.exit(3)
except SystemExit as e:
    print("SE:", e.args)
try:
    sys.exit("bye")
except SystemExit as e:
    print("SE2:", e.args, isinstance(e, BaseException))


# sys.modules 视图与模块缓存同步 (get is 同一对象, del 可驱逐)
print(sys.modules.get("math") is _m)
print("string" in sys.modules)
del sys.modules["string"]
print("string" in sys.modules)

# keys/values/items/len 与模块缓存同步 (活视图先同步再读 backing store)
import json

print("json" in sys.modules.keys())
print("json" in list(sys.modules.keys()))
print("sys" in sys.modules.keys())
print(len(sys.modules) > 5)
print(len(sys.modules.keys()) > 5)
print(len(list(sys.modules.items())) > 5)
print(sys.modules["json"] is json)
print(_m in sys.modules.values())
print(len(sys.modules.values()) > 5)
ks = sys.modules.keys()

import random
print("random" in ks)
print("random" in sys.modules.keys())

# sys.exc_info (活动异常时返回 (type, value, traceback))
import sys

print("exc0:", sys.exc_info())
try:
    1 / 0
except ZeroDivisionError:
    t, v, tb = sys.exc_info()
    print("exc1:", t.__name__)
    print("exc2:", isinstance(v, ZeroDivisionError))
