#!/usr/bin/env python3
"""Daily QC Fact-Check Email Dispatcher for World of Warcraft: Forever.

Dispatches the daily 8:00 PM online fact-checking report in Markdown
and formatted HTML directly to the maintainer/QC reviewer.

Configuration:
  Set the following in `.env` or GitHub Secrets:
    QC_EMAIL_RECIPIENT=reviewer@example.com
    SMTP_HOST=smtp.mailserver.com
    SMTP_PORT=587
    SMTP_USER=user@example.com
    SMTP_PASSWORD=your_password

Usage:
  python3 scripts/email_daily_qc_report.py
  python3 scripts/email_daily_qc_report.py --recipient admin@domain.com
"""

import argparse
import html
import json
import os
import smtplib
import sys
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime, timezone

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORT_MD_PATH = os.path.join(REPO_ROOT, "tests", "reports", "DAILY_ONLINE_FACT_CHECK_REPORT.md")
REPORT_JSON_PATH = os.path.join(REPO_ROOT, "tests", "reports", "DAILY_ONLINE_FACT_CHECK_REPORT.json")
DRAFT_HTML_PATH = os.path.join(REPO_ROOT, "tests", "reports", "DAILY_QC_EMAIL_DRAFT.html")


def load_env_vars():
    """Lightweight loader for .env without external dependencies."""
    env_path = os.path.join(REPO_ROOT, ".env")
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k not in os.environ:
                    os.environ[k] = v


