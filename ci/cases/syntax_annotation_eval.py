# 职责: 变量与函数注解求值、注解字典与联合类型
# 比对: same_output

# 变量注解求值与 __annotations__ (alpha.5, P2-44)
x: int = 5
print(__annotations__)
y: "literal"
print(__annotations__["y"])
class C:
    a: int = 1
    b: str
print(C.__annotations__, hasattr(C, "a"), hasattr(C, "b"))
def f(a: int, b: str = "x") -> bool:
    return True
print(f.__annotations__)
def g():
    z: undefined_local = 1
    return z
print(g())
def add(x: int | float, y: int | float) -> int | float:
    return x + y
print(add(1, 2.5))
print(int | float)
u = int | str
print(isinstance(5, u), isinstance("a", u), isinstance(1.5, u))
print(issubclass(bool, int | str), u == int | str)
