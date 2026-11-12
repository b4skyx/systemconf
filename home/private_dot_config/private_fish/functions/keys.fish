# keys: load API keys (and SSH keys) from gopass into fish.
#
# Groups are defined in ~/.config/keys/groups.conf. Each group maps one gopass
# entry (<folder>/<provider>) to one or more environment variables. The chosen
# provider per group is remembered in ~/.local/state/keys/active.
#
#   keys                      status of all groups (values masked)
#   keys use <group> <prov>   switch provider (this shell + default for new shells)
#   keys off <group>          unset the group's variables (persisted)
#   keys reload [-q]          (re)load all groups into this shell
#   keys list [group]         list stored providers
#   keys add <group> <prov>   store a new key (hidden prompt)
#   keys rotate <group> [prov] replace a stored key, keep its other fields
#   keys unlock               unlock gopass (prompts for the age passphrase)
#   keys ssh push <name>|all  push keys to gopass (no default); bare name = pair
#   keys ssh pull [name|all] [--force]
#                             restore keys from gopass (default: all)
#   keys ssh ls               list tracked keys in the store
#   keys edit                 edit groups.conf
function keys --description 'Manage API keys stored in gopass'
    set -l cmd status
    if set -q argv[1]
        set cmd $argv[1]
        set -e argv[1]
    end

    switch $cmd
        case status st
            __keys_status
        case use
            __keys_use $argv
        case off
            __keys_off $argv
        case reload
            __keys_reload $argv
        case list ls
            __keys_list $argv
        case add
            __keys_add $argv
        case rotate
            __keys_rotate $argv
        case unlock
            gopass age agent unlock; and __keys_reload
        case lock
            gopass age agent lock
        case ssh
            __keys_ssh $argv
        case edit
            $EDITOR (__keys_conf)
        case help -h --help
            sed -n '3,16p' (functions --details keys) | string replace -r '^# ?' ''
        case '*'
            echo "keys: unknown command '$cmd' (see: keys help)" >&2
            return 1
    end
end

# ---------------------------------------------------------------- helpers ---

function __keys_conf
    if set -q KEYS_CONFIG
        echo $KEYS_CONFIG
    else
        echo ~/.config/keys/groups.conf
    end
end

function __keys_statefile
    set -l dir ~/.local/state/keys
    if set -q XDG_STATE_HOME
        set dir $XDG_STATE_HOME/keys
    end
    echo $dir/active
end

# Print config lines (comments/blank removed), optionally only for one group.
function __keys_lines
    set -l conf (__keys_conf)
    test -r $conf; or return 1
    for line in (string match -rv '^\s*(#|$)' <$conf)
        set -l f (string split -n ' ' -- (string replace -ra '\s+' ' ' -- (string trim -- $line)))
        if not set -q argv[1]; or test "$f[1]" = "$argv[1]"
            echo (string join ' ' -- $f)
        end
    end
end

function __keys_groups
    for l in (__keys_lines)
        string split -f1 ' ' -- $l
    end
end

# Active provider for a group: saved choice, else the configured default.
function __keys_active -a group
    set -l sf (__keys_statefile)
    if test -r $sf
        set -l saved (string match -r "^$group\s+(\S+)" <$sf)
        if set -q saved[2]
            echo $saved[2]
            return
        end
    end
    set -l f (string split ' ' -- (__keys_lines $group))
    echo $f[3]
end

function __keys_save -a group provider
    set -l sf (__keys_statefile)
    mkdir -p (path dirname $sf)
    set -l rest
    test -r $sf; and set rest (string match -rv "^$group\s" <$sf)
    printf '%s\n' $rest "$group $provider" >$sf
end

# Read an entry without ever prompting (fails fast when gopass is locked).
function __keys_read -a entry
    env GOPASS_AGE_STDIN_PASSPHRASE=1 gopass show -n -- $entry </dev/null 2>/dev/null
end

function __keys_locked_hint
    echo "keys: could not read from gopass (locked?). Run: keys unlock" >&2
end

