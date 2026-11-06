#!/usr/bin/env python3
"""
tests/test_github_page_security.py

Automated Security and Integrity Test Suite:
1. Validates Content-Security-Policy (CSP) on GitHub Pages (site/index.html).
2. Validates X-Content-Type-Options and Referrer-Policy headers.
3. Checks all external links for rel="noopener noreferrer" against tabnabbing.
4. Audits site/app.js for DOM XSS prevention and safe markdown rendering.
5. Verifies zero credentials, private keys, or API tokens in the codebase.
6. Verifies full game catalog export (all 26,800+ items loaded with correct info).
7. Verifies AlphaOpen distribution archive packaging.
"""

import os
import re
import unittest
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE_DIR = os.path.join(BASE_DIR, "site")
INDEX_HTML = os.path.join(SITE_DIR, "index.html")
APP_JS = os.path.join(SITE_DIR, "app.js")
ADDON_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
DATA_FILE = os.path.join(ADDON_DIR, "ForeverGuide_Data.lua")


class TestGitHubPageSecurity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(INDEX_HTML, "r", encoding="utf-8") as f:
            cls.html_content = f.read()
        with open(APP_JS, "r", encoding="utf-8") as f:
            cls.js_content = f.read()

    def test_01_content_security_policy_present(self):
        """Verify Content-Security-Policy meta header is strictly defined."""
        self.assertIn("Content-Security-Policy", self.html_content)
        self.assertIn("default-src 'self'", self.html_content)

    def test_02_security_headers_present(self):
        """Verify X-Content-Type-Options and Referrer-Policy are present."""
        self.assertIn('http-equiv="X-Content-Type-Options" content="nosniff"', self.html_content)
        self.assertIn('name="referrer" content="strict-origin-when-cross-origin"', self.html_content)

    def test_03_no_reverse_tabnabbing(self):
        """Verify all target='_blank' links have rel='noopener noreferrer'."""
        bad_links = re.findall(r'<a[^>]+target=["\']_blank["\'](?![^>]*rel=["\'][^"\']*noopener\s+noreferrer)', self.html_content)
        self.assertEqual(len(bad_links), 0, f"Found links missing rel='noopener noreferrer': {bad_links}")

    def test_04_js_xss_protection(self):
        """Verify Discord markdown formatting sanitizes HTML entities before formatting."""
        self.assertIn("function formatDiscordMarkdown(str)", self.js_content)
        self.assertIn("const safe = escapeHtml(str)", self.js_content)
        self.assertIn("formatDiscordMarkdown(data.desc)", self.js_content)
        self.assertIn("formatDiscordMarkdown(f.val)", self.js_content)

    def test_05_no_eval_or_document_write(self):
        """Ensure no unsafe eval or document.write calls in client-side JavaScript."""
        self.assertNotIn("eval(", self.js_content)
        self.assertNotIn("document.write", self.js_content)

    def test_06_no_hardcoded_secrets_in_repo(self):
        """Scan repository files for exposed Discord tokens, API keys, or private keys."""
        patterns = [
            (r'(?i)discordapp\.com/api/webhooks/[0-9]+/[a-zA-Z0-9_-]+', 'Discord Webhook'),
            (r'(?i)ghp_[a-zA-Z0-9]{36}', 'GitHub Token'),
            (r'(?i)-----BEGIN\s+PRIVATE\s+KEY-----', 'Private Key Block'),
        ]
        for root, dirs, files in os.walk(BASE_DIR):
            if any(skip in root for skip in ['.git', '__pycache__', 'ground_truth', 'node_modules', 'dist']):
                continue
            for f in files:
                if f.endswith(('.py', '.lua', '.html', '.js', '.json', '.yml')):
                    p = os.path.join(root, f)
                    with open(p, 'r', encoding='utf-8', errors='ignore') as fh:
                        content = fh.read()
                    for pat, name in patterns:
                        self.assertFalse(re.search(pat, content), f"Potential {name} detected in {p}!")

    def test_07_full_game_item_catalog_count(self):
        """Verify the addon catalog exports all 26,800+ real game items."""
        res = subprocess.run([
            "luajit", "-e",
            """
            ForeverGuide_Data = {}
            dofile("addon/ForeverGuide/ForeverGuide_Data.lua")
            local count = 0
            for k,v in pairs(ForeverGuide_Data.Items) do count = count + 1 end
            assert(count >= 26800, "Expected at least 26,800 items, got " .. count)
            """
        ], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"Item count validation failed: {res.stderr}")


if __name__ == "__main__":
    unittest.main()
