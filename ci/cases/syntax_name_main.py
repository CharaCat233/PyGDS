# 职责: __name__/__file__ 与主守卫
# 比对: same_output


print(__name__)
print(__name__ == "__main__")

if __name__ == "__main__":
    print("main guard entered")

print(type(__name__))
print(isinstance(__file__, str))


def where():
    return __name__


print(where())


class WithName:
    def get(self):
        return __name__


print(WithName().get())

__name__ = "custom"
print(__name__)
print(where())
