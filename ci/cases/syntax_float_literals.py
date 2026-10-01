# 职责: .5 与 1. 点省略浮点字面量各位置
# 比对: same_output

# 点省略浮点字面量 (.5 与 1., P1-58)
print(.5, 1., 1.e5, .5e2, .25, 5.)
print(.5 + .5, 1. * 2, .5 * 4)
print(.0, 0., .1 + .2)
x = .75
print(x, x * 2)
print([.5, 1.5, 1.], (.5, 1.), {"k": .5})
print(int(1.), float(.5), str(1.))
print(.5 == 0.5, 1. == 1.0, .5e2 == 50.0)
print(divmod(5., 2.), abs(-.5), round(.5))


def half(v):
    return v / 2


print(half(1), half(.5))
print("%.2f %.1f" % (.125, 1.))
print("{:.3f}".format(.5))
print(f"{1.}")
