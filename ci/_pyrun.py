"""
CPython 执行垫片: 运行单个用例文件, 把结果以 JSON 写入指定文件

由 ci/run_cases.gd 通过 OS.execute() 调用:

    python _pyrun.py <用例文件> <结果JSON路径> [工作目录]

设计约束:

- 结果经文件传递而非 stdout 捕获, 规避 OS.execute 的输出切分与平台编码差异
- 结果 JSON 以 ensure_ascii=True 写出, 文件内容为纯 ASCII
- 子进程强制 UTF-8 (PYTHONUTF8=1), 与 Godot String 的 UTF-8 语义对齐
- 工作目录给定时装载为子进程 cwd: 文件类用例的裸相对路径由此与
  PyGDS 盘符沙箱收敛到同一物理目录
- 本垫片只执行不判定, 判定逻辑全部在 run_cases.gd
"""

import json
import os
import subprocess
import sys

# Windows: 派生自无控制台的 Godot 进程链, 子进程会新建可见控制台窗口, 显式抑制
CREATE_NO_WINDOW = 0x08000000 if os.name == "nt" else 0


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print("usage: _pyrun.py <case.py> <result.json> [work_dir]", file=sys.stderr)
        return 2

    case_path, result_path = sys.argv[1], sys.argv[2]
    work_dir = sys.argv[3] if len(sys.argv) == 4 else None
    env = dict(os.environ, PYTHONUTF8="1")

    try:
        proc = subprocess.run(
            [sys.executable, case_path],
            capture_output=True,
            check=False,  # 非零退出码是采集数据 (报错用例), 显式声明不抛
            timeout=15,
            env=env,
            cwd=work_dir,
            creationflags=CREATE_NO_WINDOW,
        )
        result = {
            "code": proc.returncode,
            "stdout": proc.stdout.decode("utf-8", errors="replace"),
            "stderr": proc.stderr.decode("utf-8", errors="replace"),
            "timeout": False,
        }
    except subprocess.TimeoutExpired:
        result = {"code": None, "stdout": "", "stderr": "", "timeout": True}

    with open(result_path, "w", encoding="ascii") as f:
        json.dump(result, f, ensure_ascii=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
