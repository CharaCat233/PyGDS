# 职责: importlib 的 import_module 与 invalidate_caches
# 比对: same_output

import importlib
import sys

print(importlib.import_module("math") is sys.modules["math"])
print(importlib.import_module("collections.abc").__name__)
print(importlib.invalidate_caches())
try:
    importlib.import_module("")
except ValueError as e:
    print("VE", e)
try:
    importlib.import_module("no_such_mod_xyz")
except ModuleNotFoundError as e:
    print(type(e).__name__, e.name, e)
try:
    importlib.import_module(5)
except Exception as e:
    print(type(e).__name__, e)
