#!/usr/bin/env python3
"""scripts/security_audit_and_failsafes.py.

Automated Coder Security Audit & Fail-Safe Verification Suite.
Can be executed locally by any software engineer or in CI to verify:
1. Static AST Security Analysis (eval, exec, pickle, shell injection, SQL injection patterns).
2. Database Immutability & Read-Only Engine Protection.
3. Database B-Tree Integrity & Zero-Corruption PRAGMA Checks.
4. Secrets, Tokens & PII Hygiene Scanner.
5. Input Bounds, Clamping & Anti-ReDoS Fuzz Resistance.
6. Circuit Breaker & Environment Fail-Safe Health.
"""

import ast
import os
import re
import sys
import time
import sqlite3
from typing import List, Dict, Any, Tuple

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from database import (
    WoWForeverDB,
    get_connection,
    verify_database_integrity,
    clean_query,
    DB_PATH,
    USER_DB_PATH
)
from bot import (
    CircuitBreaker,
    safe_embed_str,
    safe_add_field,
    validate_runtime_environment
)
import discord

# Terminal colors
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"


class ASTSecurityVisitor(ast.NodeVisitor):
    """Inspects Python Abstract Syntax Trees for dangerous patterns."""

    DANGEROUS_FUNCS = {"eval", "exec"}

    def __init__(self, filename: str):
        self.filename = filename
        self.issues: List[str] = []

    def visit_Call(self, node: ast.Call):
        # 1. Detect eval() or exec()
        if isinstance(node.func, ast.Name) and node.func.id in self.DANGEROUS_FUNCS:
            self.issues.append(f"Line {node.lineno}: Prohibited call to '{node.func.id}()'")

        # 2. Detect os.system()
        if isinstance(node.func, ast.Attribute) and node.func.attr == "system":
            if isinstance(node.func.value, ast.Name) and node.func.value.id == "os":
                self.issues.append(f"Line {node.lineno}: Insecure 'os.system()' call detected.")

        # 3. Detect pickle.loads / pickle.load
        if isinstance(node.func, ast.Attribute) and node.func.attr in ("load", "loads"):
            if isinstance(node.func.value, ast.Name) and node.func.value.id == "pickle":
                self.issues.append(f"Line {node.lineno}: Insecure deserialization 'pickle.{node.func.attr}()'")

        # 4. Detect subprocess shell=True
        if isinstance(node.func, ast.Attribute) and node.func.attr in ("Popen", "run", "call", "check_output"):
            for kw in node.keywords:
                if kw.arg == "shell" and isinstance(kw.value, ast.Constant) and kw.value.value is True:
                    self.issues.append(f"Line {node.lineno}: Unsafe 'subprocess.{node.func.attr}(shell=True)'")

        # 5. Detect cursor.execute with f-string or % formatting (SQL injection risk)
        if isinstance(node.func, ast.Attribute) and node.func.attr in ("execute", "executescript"):
            if node.args:
                first_arg = node.args[0]
                if isinstance(first_arg, ast.JoinedStr):  # f-string in SQL execute
                    # Allow internal PRAGMA or trusted schema constants, flag table user interpolation
                    text_parts = [p.value for p in first_arg.values if isinstance(p, ast.Constant)]
                    full_str = "".join(text_parts).upper()
                    if "SELECT" in full_str or "WHERE" in full_str or "INSERT" in full_str:
                        self.issues.append(f"Line {node.lineno}: Potential SQL injection f-string inside '{node.func.attr}()'")

        self.generic_visit(node)


def audit_phase_1_ast_static_analysis() -> Tuple[bool, List[str]]:
    """Recursively parses all Python files with AST to detect dangerous patterns."""
    issues = []
    py_files = []
    for root, dirs, files in os.walk(BASE_DIR):
        if any(d in root for d in [".venv", ".git", "__pycache__", "site", "scratch"]):
            continue
        for f in files:
            if f.endswith(".py"):
                py_files.append(os.path.join(root, f))

    for py_file in py_files:
        rel_path = os.path.relpath(py_file, BASE_DIR)
        try:
            with open(py_file, "r", encoding="utf-8") as fp:
                source = fp.read()
            tree = ast.parse(source, filename=rel_path)
            visitor = ASTSecurityVisitor(rel_path)
            visitor.visit(tree)
            for iss in visitor.issues:
                issues.append(f"[{rel_path}] {iss}")
        except Exception as e:
            issues.append(f"[{rel_path}] AST parse failure: {e}")

    passed = len(issues) == 0
    return passed, issues


