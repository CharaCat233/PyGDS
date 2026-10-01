# 职责: 未捕获异常的行号报告（帧内报错行）
# 比对: same_error
# 行号: same

# 行号比对声明「行号: same」: PyGDS 侧取错误消息的 "(line N)" 尾缀,
# CPython 侧取 traceback 末帧的 "File ..., line N"; 函数帧内报错行号必须逐位一致
def divide():
    return 1 / 0

divide()
