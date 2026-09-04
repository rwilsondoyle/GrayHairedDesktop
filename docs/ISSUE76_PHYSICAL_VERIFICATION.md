# Issue #76 Physical Verification

## Summary

Issue #76 tracked a live-desktop refresh problem observed on the physical Dell Inspiron-3502 running Zorin/GNOME Wayland. When icon size was set to Large, newly added desktop launchers could exist on disk but not appear in the GrayHaired icon pane until the icon size was changed.

## Original symptom

- GrayHaired Live Desktop was already running.
- Icon size was set to Large.
- A new `.desktop` launcher was created in `~/Desktop` and made executable.
- The launcher did not appear, even after waiting and scrolling to the bottom of the icon pane.
- Touching the Desktop directory did not make it appear.
- Changing icon size from Large to Small caused the missing launcher to appear immediately.
- Returning to Large kept the launcher visible.

## Diagnosis

The desktop directory monitor and `_updateDesktop()` path were already receiving desktop-file changes. `_drawDesktop(fileList)` removed the old items, replaced `_fileList`, and called `_placeAllFilesOnGrids()`.

The important difference in the successful icon-size-change path was an additional call to `desktop.resizeGrid()` before icons were placed again. That rebuilds the GrayHaired grid/scroll geometry for the new item count.

The failure therefore was not that the new file was missed. The file list refreshed, but the icon-pane geometry could remain stale until another event, such as changing icon size, forced a grid resize/reflow.

## Fix

The permanent patch is:

`scripts/patch-live-desktop-file-refresh-reflow-issue76.sh`

It patches the shared `_drawDesktop()` path in the installed `desktopManager.js` so every desktop-file redraw rebuilds grid geometry before icon placement:

```js
// GRAYHAIRED-DESKTOP-FILE-REFLOW-ISSUE76
// Desktop-file changes can alter the rows required by the GrayHaired
// scroll canvas. Rebuild grid geometry before placing files.
for (let desktop of this._desktops) {
    desktop.resizeGrid();
}
```

The main installer runs this patch automatically through `scripts/install-gnome-live-desktop.sh`.

## Rollback protection

Before changing the installed manager, the permanent patch saves a rollback copy when one does not already exist:

`desktopManager.js.pre-issue76-file-refresh-reflow`

The patch is idempotent and exits successfully when the permanent marker is already present.

## Physical verification

Tested on the physical Inspiron-3502 under Zorin/GNOME Wayland on 2026-09-04.

1. Reproduced the original failure while staying at Large icon size.
2. Verified the test launcher existed and was executable but did not appear.
3. Verified that Large -> Small caused the launcher to appear, confirming a reflow/rebuild path restored it.
4. Applied the targeted `resizeGrid()` fix to the shared file-redraw path.
5. Created a fresh launcher while remaining at Large; it appeared automatically without changing icon size.
6. Switched to Small, created another fresh launcher, and confirmed it also appeared automatically.
7. Returned to Large successfully.
8. Removed the test launchers and confirmed their icons disappeared automatically, proving the removal path also reflowed correctly.
9. Ran `scripts/verify-live-desktop-known-good.sh`; all checks passed with no FAIL lines and the final promoted-live-desktop PASS.

## GitHub history

- Issue: #76, `Desktop icons may not appear immediately at Large size`
- Fix PR: #78, `Fix desktop icon refresh after file changes`
- PR #78 was squash-merged into `main`.
- Merge commit: `e6fd9b2340c2bf8bceae456ec123fb116f1b110d`
- Issue #76 closed automatically as completed through `Fixes #76` in the PR body.

## Result

Desktop icon additions and removals now trigger the same required grid geometry rebuild regardless of the active icon size. The original Large-size failure is fixed without adding polling or changing normal icon-size behavior.
