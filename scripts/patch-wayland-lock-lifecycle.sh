#!/usr/bin/env bash
set -euo pipefail

TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$TEST_UUID"
FILE="$EXT/extension.js"

if [[ ! -f "$FILE" ]]; then
    echo "GrayHaired Wayland prototype extension.js not found:"
    echo "  $FILE"
    exit 2
fi

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

if "[GRAYHAIRED-LIFECYCLE]" in text:
    print("Lock/unlock lifecycle patch is already present.")
    raise SystemExit(0)

old_disable_start = """    disable() {
        this.DesktopIconsUsableArea = null;
        this.data.isEnabled = false;
        this.killCurrentProcess();
        this.data.GnomeShellOverride.disable();
        this.data.x11Manager.disable();
        this.data.visibleArea.disable();
"""

new_disable_start = """    disable() {
        // GrayHairedDesktop Wayland research: GNOME Shell disables extensions
        // while entering the lock-screen session mode. A teardown exception
        // must never escape this method, because it can abort GNOME Shell's
        // extension-session update and leave other Zorin extensions INACTIVE.
        this.data.isEnabled = false;

        const safeDisableStep = (name, callback) => {
            try {
                callback();
            } catch (e) {
                logError(e, `[GRAYHAIRED-LIFECYCLE] disable step failed: ${name}`);
            }
        };

        safeDisableStep('killCurrentProcess', () => this.killCurrentProcess());
        safeDisableStep('GnomeShellOverride.disable', () => {
            if (this.data.GnomeShellOverride)
                this.data.GnomeShellOverride.disable();
        });
        safeDisableStep('x11Manager.disable', () => {
            if (this.data.x11Manager)
                this.data.x11Manager.disable();
        });
        safeDisableStep('visibleArea.disable', () => {
            if (this.data.visibleArea)
                this.data.visibleArea.disable();
        });

        this.DesktopIconsUsableArea = null;
"""

if old_disable_start not in text:
    raise SystemExit("Expected disable() start block not found; no changes made.")
text = text.replace(old_disable_start, new_disable_start, 1)

old_kill_tail = """        this.data.currentProcess = null;
        this.data.x11Manager.setWaylandClient(null);
    }
"""

new_kill_tail = """        this.data.currentProcess = null;
        try {
            if (this.data.x11Manager)
                this.data.x11Manager.setWaylandClient(null);
        } catch (e) {
            logError(e, '[GRAYHAIRED-LIFECYCLE] setWaylandClient(null) failed during teardown');
        }
    }
"""

if old_kill_tail not in text:
    raise SystemExit("Expected killCurrentProcess() tail not found; no changes made.")
text = text.replace(old_kill_tail, new_kill_tail, 1)

path.write_text(text, encoding="utf-8")
print("Applied defensive lock/unlock lifecycle patch to GrayHaired Wayland prototype.")
PY

cat <<EOF

=== LOCK/UNLOCK LIFECYCLE PATCH APPLIED ===

Patched only the user-local research extension:
  $FILE

The system Zorin extension was NOT modified.

Next: toggle the GrayHaired extension once so GNOME Shell loads the patched code.
EOF
