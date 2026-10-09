# 职责: logging 模块 info/warn/warning/error 调用与裸名移除
# 比对: same_output
import logging

print(callable(logging.info), callable(logging.warn), callable(logging.warning), callable(logging.error))
print(logging.info("info message") is None)
print(logging.warn("warn message") is None)
print(logging.warning("warning message") is None)
print(logging.error("error message") is None)

from logging import info as li, error as le
print(callable(li), callable(le))

for name, fn in [("info", lambda: info("x")), ("warn", lambda: warn("x")), ("warning", lambda: warning("x")), ("error", lambda: error("x"))]:
    try:
        fn()
        print("bare name still callable:", name)
    except NameError:
        print("bare name removed:", name)
