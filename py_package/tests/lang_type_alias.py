# type 别名绑定 TypeAliasType (alpha.5, P2-44 连带)
type Vector = list
print(Vector)
print(Vector.__value__)
def scale(v: Vector, k):
    return v[0] * k
x: Vector = 5
print(x, scale([3, 4], 2))
