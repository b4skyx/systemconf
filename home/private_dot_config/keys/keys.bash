# keys: load API keys from gopass into bash (bash port of the fish `keys`).
#
# Same groups file (~/.config/keys/groups.conf) and the same saved provider
# choices (~/.local/state/keys/active) as fish, so both shells stay in sync.
#
#   keys                       status of all groups (values masked)
#   keys use <group> <prov>    switch provider (this shell + default for new shells)
#   keys off <group>           unset the group's variables (persisted)
#   keys reload [-q]           (re)load all groups into this shell
#   keys list [group]          list stored providers
#   keys unlock | lock         unlock / lock the gopass age agent
#   keys add|rotate|ssh|edit   handled by the fish implementation (fish -c 'keys ...')
#
# Sourced from ~/.bashrc. Never prompts on load: if gopass is locked it prints
# a hint to run `keys unlock`.

__keys_conf() { printf '%s\n' "${KEYS_CONFIG:-$HOME/.config/keys/groups.conf}"; }
__keys_statefile() { printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/keys/active"; }

# Print config lines (comments/blank removed, whitespace squeezed), optionally one group.
__keys_lines() {
    local conf line
    local -a f
    conf=$(__keys_conf)
    [ -r "$conf" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
        read -r -a f <<<"$line"
        if [ -z "${1:-}" ] || [ "${f[0]}" = "$1" ]; then
            printf '%s\n' "${f[*]}"
        fi
    done <"$conf"
}

__keys_groups() {
    local l
    while IFS= read -r l; do printf '%s\n' "${l%% *}"; done < <(__keys_lines)
}

# Active provider for a group: saved choice, else the configured default.
__keys_active() {
    local group=$1 sf g p f
    sf=$(__keys_statefile)
    if [ -r "$sf" ]; then
        while read -r g p; do
            if [ "$g" = "$group" ] && [ -n "$p" ]; then
                printf '%s\n' "$p"
                return
            fi
        done <"$sf"
    fi
    read -r -a f <<<"$(__keys_lines "$group")"
    printf '%s\n' "${f[2]}"
}

__keys_save() {
    local group=$1 provider=$2 sf rest
    sf=$(__keys_statefile)
    mkdir -p "$(dirname "$sf")"
    rest=""
    [ -r "$sf" ] && rest=$(grep -Ev "^${group}[[:space:]]" "$sf")
    { [ -n "$rest" ] && printf '%s\n' "$rest"; printf '%s %s\n' "$group" "$provider"; } >"$sf"
}

# Read an entry without ever prompting (fails fast when gopass is locked).
__keys_read() {
    GOPASS_AGE_STDIN_PASSPHRASE=1 gopass show -n -- "$1" </dev/null 2>/dev/null
}

__keys_locked_hint() { echo "keys: could not read from gopass (locked?). Run: keys unlock" >&2; }

# Apply one group with the given provider. Returns 1 on failure.
__keys_apply() {
    local group=$1 provider=$2 quiet=${3:-0}
    local f specs spec var src optional entry raw line val found
    read -r -a f <<<"$(__keys_lines "$group")"
    if [ "${#f[@]}" -lt 4 ]; then
        echo "keys: unknown group '$group'" >&2
        return 1
    fi
    specs=("${f[@]:3}")

    if [ "$provider" = - ]; then
        for spec in "${specs[@]}"; do unset "${spec%%=*}"; done
        return 0
    fi

    entry="${f[1]}/$provider"
    mapfile -t raw < <(__keys_read "$entry")
    if [ "${#raw[@]}" -eq 0 ] || [ -z "${raw[0]}" ]; then
        [ "$quiet" = 1 ] || echo "keys: cannot read '$entry'" >&2
        return 1
    fi

    for spec in "${specs[@]}"; do
        var=${spec%%=*}
        src=${spec#*=}
        if [ "$src" = @key ]; then
            export "$var=${raw[0]}"
            continue
        fi
        optional=0
        if [[ $src == *\? ]]; then
            optional=1
            src=${src%\?}
        fi
        found=0
        for line in "${raw[@]:1}"; do
            if [[ $line == "$src:"* ]]; then
                val=${line#"$src:"}
                val=${val#"${val%%[![:space:]]*}"}
                export "$var=$val"
                found=1
                break
            fi
        done
        if [ $found = 0 ]; then
            if [ $optional = 1 ]; then
                unset "$var"
            else
                echo "keys: '$entry' has no field '$src' (for $var)" >&2
            fi
        fi
    done
}

__keys_reload() {
    local quiet=0 failed=0 g n=0
    case "${1:-}" in -q | --quiet) quiet=1 ;; esac
    while IFS= read -r g; do
        n=$((n + 1))
        __keys_apply "$g" "$(__keys_active "$g")" 1 || failed=1
    done < <(__keys_groups)
    if [ $failed = 1 ]; then
        __keys_locked_hint
        return 1
    fi
    [ $quiet = 1 ] || echo "keys: loaded $n groups"
}

__keys_status() {
    local l f prov vars spec var
    printf '%-16s %-12s %s\n' GROUP PROVIDER VARIABLES
    while IFS= read -r l; do
        read -r -a f <<<"$l"
        prov=$(__keys_active "${f[0]}")
        vars=()
        for spec in "${f[@]:3}"; do
            var=${spec%%=*}
            if [ -n "${!var+x}" ]; then
                vars+=("$var=…${!var: -4}")
            else
                vars+=("$var=(unset)")
            fi
        done
        printf '%-16s %-12s %s\n' "${f[0]}" "$prov" "${vars[*]}"
    done < <(__keys_lines)
}

__keys_list() {
    local l f active e p
    while IFS= read -r l; do
        read -r -a f <<<"$l"
        active=$(__keys_active "${f[0]}")
        echo "${f[0]} (${f[1]}):"
        while IFS= read -r e; do
            p=${e#"${f[1]}/"}
            [[ $p == */* ]] && continue
            if [ "$p" = "$active" ]; then echo "  * $p"; else echo "    $p"; fi
        done < <(gopass ls --flat "${f[1]}" 2>/dev/null)
    done < <(__keys_lines "${1:-}")
}

keys() {
    local cmd=${1:-status}
    [ $# -gt 0 ] && shift
    case "$cmd" in
        status | st) __keys_status ;;
        use)
            if [ -z "${2:-}" ]; then
                echo "usage: keys use <group> <provider>" >&2
                return 1
            fi
            __keys_apply "$1" "$2" || return 1
            __keys_save "$1" "$2"
            echo "keys: $1 -> $2"
            ;;
        off)
            if [ -z "${1:-}" ]; then
                echo "usage: keys off <group>" >&2
                return 1
            fi
            __keys_apply "$1" - || return 1
            __keys_save "$1" -
            echo "keys: $1 off"
            ;;
        reload) __keys_reload "$@" ;;
        list | ls) __keys_list "$@" ;;
        unlock) gopass age agent unlock && __keys_reload ;;
        lock) gopass age agent lock ;;
        add | rotate | ssh | edit)
            if command -v fish >/dev/null 2>&1; then
                fish -c 'keys $argv' -- "$cmd" "$@"
                # add/rotate may change values used by this shell
                case "$cmd" in add | rotate) __keys_reload --quiet ;; esac
            else
                echo "keys: '$cmd' needs fish (or use gopass directly)" >&2
                return 1
            fi
            ;;
        help | -h | --help) sed -n '6,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
        *)
            echo "keys: unknown command '$cmd' (see: keys help)" >&2
            return 1
            ;;
    esac
}

# Load keys into interactive shells (never prompts).
if [[ $- == *i* ]] && command -v gopass >/dev/null 2>&1 && [ -r "$(__keys_conf)" ]; then
    keys reload --quiet
fi