# Apply one group with the given provider. Returns 1 on failure.
function __keys_apply -a group provider quiet
    set -l f (string split ' ' -- (__keys_lines $group))
    if not set -q f[4]
        echo "keys: unknown group '$group'" >&2
        return 1
    end
    set -l specs $f[4..-1]

    if test "$provider" = -
        for spec in $specs
            set -e (string split -f1 = -- $spec)
        end
        return 0
    end

    set -l entry $f[2]/$provider
    set -l raw (__keys_read $entry)
    if test $status -ne 0; or not set -q raw[1]
        test "$quiet" = 1; or echo "keys: cannot read '$entry'" >&2
        return 1
    end

    for spec in $specs
        set -l kv (string split -m1 = -- $spec)
        set -l var $kv[1]
        set -l src $kv[2]
        if test "$src" = @key
            set -gx $var $raw[1]
            continue
        end
        set -l optional 0
        if string match -q '*?' -- $src
            set optional 1
            set src (string sub -e -1 -- $src)
        end
        set -l val (string match -r "^\Q$src\E:\s*(.*)\$" -- $raw[2..-1])
        if set -q val[2]
            set -gx $var $val[2]
        else if test $optional = 1
            set -e $var
        else
            echo "keys: '$entry' has no field '$src' (for $var)" >&2
        end
    end
end

# ---------------------------------------------------------------- commands ---

function __keys_reload
    set -l quiet 0
    contains -- -q $argv; or contains -- --quiet $argv; and set quiet 1
    set -l failed 0
    for g in (__keys_groups)
        __keys_apply $g (__keys_active $g) 1; or set failed 1
    end
    if test $failed = 1
        __keys_locked_hint
        return 1
    end
    test $quiet = 1; or echo "keys: loaded" (count (__keys_groups)) groups
end

function __keys_status
    set -l sf (__keys_statefile)
    printf '%-16s %-12s %s\n' GROUP PROVIDER VARIABLES
    for l in (__keys_lines)
        set -l f (string split ' ' -- $l)
        set -l prov (__keys_active $f[1])
        set -l vars
        for spec in $f[4..-1]
            set -l var (string split -f1 = -- $spec)
            if set -q $var
                set -l v $$var
                set -a vars "$var=…"(string sub -s -4 -- $v)
            else
                set -a vars "$var=(unset)"
            end
        end
        printf '%-16s %-12s %s\n' $f[1] $prov "$vars"
    end
end

function __keys_list -a group
    for l in (__keys_lines $group)
        set -l f (string split ' ' -- $l)
        set -l active (__keys_active $f[1])
        echo "$f[1] ($f[2]):"
        for e in (gopass ls --flat $f[2] 2>/dev/null)
            set -l p (string replace -- "$f[2]/" '' $e)
            string match -q '*/*' -- $p; and continue
            if test "$p" = "$active"
                echo "  * $p"
            else
                echo "    $p"
            end
        end
    end
end

function __keys_use -a group provider
    if test -z "$provider"
        echo "usage: keys use <group> <provider>" >&2
        return 1
    end
    __keys_apply $group $provider; or return 1
    __keys_save $group $provider
    echo "keys: $group -> $provider"
end

function __keys_off -a group
    test -n "$group"; or begin
        echo "usage: keys off <group>" >&2
        return 1
    end
    __keys_apply $group -; or return 1
    __keys_save $group -
    echo "keys: $group off"
end

function __keys_add -a group provider
    set -l f (string split ' ' -- (__keys_lines $group))
    if not set -q f[2]; or test -z "$provider"
        echo "usage: keys add <group> <provider>  (group must exist in "(__keys_conf)")" >&2
        return 1
    end
    set -l entry $f[2]/$provider
    read -s -P "Key for $entry: " -l key; or return 1
    test -n "$key"; or return 1
    printf '%s\n' $key | gopass insert -- $entry >/dev/null; or return 1
    echo "keys: stored $entry  (add fields with: gopass edit $entry)"
end

