def f(x):
    match x:
        case {"a": v, **_}:
            pass
