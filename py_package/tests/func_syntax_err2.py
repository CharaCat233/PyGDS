# Function: SyntaxError — 关键字参数后接位置参数

def f1(a, b, /, c, d=0, *args, e, f=1, **kwargs):
    print(a, b, c, d, e, f, args, kwargs)


try:
    f1(1, 2, 3, 4, e=5, f=6, 7)
except Exception as e:
    print(type(e), e)
