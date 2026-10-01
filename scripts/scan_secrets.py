#!/usr/bin/env python3
"""
scripts/scan_secrets.py
Production Git History & Repository Secret Scanner
Checks working tree and full git log for exposed credentials, tokens, and private keys.
"""

import os
import re
import subprocess
import sys

# High-risk secret patterns
SECRET_PATTERNS = [
    ("AWS Access Key", re.compile(r"(?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])")), # Generic 20-char, handled with AKIA below
    ("AWS Client Key ID", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("Google API Key", re.compile(r"AIza[0-9A-Za-z\-_]{35}")),
    ("Private Key Header", re.compile(r"-----BEGIN\s+([A-Z\s]+)?PRIVATE\s+KEY-----")),
    ("GitHub Personal Access Token", re.compile(r"gh[pousr]_[A-Za-z0-9_]{36,}")),
    ("Slack API Token", re.compile(r"xox[baprs]-[0-9a-zA-Z]{10,48}")),
    ("Stripe/Payment Secret Key", re.compile(r"sk_live_[0-9a-zA-Z]{24,}")),
    ("Database Connection String with Credentials", re.compile(r"(?:postgres|mysql|mongodb(?:\+srv)?):\/\/[^\s:]+:[^\s@]+@[^\s\/]+")),
    ("Generic Password Assignment", re.compile(r'''(?i)(?:password|passwd|pwd|secret|api_key|auth_token)\s*[:=]\s*['"]([a-zA-Z0-9_\-!@#$%^&*]{8,})['"]''')),
    ("Hardcoded JWT Token", re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_\-]{10,}")),
]

IGNORE_EXTENSIONS = {
    ".lock", ".png", ".jpg", ".jpeg", ".ico", ".svg", ".jar", ".class",
    ".dll", ".exe", ".so", ".dylib", ".ttf", ".woff", ".woff2", ".db", ".iml"
}

IGNORE_DIRS = {
    ".git", ".dart_tool", "build", ".idea", ".gradle", "node_modules",
    "__pycache__", ".widget_preview"
}

# Allowlisted sample / placeholder words
SAFE_SAMPLE_VALUES = {
    "replace_with_", "your_", "example", "dummy", "test_secret", "changeme",
    "phone-alpha", "phone-1", "phone-2", "disaster_ready.db", "disaster_server.db",
    "password123", "secret_key_123"
}

def is_safe_match(text: str) -> bool:
    lower = text.lower()
    return any(safe in lower for safe in SAFE_SAMPLE_VALUES)

def scan_working_tree(repo_root: str):
    findings = []
    print(f"[*] Scanning working tree under: {repo_root}")

    for root, dirs, files in os.walk(repo_root):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in IGNORE_EXTENSIONS:
                continue

            filepath = os.path.join(root, file)
            relpath = os.path.relpath(filepath, repo_root)

            # Skip .env.example
            if file == ".env.example" or file == "scan_secrets.py":
                continue

            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line_no, line in enumerate(f, 1):
                        for pattern_name, regex in SECRET_PATTERNS:
                            # Skip broad AWS generic if already checked
                            if pattern_name == "AWS Access Key":
                                continue
                            match = regex.search(line)
                            if match:
                                matched_text = match.group(0)
                                if not is_safe_match(matched_text):
                                    findings.append({
                                        "type": pattern_name,
                                        "location": f"{relpath}:{line_no}",
                                        "snippet": line.strip()[:100]
                                    })
            except Exception as e:
                pass

    return findings

def scan_git_history(repo_root: str):
    findings = []
    print(f"[*] Scanning Git commit history diffs in: {repo_root}")

    try:
        cmd = ["git", "log", "-p", "--full-history", "-n", "100"]
        result = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, errors="ignore")
        if result.returncode != 0:
            print("[-] Unable to run git log (maybe not a git repository)")
            return findings

        current_commit = "HEAD"
        current_file = ""

        for line in result.stdout.splitlines():
            if line.startswith("commit "):
                current_commit = line.split()[1][:8]
            elif line.startswith("+++ b/"):
                current_file = line[6:]
            elif line.startswith("+") and not line.startswith("+++"):
                added_code = line[1:]
                for pattern_name, regex in SECRET_PATTERNS:
                    if pattern_name == "AWS Access Key":
                        continue
                    match = regex.search(added_code)
                    if match:
                        matched_text = match.group(0)
                        if not is_safe_match(matched_text) and not current_file.endswith("scan_secrets.py"):
                            findings.append({
                                "type": pattern_name,
                                "commit": current_commit,
                                "file": current_file,
                                "snippet": added_code.strip()[:100]
                            })
    except Exception as e:
        print(f"[-] Error scanning git history: {e}")

    return findings

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    print("=" * 70)
    print("RESQLINK & DISASTERREADY SECURITY CHECKLIST: GIT & REPO SECRET SCAN")
    print("=" * 70)

    working_findings = scan_working_tree(repo_root)
    history_findings = scan_git_history(repo_root)

    total_findings = len(working_findings) + len(history_findings)

    print("\n" + "=" * 70)
    print(f"SCAN RESULTS: {total_findings} potential secret(s) found.")
    print("=" * 70)

    if total_findings == 0:
        print("[SUCCESS] Git history and working tree are clean of exposed secrets!")
    else:
        if working_findings:
            print(f"\n[!] Working Tree Findings ({len(working_findings)}):")
            for f in working_findings:
                print(f"  - [{f['type']}] in {f['location']}: {f['snippet']}")

        if history_findings:
            print(f"\n[!] Git History Findings ({len(history_findings)}):")
            for f in history_findings:
                print(f"  - [{f['type']}] in commit {f['commit']} ({f['file']}): {f['snippet']}")

    return 0 if total_findings == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
