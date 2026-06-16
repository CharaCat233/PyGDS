# Error: 异常类型不匹配传播

mismatch_caught = False
mismatch_outer = False
try:
    try:
        raise ValueError("mismatch")
    except TypeError:
        mismatch_caught = True
except:
    mismatch_outer = True
print(mismatch_caught, mismatch_outer)
