import subprocess
import json
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
TEST_DIR = SCRIPT_DIR / "tests"
OUTPUT_FILE = SCRIPT_DIR / "expected.json"

results = {}

for py_file in sorted(TEST_DIR.glob("*.py")):
    if py_file.name.startswith("_"):
        continue

    name = py_file.stem

    proc = subprocess.run(
        ["python", str(py_file)],
        capture_output=True,
        text=True,
        timeout=5,
    )
    expected = proc.stdout

    syntax_error_msg_ls = proc.stderr.strip().split("\n")
    if syntax_error_msg_ls:
        syntax_error_msg = syntax_error_msg_ls[-1]
        expected = syntax_error_msg + "\n" if syntax_error_msg else expected

    results[name] = {
        "source": py_file.read_text(encoding="utf-8"),
        "expected": expected,
    }

OUTPUT_FILE.write_text(json.dumps(results, indent=4, ensure_ascii=False), encoding="utf-8")
print(f"Generated {len(results)} test cases → {OUTPUT_FILE}")
