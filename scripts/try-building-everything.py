#!/usr/bin/env python3

from tqdm import tqdm
import json
from pathlib import Path
from subprocess import run

repo = Path(__file__).resolve().parent.parent

broken = []
try:
    with open(repo / "quicklisp/broken.txt") as f:
        for line in f:
            broken.append(line.strip())
except FileNotFoundError:
    pass

with open(repo / "quicklisp/dist-latest.json") as f:
    dist_info = json.load(f)
projects = dist_info["projects"]
total_count = len(projects)

with tqdm(
    total=total_count,
    bar_format=f"{{postfix[0]}}/{{postfix[1]}}/{total_count}",
    postfix=[0, 0, 0, []],
) as t:
    for project_name in tqdm(projects):
        if project_name in broken:
            t.postfix[2] += 1
            continue

        out = run(
            [
                "nix",
                "build",
                "--option",
                "warn-dirty",
                "false",
                f"{repo}#sbcl.packages.{project_name}",
            ]
        )
        if out.returncode == 0:
            t.postfix[0] += 1
        else:
            t.postfix[1] += 1
            t.postfix[3].append(project_name)
        t.update()

    good_count = t.postfix[0]
    fail_count = t.postfix[1]
    skip_count = t.postfix[2]
    failures = t.postfix[3]

with open(repo / "quicklisp/broken.txt", "w") as f:
    for skipped in broken:
        print(skipped, file=f)
    for failure in failures:
        print(failure, file=f)

print(f"Total: {total_count}")
print(f"NFail: {fail_count} ({100 * fail_count / total_count}%)")
print(f"NGood: {good_count} ({100 * good_count / total_count}%)")
print(f"NSkip: {skip_count} ({100 * skip_count / total_count}%)")
