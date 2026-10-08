# 职责: type() 三参错误文案对齐 type.__new__() (I2-69)
# 比对: same_output

# type(name, bases, dict) 三参形态的参数类型错误文案为 type.__new__() 前缀 (CPython 同)

def t(label, fn):
    try:
        print(label + ":", fn())
    except Exception as e:
        print(label, type(e).__name__, ":", e)


t("arg3-not-dict", lambda: type("Bad", (), 5))
t("arg2-not-tuple", lambda: type("Bad", 5, {}))
t("arg1-not-str", lambda: type(5, (), {}))


# 合法三参构造不受影响
def ok_case():
    C = type("Dyn", (), {"x": 1})
    return (C.__name__, C().x)


t("ok", ok_case)