def generate_html_email(data: dict, md_content: str) -> str:
    """Generates a styled, readable HTML email for quick review on desktop & mobile."""
    timestamp = data.get("timestamp", "Recent")
    pass_rate = data.get("pass_rate", 100.0)
    total_checks = data.get("total_checks", 0)
    passed = data.get("passed", 0)
    failed = data.get("failed", 0)
    records = data.get("records", [])

    badge_color = "#10b981" if failed == 0 else "#ef4444"
    status_text = "ALL CHECKS VERIFIED" if failed == 0 else f"{failed} DISCREPANCIES FLAGGED"

    rows_html = []
    for r in records:
        is_pass = r.get("matched", False)
        status_badge = '<span style="color: #10b981; font-weight: bold;">✅ PASS</span>' if is_pass else '<span style="color: #ef4444; font-weight: bold;">❌ FAIL</span>'
        
        online_source = r.get("online_source", "Web API")
        online_name = r.get("online_name", "N/A")
        
        # Link generation
        obj_type = r.get("type", "").lower()
        obj_id = r.get("id")
        link = f"https://www.wowhead.com/classic/{'item' if 'item' in obj_type else 'npc' if 'creature' in obj_type else 'quest'}={obj_id}"
        
        row = f"""
        <tr style="border-bottom: 1px solid #334155;">
            <td style="padding: 10px; font-size: 13px; color: #94a3b8;">{r.get('type')}</td>
            <td style="padding: 10px; font-size: 13px; font-family: monospace; color: #cbd5e1;">#{r.get('id')}</td>
            <td style="padding: 10px; font-size: 14px; font-weight: bold; color: #ffffff;">{html.escape(str(r.get('name')))}</td>
            <td style="padding: 10px; font-size: 13px; color: #38bdf8;"><a href="{link}" style="color: #38bdf8; text-decoration: none;">{online_source}</a></td>
            <td style="padding: 10px; font-size: 13px; color: #e2e8f0;">{html.escape(str(online_name))}</td>
            <td style="padding: 10px; font-size: 12px; font-family: monospace; color: #94a3b8;">{r.get('latency_ms', 0)}ms</td>
            <td style="padding: 10px; font-size: 13px;">{status_badge}</td>
        </tr>
        """
        rows_html.append(row)

    html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0f172a; color: #f8fafc; margin: 0; padding: 20px; }}
  .container {{ max-width: 900px; margin: 0 auto; background: #1e293b; border-radius: 12px; overflow: hidden; border: 1px solid #334155; }}
  .header {{ background: linear-gradient(135deg, #1e293b, #0f172a); padding: 24px; border-bottom: 1px solid #334155; }}
  .header h1 {{ margin: 0; font-size: 22px; color: #f8fafc; display: flex; align-items: center; gap: 8px; }}
  .header p {{ margin: 6px 0 0; color: #94a3b8; font-size: 14px; }}
  .metric-card {{ display: inline-block; background: #0f172a; border: 1px solid #334155; border-radius: 8px; padding: 12px 18px; margin: 12px 8px 12px 0; }}
  .metric-val {{ font-size: 20px; font-weight: bold; color: #ffffff; }}
  .metric-lbl {{ font-size: 12px; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.5px; }}
  table {{ width: 100%; border-collapse: collapse; margin-top: 10px; text-align: left; }}
  th {{ background: #0f172a; padding: 12px 10px; font-size: 12px; text-transform: uppercase; color: #94a3b8; letter-spacing: 0.5px; border-bottom: 2px solid #334155; }}
  .footer {{ background: #0f172a; padding: 16px 24px; font-size: 12px; color: #64748b; border-top: 1px solid #334155; }}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>🛡️ Foreverbot Daily QC Fact-Check Report</h1>
    <p>Automated 8:00 PM Daily Live Cross-Verification against Wowhead Classic, ClassicDB & Blizzard Forums</p>
    <div style="margin-top: 14px;">
      <div class="metric-card">
        <div class="metric-val" style="color: {badge_color};">{pass_rate:.1f}%</div>
        <div class="metric-lbl">Pass Rate</div>
      </div>
      <div class="metric-card">
        <div class="metric-val">{passed} / {total_checks}</div>
        <div class="metric-lbl">Verified Live</div>
      </div>
      <div class="metric-card">
        <div class="metric-val" style="color: {badge_color};">{status_text}</div>
        <div class="metric-lbl">QC Status</div>
      </div>
    </div>
  </div>

  <div style="padding: 20px;">
    <h3 style="margin-top: 0; color: #f1f5f9; font-size: 16px;">Live Query vs External Web Verification Log ({timestamp})</h3>
    <p style="font-size: 13px; color: #94a3b8;">Below is your curated sample of random item, boss, and quest queries executed against the database and cross-checked against live online APIs. Click any source link for direct reference.</p>
    <table>
      <thead>
        <tr>
          <th>Type</th>
          <th>ID</th>
          <th>Query Output Name</th>
          <th>Online Source</th>
          <th>Online Name</th>
          <th>Latency</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        {''.join(rows_html)}
      </tbody>
    </table>
  </div>

  <div class="footer">
    Sent automatically by Foreverbot Daily QC Pipeline at 8:00 PM Daily. View repository at <a href="https://github.com/ForeverbotDev/Foreverbot" style="color: #38bdf8;">github.com/ForeverbotDev/Foreverbot</a>.
  </div>
</div>
</body>
</html>
"""
    return html_content


def dispatch_daily_qc_email(recipient: Optional[str] = None) -> bool:
    """Reads the latest report and sends the QC email."""
    load_env_vars()

    to_email = recipient or os.getenv("QC_EMAIL_RECIPIENT")
    smtp_host = os.getenv("SMTP_HOST", "")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASSWORD")

    if not os.path.exists(REPORT_MD_PATH):
        print(f"❌ Error: Report file not found at {REPORT_MD_PATH}")
        return False

    with open(REPORT_MD_PATH, "r", encoding="utf-8") as f:
        md_content = f.read()

    data = {}
    if os.path.exists(REPORT_JSON_PATH):
        try:
            with open(REPORT_JSON_PATH, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            pass

    pass_rate = data.get("pass_rate", 100.0)
    failed = data.get("failed", 0)
    now_str = datetime.now(timezone.utc).strftime("%b %d, %Y")

    status_tag = "100% VERIFIED" if failed == 0 else f"{failed} DISCREPANCIES"
    subject = f"🛡️ Foreverbot Daily QC Report ({now_str}) — {status_tag} ({pass_rate:.1f}%)"

    html_body = generate_html_email(data, md_content)

    # Always write HTML draft to disk
    with open(DRAFT_HTML_PATH, "w", encoding="utf-8") as f:
        f.write(html_body)
    print(f"📄 Saved HTML preview draft to: {os.path.relpath(DRAFT_HTML_PATH, REPO_ROOT)}")

    # Check if SMTP credentials are provided
    if not to_email or not smtp_user or not smtp_pass:
        print("\n" + "=" * 70)
        print("ℹ️  DAILY QC EMAIL NOTIFICATION CONFIGURATION")
        print("=" * 70)
        print("The email report has been formatted and generated successfully.")
        print("To receive this automatically in your inbox each day at 8:00 PM:")
        print("1. Add these keys to your `.env` file (or GitHub Repository Secrets):")
        print("   QC_EMAIL_RECIPIENT=your_email@example.com")
        print("   SMTP_HOST=smtp.gmail.com")
        print("   SMTP_PORT=587")
        print("   SMTP_USER=your_email@gmail.com")
        print("   SMTP_PASSWORD=your_app_password  # Gmail App Password (16 characters)")
        print(f"\nSubject: {subject}")
        print(f"Recipient: {to_email or '(Not set - provide in .env or via --recipient)'}")
        print("=" * 70 + "\n")
        return True

    # Build MIME Message
    msg = MIMEMultipart("mixed")
    msg["Subject"] = subject
    msg["From"] = smtp_user
    msg["To"] = to_email
    msg["Date"] = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")

    # Alternative body (plain markdown for markdown readers, HTML for rich email clients)
    alt_part = MIMEMultipart("alternative")
    part_text = MIMEText(md_content, "plain", "utf-8")
    part_html = MIMEText(html_body, "html", "utf-8")
    alt_part.attach(part_text)
    alt_part.attach(part_html)
    msg.attach(alt_part)

    # Attach raw Markdown file
    part_file = MIMEApplication(md_content.encode("utf-8"), Name="DAILY_ONLINE_FACT_CHECK_REPORT.md")
    part_file["Content-Disposition"] = 'attachment; filename="DAILY_ONLINE_FACT_CHECK_REPORT.md"'
    msg.attach(part_file)

    # Send via SMTP
    try:
        print(f"📧 Connecting to SMTP server {smtp_host}:{smtp_port}...")
        server = smtplib.SMTP(smtp_host, smtp_port, timeout=15)
        server.ehlo()
        if smtp_port in [587, 25]:
            server.starttls()
            server.ehlo()
        server.login(smtp_user, smtp_pass)
        server.send_message(msg)
        server.quit()
        print(f"✅ Daily QC Fact-Check report successfully emailed to: {to_email}")
        return True
    except Exception as e:
        print(f"❌ Failed to dispatch email via SMTP: {e}")
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Daily QC Fact-Check Email Dispatcher")
    parser.add_argument("--recipient", type=str, help="Recipient email address")
    args = parser.parse_args()

    success = dispatch_daily_qc_email(recipient=args.recipient)
    sys.exit(0 if success else 1)
