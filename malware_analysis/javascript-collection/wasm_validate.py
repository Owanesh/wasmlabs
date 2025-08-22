#!/usr/bin/env python3
import subprocess
import sys
import os
from collections import defaultdict

def main(directory):
    # Dictionaries for errors and successes
    errors = defaultdict(list)
    ok_files = []

    # Find all .wasm files
    for root, _, files in os.walk(directory):
        for f in files:
            if f.endswith(".wasm"):
                path = os.path.join(root, f)
                try:
                    result = subprocess.run(
                        ["wasm-validate", path],
                        capture_output=True,
                        text=True
                    )
                    if result.returncode == 0:
                        ok_files.append(path)
                    else:
                        # Normalize the error (remove trailing spaces)
                        err_msg = (result.stderr.strip() or "Unknown error")
                        errors[err_msg].append(path)
                except FileNotFoundError:
                    print("Error: 'wasm-validate' not found. Please install it first.")
                    return

    # Write the report
    report_file = "wasm_validate_report.txt"
    with open(report_file, "w", encoding="utf-8") as out:
        out.write("=== WASM Validation Report ===\n\n")

        for err, files in errors.items():
            out.write(f"[ERROR] {err}\n")
            for f in files:
                out.write(f"  - {f}\n")
            out.write(f"  Total: {len(files)}\n\n")

        out.write(f"[OK] {len(ok_files)} valid files\n")
        for f in ok_files:
            out.write(f"  - {f}\n")

    print(f"Report completed: {report_file}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <folder>")
        sys.exit(1)
    main(sys.argv[1])