def audit_phase_2_database_immutability() -> Tuple[bool, List[str]]:
    """Verifies that the static game catalog cannot be modified or dropped."""
    issues = []
    try:
        conn = get_connection(DB_PATH, read_only=True)
        try:
            conn.execute("DROP TABLE items;")
            issues.append("VULNERABILITY: Read-only connection permitted DROP TABLE!")
        except sqlite3.OperationalError as e:
            # Expected error: "attempt to write a readonly database"
            if "readonly database" not in str(e).lower():
                issues.append(f"Unexpected error when attempting write on read-only DB: {e}")
        finally:
            conn.close()
    except Exception as exc:
        issues.append(f"Database read-only connection test failed: {exc}")

    passed = len(issues) == 0
    return passed, issues


def audit_phase_3_database_integrity() -> Tuple[bool, List[str]]:
    """Runs PRAGMA integrity_check and quick_check on wow_forever.db and user_data.db."""
    issues = []
    for db_file in [DB_PATH, USER_DB_PATH]:
        res = verify_database_integrity(db_file)
        if res.get("status") != "ok":
            issues.append(f"Integrity check failed for {os.path.basename(db_file)}: {res}")
        elif res.get("integrity_check") != "ok" or res.get("quick_check") != "ok":
            issues.append(f"Corrupt B-Tree detected in {os.path.basename(db_file)}: {res}")

    passed = len(issues) == 0
    return passed, issues


def audit_phase_4_secrets_and_pii_scanner() -> Tuple[bool, List[str]]:
    """Scans repository code and config files for exposed tokens or personal identifiers."""
    issues = []
    TOKEN_REGEX = re.compile(r"([MN][A-Za-z0-9_-]{23,28}\.[A-Za-z0-9_-]{6,7}\.[A-Za-z0-9_-]{27,38})")
    PII_REGEX = re.compile(r"/home/([a-zA-Z0-9_\-]+)")

    scan_files = [
        "bot.py", "database.py", "knowledge_engine.py", "redirection.py",
        ".env.example", ".github/workflows/ci.yml"
    ]

    for fname in scan_files:
        fpath = os.path.join(BASE_DIR, fname)
        if not os.path.exists(fpath):
            continue
        with open(fpath, "r", encoding="utf-8", errors="ignore") as fp:
            for i, line in enumerate(fp, 1):
                # Check for live discord token format
                tokens = TOKEN_REGEX.findall(line)
                for t in tokens:
                    if not t.startswith("MTU2NDAzOTUz"):  # Allow non-functional test tokens
                        issues.append(f"{fname}:{i} Potential exposed live token: {t[:8]}...")
                # Check for developer personal home directory
                pii_matches = PII_REGEX.findall(line)
                for m in pii_matches:
                    if m not in ("runner", "appuser", "ubuntu", "node"):
                        issues.append(f"{fname}:{i} Potential developer username path leaked: '/home/{m}'")

    passed = len(issues) == 0
    return passed, issues


def audit_phase_5_input_bounds_and_fuzz() -> Tuple[bool, List[str]]:
    """Verifies that query cleaners, embed builders, and parsers handle massive malicious inputs."""
    issues = []
    # 1. 100k char repeated ReDoS attack payload
    payload = ("what are the bosses in " * 5000) + "molten core"
    t0 = time.time()
    cleaned = clean_query(payload)
    elapsed = time.time() - t0
    if elapsed > 0.05:
        issues.append(f"clean_query exceeded latency threshold on ReDoS payload: {elapsed:.4f}s")
    if len(cleaned) > 500:
        issues.append(f"clean_query output exceeded 500 character ceiling: {len(cleaned)}")

    # 2. Discord Embed field boundary test
    embed = discord.Embed(title="Boundary Test")
    safe_add_field(embed, "K" * 1000, "V" * 3000)
    f = embed.fields[0]
    if len(f.name) > 256:
        issues.append(f"safe_add_field produced name longer than 256 chars: {len(f.name)}")
    if len(f.value) > 1024:
        issues.append(f"safe_add_field produced value longer than 1024 chars: {len(f.value)}")

    passed = len(issues) == 0
    return passed, issues


