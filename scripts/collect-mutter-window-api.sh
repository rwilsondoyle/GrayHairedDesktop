#!/usr/bin/env bash
# Read-only GNOME 46 GI API probe; does not access or change live windows.
set -u

printf '%s\n' 'GrayHaired Desktop: Mutter window API report'
printf 'GNOME Shell: '
if command -v gnome-shell >/dev/null 2>&1; then
    gnome-shell --version 2>&1
else
    printf '%s\n' 'not installed or not on PATH'
fi

if ! command -v gjs >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: gjs is not installed or not on PATH' >&2
    exit 1
fi

gjs -c '
const Meta = imports.gi.Meta;

const windowMethods = [
    "lower", "raise", "get_stack_position", "set_stack_position",
    "get_layer", "set_type", "stick", "unstick",
    "hide_from_window_list", "show_in_window_list",
];
const displayMethods = [
    "sort_windows_by_stacking", "restack_window", "set_stack_position",
    "get_stack_position", "lower", "raise",
];

function report(typeName, prototype, methods) {
    print(`\n== ${typeName} candidate methods ==`);
    for (const name of methods)
        print(`${name}: ${typeof prototype[name] === "function" ? "AVAILABLE" : "NOT EXPOSED"}`);

    const related = new Set();
    for (let current = prototype; current; current = Object.getPrototypeOf(current)) {
        for (const name of Object.getOwnPropertyNames(current)) {
            if (/(stack|restack|layer|lower|raise)/i.test(name) &&
                typeof prototype[name] === "function")
                related.add(name);
        }
    }
    print(`Related callable names: ${[...related].sort().join(", ") || "(none enumerated)"}`);
}

report("Meta.Window", Meta.Window.prototype, windowMethods);
report("Meta.Display / global.display", Meta.Display.prototype, displayMethods);
print("\nThis probes GNOME introspection metadata only; it does not manipulate a window.");
' 2>&1