function __keys_rotate -a group provider
    set -l f (string split ' ' -- (__keys_lines $group))
    if not set -q f[2]
        echo "usage: keys rotate <group> [provider]" >&2
        return 1
    end
    test -n "$provider"; or set provider (__keys_active $group)
    set -l entry $f[2]/$provider
    set -l raw (__keys_read $entry)
    or begin
        __keys_locked_hint
        return 1
    end
    read -s -P "New key for $entry: " -l key; or return 1
    test -n "$key"; or return 1
    printf '%s\n' $key $raw[2..-1] | gopass insert -f -- $entry >/dev/null; or return 1
    echo "keys: rotated $entry (old value kept in gopass history)"
    # Reload every group currently using this entry.
    for g in (__keys_groups)
        set -l gf (string split ' ' -- (__keys_lines $g))
        test "$gf[2]/"(__keys_active $g) = $entry; and __keys_apply $g (__keys_active $g)
    end
end

# SSH keys: stored as binary entries under ssh/<filename>.
# Only key pairs (~/.ssh/id_* and their .pub); ~/.ssh/config stays per machine.
# Names may be given with or without .pub; a bare name selects the whole pair.
# push takes explicit names or `all` (no default); pull defaults to all.
# Uses `gopass cat` (stdin) so commit messages never contain local paths.
function __keys_ssh -a sub
    set -l force 0
    set -l names
    set -l failed 0
    for a in $argv[2..-1]
        if test "$a" = --force
            set force 1
        else
            set -a names $a
        end
    end

    switch "$sub"
        case push
            if test (count $names) -eq 0
                echo "usage: keys ssh push <name>... | all  (no default)" >&2
                return 1
            end
            set -l files
            if contains -- all $names
                for k in ~/.ssh/id_*
                    string match -q '*.pub' -- $k; and continue
                    test -f $k; or continue
                    set -a files $k $k.pub
                end
            else
                for n in $names
                    set -l base (string replace -r '\.pub$' '' -- $n)
                    set -l hit 0
                    if test -f ~/.ssh/$base
                        set -a files ~/.ssh/$base
                        set hit 1
                    end
                    if test -f ~/.ssh/$base.pub
                        set -a files ~/.ssh/$base.pub
                        set hit 1
                    end
                    if test $hit = 0
                        echo "keys: no local key matching '$n'" >&2
                        set failed 1
                    end
                end
            end
            for file in $files
                # Skip when the store already has identical content.
                set -l tmp (mktemp)
                if gopass cat ssh/(path basename $file) >$tmp 2>/dev/null; and cmp -s $tmp $file
                    rm -f $tmp
                    echo "up-to-date ssh/"(path basename $file)
                    continue
                end
                rm -f $tmp
                gopass cat ssh/(path basename $file) <$file >/dev/null
                and echo "pushed ssh/"(path basename $file)
                or set failed 1
            end
        case pull
            mkdir -p ~/.ssh; and chmod 700 ~/.ssh
            set -l entries (gopass ls --flat ssh 2>/dev/null)
            if test (count $entries) -eq 0
                __keys_locked_hint
                return 1
            end
            if test (count $names) -gt 0; and not contains -- all $names
                set -l filtered
                for n in $names
                    set -l base (string replace -r '\.pub$' '' -- $n)
                    set -l hit 0
                    for e in $entries
                        set -l name (string replace 'ssh/' '' -- $e)
                        if test "$name" = "$n"; or test (string replace -r '\.pub$' '' -- $name) = "$base"
                            contains -- $e $filtered; or set -a filtered $e
                            set hit 1
                        end
                    end
                    if test $hit = 0
                        echo "keys: nothing in store matches '$n'" >&2
                        set failed 1
                    end
                end
                set entries $filtered
            end
            for e in $entries
                set -l name (string replace 'ssh/' '' -- $e)
                set -l dest ~/.ssh/$name
                if test -e $dest; and test $force = 0
                    echo "skip $dest (exists; use --force)"
                    continue
                end
                test -e $dest; and cp -p $dest $dest.bak-(date +%Y%m%d%H%M%S)
                printf '' >$dest; and chmod 600 $dest   # never world-readable, even briefly
                gopass cat $e >$dest; or continue
                if string match -q '*.pub' -- $name
                    chmod 644 $dest
                else
                    chmod 600 $dest
                end
                echo "pulled $dest"
            end
        case ls list ''
            gopass ls --flat ssh 2>/dev/null
        case '*'
            echo "usage: keys ssh push <name>... | all | pull [name...|all] [--force] | ls" >&2
            return 1
    end
    test $failed = 0
end
