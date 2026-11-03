#!/usr/bin/env python3
"""tests/test_security_audit_and_failsafes.py.

Unit test adapter for Coder Security Audit and Fail-Safes.
Runs as Suite 15 in CI to guarantee 100% security boundary compliance.
"""

import os
import sys
import unittest

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from scripts.security_audit_and_failsafes import (
    audit_phase_1_ast_static_analysis,
    audit_phase_2_database_immutability,
    audit_phase_3_database_integrity,
    audit_phase_4_secrets_and_pii_scanner,
    audit_phase_5_input_bounds_and_fuzz,
    audit_phase_6_circuit_breaker_and_env,
)


class TestSecurityAuditAndFailSafes(unittest.TestCase):
    """Verifies that all 6 security audit phases pass with zero defects."""

    def test_01_ast_static_security_analysis(self):
        passed, issues = audit_phase_1_ast_static_analysis()
        self.assertTrue(passed, f"AST Static Analysis failed: {issues}")

    def test_02_database_immutability(self):
        passed, issues = audit_phase_2_database_immutability()
        self.assertTrue(passed, f"Database Immutability check failed: {issues}")

    def test_03_database_integrity(self):
        passed, issues = audit_phase_3_database_integrity()
        self.assertTrue(passed, f"Database Integrity check failed: {issues}")

    def test_04_secrets_and_pii_scanner(self):
        passed, issues = audit_phase_4_secrets_and_pii_scanner()
        self.assertTrue(passed, f"Secrets & PII Scanner failed: {issues}")

    def test_05_input_bounds_and_fuzz(self):
        passed, issues = audit_phase_5_input_bounds_and_fuzz()
        self.assertTrue(passed, f"Input bounds & fuzz resistance failed: {issues}")

    def test_06_circuit_breaker_and_env(self):
        passed, issues = audit_phase_6_circuit_breaker_and_env()
        self.assertTrue(passed, f"Circuit Breaker & Env Fail-Safe check failed: {issues}")


if __name__ == "__main__":
    unittest.main()
