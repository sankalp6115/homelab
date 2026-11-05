#!/usr/bin/env python3
import os
import shutil
import subprocess
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(os.environ.get("GITHUB_BACKUP_DIR", Path(__file__).resolve().parent))
load_dotenv(dotenv_path=BASE_DIR / ".env")

import requests

PAT = os.environ.get("GITHUB_PAT")
if not PAT:
    print("Warning: GITHUB_PAT not set in environment or .env file.")

REPOS_DIR = BASE_DIR / "repos"
ARCHIVE_DIR = BASE_DIR / "archive"

def get_repos():
    repos = []
    page = 1
    headers = {"Authorization": f"token {PAT}"} if PAT else {}
    while True:
        url = f"https://api.github.com/user/repos?per_page=100&page={page}"
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            print("Failed to fetch repos:", response.status_code, response.text)
            break
        data = response.json()
        if not data:
            break
        repos.extend(data)
        page += 1
    return repos

def clone_or_fetch(repo):
    name = repo["name"]
    clone_url = repo["clone_url"]
    if PAT:
        clone_url = clone_url.replace("https://", f"https://{PAT}@")

    repo_dir = REPOS_DIR / name

    if repo_dir.exists():
        print(f"Fetching {name}...")
        subprocess.run(["git", "-C", str(repo_dir), "fetch", "--all", "--prune"], check=True)
    else:
        print(f"Cloning {name}...")
        subprocess.run(["git", "clone", "--mirror", clone_url, str(repo_dir)], check=True)

def archive_repo(repo_dir):
    name = repo_dir.name
    bundle_file = ARCHIVE_DIR / f"{name}.bundle"

    if bundle_file.exists():
        bundle_file.unlink()

    print(f"Archiving {name} to bundle...")
    subprocess.run(
        ["git", "-C", str(repo_dir), "bundle", "create", str(bundle_file), "--all"],
        check=True
    )

    target = ARCHIVE_DIR / name
    if target.exists():
        if target.is_dir():
            shutil.rmtree(target)
        else:
            target.unlink()
    shutil.move(str(repo_dir), str(target))

def main():
    if not PAT:
        print("Error: GITHUB_PAT is required to run backup.")
        return

    REPOS_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

    repos = get_repos()
    print(f"Found {len(repos)} repositories.")

    for repo in repos:
        local_name = repo["name"]
        try:
            clone_or_fetch(repo)
        except subprocess.CalledProcessError as e:
            print(f"Error fetching/cloning {local_name}: {e}")
            continue

        archive_repo(REPOS_DIR / local_name)

if __name__ == "__main__":
    main()
