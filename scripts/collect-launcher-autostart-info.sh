#!/usr/bin/env bash
# Read-only launcher and sign-in startup report for a physical Zorin system.
set -u

printf '%s\n' 'GrayHaired Desktop launcher/autostart report (read only)'
printf 'Date (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'XDG_SESSION_TYPE: %s\n' "${XDG_SESSION_TYPE:-unset}"
printf 'XDG_CURRENT_DESKTOP: %s\n' "${XDG_CURRENT_DESKTOP:-unset}"
printf 'XDG_CONFIG_HOME: %s\n' "${XDG_CONFIG_HOME:-unset (defaults to $HOME/.config)}"
printf 'XDG_DATA_HOME: %s\n' "${XDG_DATA_HOME:-unset (defaults to $HOME/.local/share)}"

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
autostart_dir="$config_home/autostart"
applications_dir="$data_home/applications"

print_directory() {
  local label="$1"
  local directory="$2"
  printf '\n== %s: %s ==\n' "$label" "$directory"
  if [[ -d "$directory" ]]; then
    find "$directory" -maxdepth 1 \( -type f -o -type l \) -printf '%f\n' \
      2>/dev/null \
      | LC_ALL=C sort
  else
    printf '%s\n' '(directory does not exist)'
  fi
}

print_directory 'User autostart files' "$autostart_dir"
print_directory 'User application launchers' "$applications_dir"

printf '\n%s\n' '== Relevant desktop entries =='
desktop_files=()
while IFS= read -r -d '' file; do
  desktop_files+=("$file")
done < <(
  find "$autostart_dir" "$applications_dir" /etc/xdg/autostart \
    /usr/local/share/applications /usr/share/applications \
    -maxdepth 1 \( -type f -o -type l \) -name '*.desktop' -print0 2>/dev/null
)

found_entry=false
for file in "${desktop_files[@]}"; do
  if grep -Eqi 'gray[[:space:]_-]*haired|grayhaired-desktop|grayhaired_desktop' \
      "$file" 2>/dev/null; then
    found_entry=true
    printf '\n-- %s --\n' "$file"
    grep -Ei '^(Name|Exec|TryExec|Hidden|X-GNOME-Autostart-enabled)=' \
      "$file" 2>/dev/null || true
  fi
done
if [[ "$found_entry" == false ]]; then
  printf '%s\n' '(no relevant desktop entries found in standard locations)'
fi

printf '\n%s\n' '== Running relevant processes =='
processes="$(ps -eo pid=,ppid=,lstart=,args= 2>/dev/null \
  | grep -Ei 'grayhaired-desktop|grayhaired_desktop|GrayHairedDesktop' \
  | grep -Ev 'grep -Ei|collect-launcher-autostart-info' || true)"
if [[ -n "$processes" ]]; then
  printf '%s\n' "$processes"
else
  printf '%s\n' '(none found)'
fi

printf '\n%s\n' '== Relevant user systemd unit files =='
if command -v systemctl >/dev/null 2>&1; then
  unit_names="$({
    systemctl --user list-unit-files --no-pager --no-legend 2>/dev/null \
      | sed -n 's/^[[:space:]]*\([^[:space:]]\+\).*/\1/p'
    systemctl --user list-units --all --plain --no-pager --no-legend 2>/dev/null \
      | sed -n 's/^[[:space:]]*\([^[:space:]]\+\).*/\1/p'
  } | LC_ALL=C sort -u)"
  relevant_units=()
  while IFS= read -r unit; do
    [[ -n "$unit" ]] || continue
    unit_contents="$(systemctl --user cat --no-pager "$unit" 2>/dev/null || true)"
    if printf '%s\n%s\n' "$unit" "$unit_contents" \
        | grep -Eqi 'gray[[:space:]_-]*haired|grayhaired-desktop|grayhaired_desktop|GrayHairedDesktop'; then
      relevant_units+=("$unit")
    fi
  done <<<"$unit_names"

  if ((${#relevant_units[@]} > 0)); then
    for unit in "${relevant_units[@]}"; do
      printf '\n-- systemctl --user cat %s --\n' "$unit"
      systemctl --user cat --no-pager "$unit" 2>&1 || true
      printf '\n-- systemctl --user status %s --\n' "$unit"
      systemctl --user status --no-pager "$unit" 2>&1 || true
    done
  else
    printf '%s\n' '(none found)'
  fi
else
  printf '%s\n' '(systemctl is unavailable)'
fi

printf '\n%s\n' \
  'This report did not create, modify, enable, disable, launch, or terminate anything.'
