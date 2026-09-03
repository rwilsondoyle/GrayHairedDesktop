#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-stage23a-v10"

fail() {
    printf '[GRAYHAIRED-SITE23A] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE23A] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"

if grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10' "$GRID"; then
    pass "Stage 23A v10 is already installed"
    exit 0
fi

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V3' "$GRID" || \
    fail "This direct upgrade expects the physically installed Stage 23A v3 tree"

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

# Upgrade only the physically observed Stage 23A v3 block. Do not assume any
# exact indentation or comment spacing: later patch layers can shift whitespace.
marker = 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V3'
if marker not in text:
    raise SystemExit('Stage 23A v3 marker not found')
text = text.replace(marker, 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10', 1)

# Add retry state immediately before the Stage 23 decide-policy handler.
state_pattern = re.compile(
    r"(?m)^(?P<indent>[ \t]*)this\.connectSignal\(this\._liveWebView, 'decide-policy',\s*$"
)
state_matches = list(state_pattern.finditer(text))
# There can be older Stage20 policy handlers too. Choose the first decide-policy
# handler after the Stage23 v10 marker.
marker_pos = text.index('GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10')
state_match = next((m for m in state_matches if m.start() > marker_pos), None)
if state_match is None:
    raise SystemExit('Stage 23A decide-policy handler not found after marker')
indent = state_match.group('indent')
text = (
    text[:state_match.start()]
    + indent + 'let liveRetryAttempted = false;\n'
    + text[state_match.start():]
)

# Replace the known v3 retry action semantically, regardless of indentation.
retry_pattern = re.compile(
    r"(?ms)"
    r"^(?P<i>[ \t]*)if \(uri !== 'grayhaired-retry://retry'\)\s*\n"
    r"(?P=i)[ \t]+return false;\s*\n\s*"
    r"(?P=i)print\(`\[GRAYHAIRED-SITE23A\] retrying \$\{liveDesktopUrl\}`\);\s*\n"
    r"(?P=i)decision\.ignore\(\);\s*\n"
    r"(?P=i)webView\.load_uri\(liveDesktopUrl\);\s*\n"
    r"(?P=i)return true;"
)
retry_match = retry_pattern.search(text, marker_pos)
if retry_match is None:
    raise SystemExit('Stage 23A v3 retry action not found')
i = retry_match.group('i')
new_retry_lines = [
    "if (uri !== 'grayhaired-retry://retry')",
    "    return false;",
    "",
    "print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);",
    "liveRetryAttempted = true;",
    "decision.ignore();",
    "",
    "const tryingHtml = `<!doctype html>",
    "<html>",
    "<head>",
    "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "<title>Trying Again</title>",
    "<style>",
    "  :root { color-scheme: light dark; }",
    "  body {",
    "    margin: 0; min-height: 100vh; display: flex; align-items: center;",
    "    justify-content: center; box-sizing: border-box; padding: 42px;",
    "    font-family: system-ui, sans-serif; background: #f5f5f5; color: #242424;",
    "  }",
    "  .card {",
    "    width: min(680px, 100%); background: #fff; border: 1px solid #d0d0d0;",
    "    border-radius: 16px; padding: 34px; box-sizing: border-box;",
    "    box-shadow: 0 4px 18px rgba(0,0,0,.10); text-align: center;",
    "  }",
    "  h1 { margin: 0 0 16px; font-size: 32px; }",
    "  p { font-size: 20px; line-height: 1.5; margin: 12px 0; }",
    "  @media (prefers-color-scheme: dark) {",
    "    body { background: #202326; color: #f4f4f4; }",
    "    .card { background: #292d31; border-color: #50555a; }",
    "  }",
    "</style>",
    "</head>",
    "<body>",
    "  <main class=\"card\">",
    "    <h1>Trying Again…</h1>",
    "    <p>Checking the website one more time.</p>",
    "  </main>",
    "</body>",
    "</html>`;",
    "",
    "webView.load_html(tryingHtml, 'about:blank');",
    "GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {",
    "    print(`[GRAYHAIRED-SITE23A] retry load ${liveDesktopUrl}`);",
    "    webView.load_uri(liveDesktopUrl);",
    "    return GLib.SOURCE_REMOVE;",
    "});",
    "return true;",
]
new_retry = '\n'.join(i + line if line else '' for line in new_retry_lines)
text = text[:retry_match.start()] + new_retry + text[retry_match.end():]

# Add a persistent retry-result message to the failure page.
error_pos = text.find("this.connectSignal(this._liveWebView, 'load-failed'", marker_pos)
if error_pos < 0:
    raise SystemExit('Stage 23A load-failed handler not found')
html_pos = text.find('const errorHtml = `<!doctype html>', error_pos)
if html_pos < 0:
    raise SystemExit('Stage 23A error HTML not found')
line_start = text.rfind('\n', 0, html_pos) + 1
html_indent = text[line_start:html_pos]
status_block = (
    html_indent + "const retryFailed = liveRetryAttempted;\n"
    + html_indent + "const heading = retryFailed ? 'Retry Failed' : 'Website Not Available';\n"
    + html_indent + "const statusMessage = retryFailed\n"
    + html_indent + "    ? 'The website is still unavailable after trying again.'\n"
    + html_indent + "    : 'My Desktop could not reach your selected website.';\n\n"
)
text = text[:line_start] + status_block + text[line_start:]

error_section_end = text.find('webView.load_html(errorHtml', html_pos)
if error_section_end < 0:
    raise SystemExit('Stage 23A error HTML load call not found')
segment = text[html_pos:error_section_end]
if '<h1>Website Not Available</h1>' not in segment:
    raise SystemExit('Stage 23A error heading not found')
segment = segment.replace('<h1>Website Not Available</h1>', '<h1>${heading}</h1>', 1)
if '<p>My Desktop could not reach your selected website.</p>' not in segment:
    raise SystemExit('Stage 23A error status line not found')
segment = segment.replace(
    '<p>My Desktop could not reach your selected website.</p>',
    '<p>${statusMessage}</p>',
    1,
)
text = text[:html_pos] + segment + text[error_section_end:]

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10' "$GRID" || fail "v10 marker missing"
grep -Fq 'Trying Again…' "$GRID" || fail "Trying Again screen missing"
grep -Fq 'Retry Failed' "$GRID" || fail "Retry Failed result missing"
grep -Fq 'retry load ${liveDesktopUrl}' "$GRID" || fail "delayed retry load missing"
grep -Fq 'let liveRetryAttempted = false;' "$GRID" || fail "retry state missing"

pass "Stage 23A v3 upgraded directly to v10 with visible retry feedback"
printf '[GRAYHAIRED-SITE23A] INFO: reload the GrayHaired child and test the invalid site.\n'