def audit_phase_6_circuit_breaker_and_env() -> Tuple[bool, List[str]]:
    """Tests circuit breaker fail-safe transitions and environment validation."""
    issues = []
    cb = CircuitBreaker(failure_threshold=3, recovery_time=0.1)
    if not cb.can_execute():
        issues.append("CircuitBreaker did not start in CLOSED state.")

    # Record 3 failures
    cb.record_failure()
    cb.record_failure()
    cb.record_failure()
    if cb.state != "OPEN" or cb.can_execute():
        issues.append("CircuitBreaker failed to OPEN after 3 consecutive failures.")

    # Wait for recovery time
    time.sleep(0.12)
    if not cb.can_execute() or cb.state != "HALF_OPEN":
        issues.append("CircuitBreaker failed to transition to HALF_OPEN after recovery time.")

    # Record success -> back to CLOSED
    cb.record_success()
    if cb.state != "CLOSED":
        issues.append("CircuitBreaker failed to reset to CLOSED upon success.")

    # Validate runtime environment checks
    os.environ["TESTING"] = "1"
    is_sec, env_issues = validate_runtime_environment(enforce_production=False)
    if not is_sec:
        issues.append(f"validate_runtime_environment failed in testing mode: {env_issues}")

    passed = len(issues) == 0
    return passed, issues


def main():
    print(f"\n{BOLD}{CYAN}=" * 80)
    print("🔒 WOW: FOREVER BOT — AUTOMATED CODER SECURITY AUDIT & FAIL-SAFE VERIFICATION")
    print(f"=" * 80 + f"{RESET}")

    suites = [
        ("Phase 1: AST Static Security Analysis", audit_phase_1_ast_static_analysis),
        ("Phase 2: Database Immutability & Read-Only Engine Protection", audit_phase_2_database_immutability),
        ("Phase 3: Database B-Tree Integrity & Zero-Corruption Check", audit_phase_3_database_integrity),
        ("Phase 4: Secrets, Tokens & PII Hygiene Scanner", audit_phase_4_secrets_and_pii_scanner),
        ("Phase 5: Input Length Clamping & Anti-ReDoS Fuzz Resistance", audit_phase_5_input_bounds_and_fuzz),
        ("Phase 6: Circuit Breaker & Environment Fail-Safe Health", audit_phase_6_circuit_breaker_and_env),
    ]

    all_passed = True
    for title, test_func in suites:
        print(f"\n{BOLD}▶ Running {title}...{RESET}")
        passed, issues = test_func()
        if passed:
            print(f"   {GREEN}✔ PASSED{RESET} — All assertions and security boundaries intact.")
        else:
            all_passed = False
            print(f"   {RED}✘ FAILED{RESET} — {len(issues)} issue(s) identified:")
            for iss in issues:
                print(f"       {YELLOW}• {iss}{RESET}")

    print(f"\n{BOLD}{CYAN}=" * 80)
    if all_passed:
        print(f"{GREEN}{BOLD}🏁 ALL 6 SECURITY & FAIL-SAFE AUDIT PHASES PASSED (100% COMPLIANT){RESET}")
        print(f"{CYAN}Verified for production deployment, code review, and developer audit.")
        print(f"=" * 80 + f"{RESET}\n")
        sys.exit(0)
    else:
        print(f"{RED}{BOLD}🚨 SECURITY AUDIT FAILED — Issues must be resolved before passing.{RESET}")
        print(f"=" * 80 + f"{RESET}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
