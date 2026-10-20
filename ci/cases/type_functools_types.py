# I2-43 case: functools.cache / lru_cache type identity (addresses differ per-end, prefix checks)
# 职责: functools.cache/lru_cache 工厂类型身份与包装对象类型 (type 'function' / _lru_cache_wrapper)
# 比对: same_output

import functools

print(type(functools.cache).__name__)
print(type(functools.lru_cache).__name__)


@functools.cache
def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)


print(type(fib).__name__)
print(fib.__name__)
print(repr(functools.cache).startswith("<function cache at 0x"))
print(repr(fib).startswith("<functools._lru_cache_wrapper object"))
print(str(fib) == repr(fib))
print(type(functools.cache).__name__ == "function")
c = functools.lru_cache(maxsize=8)(lambda x: x * 2)
print(type(c).__name__)
print(c.__name__)
print(c(3), c(3))
print(functools.cache is functools.lru_cache)
print(hasattr(fib, "cache_clear"), hasattr(fib, "cache_info"))
print(fib(10), fib(10))
