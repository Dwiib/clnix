#!/usr/bin/env python3

import hashlib
import requests
from tqdm import tqdm
import json
import os
from pathlib import Path


repo = Path(__file__).resolve().parent.parent


def get_lines(url):
    req = requests.get(url)
    req.raise_for_status()
    for line in req.text.split("\n"):
        line = line.split("#", 1)[0].strip()
        if line == "":
            continue
        yield line


def get_distinfo():
    return {
        k: v
        for k, v in (
            line.split(": ", 1)
            for line in get_lines("http://beta.quicklisp.org/dist/quicklisp.txt")
        )
    }


def get_system_info(distinfo, projects):
    system_info = {}
    for line in get_lines(distinfo["system-index-url"]):
        project, system_file_basename, system_name, *deps = line.split()
        projects[project]["system-deps"][system_name] = deps

        if system_name not in system_info:
            system_info[system_name] = []
        system_info[system_name].append(
            {
                "project": project,
                "system-file-basename": system_file_basename,
            }
        )
    return system_info


def save_distinfo():
    distinfo = get_distinfo()
    projects = {
        project: {
            "url": url,
            "size": int(size),
            "md5": md5,
            "content-sha1": content_sha1,
            "prefix": prefix,
            "asd-files": asd_files,
            "system-deps": {},
        }
        for project, url, size, md5, content_sha1, prefix, *asd_files in (
            line.split() for line in get_lines(distinfo["release-index-url"])
        )
    }
    systems = get_system_info(distinfo, projects)

    out_basename = f"dist-{distinfo['version']}.json"
    with open(repo / "quicklisp" / out_basename, "w") as out:
        json.dump({"projects": projects, "systems": systems}, out)

    latest_path = repo / "quicklisp/dist-latest.json"
    os.unlink(latest_path)
    os.symlink(out_basename, latest_path)


def update_hashes():
    with open(repo / "quicklisp/hashes.json") as f:
        hashes = json.load(f)

    unsaved_count = 0

    for dep_path in tqdm(repo.glob("quicklisp/dist-*.json")):
        with open(dep_path) as f:
            dist_info = json.load(f)

        for project_name, project in tqdm(dist_info["projects"].items()):
            url = project["url"]
            md5 = project["md5"]

            if md5 in hashes:
                continue

            req = requests.get(url)
            req.raise_for_status()

            if md5 != hashlib.md5(req.content).hexdigest():
                print(f"md5 mismatch for {project_name} ({url})")
                exit(1)

            hashes[md5] = hashlib.sha256(req.content).hexdigest()

            unsaved_count += 1
            if unsaved_count > 10:
                with open(repo / "quicklisp/hashes.json", "w") as f:
                    json.dump(hashes, f)

    with open(repo / "quicklisp/hashes.json", "w") as f:
        json.dump(hashes, f)


save_distinfo()
update_hashes()
