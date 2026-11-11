functions -q keys # autoload helpers from functions/keys.fish
set -l cmds status use off reload list add rotate unlock lock ssh edit help

complete -c keys -f
complete -c keys -n "not __fish_seen_subcommand_from $cmds" -a "$cmds"
complete -c keys -n "__fish_seen_subcommand_from use off list add rotate; and test (count (commandline -opc)) -eq 2" -a "(__keys_groups)"
complete -c keys -n "__fish_seen_subcommand_from use rotate; and test (count (commandline -opc)) -eq 3" -a "(__keys_complete_providers)"
complete -c keys -n "__fish_seen_subcommand_from ssh; and test (count (commandline -opc)) -eq 2" -a "push pull ls"

function __keys_complete_providers
    set -l group (commandline -opc)[3]
    set -l f (string split ' ' -- (__keys_lines $group))
    set -q f[2]; or return
    for e in (gopass ls --flat $f[2] 2>/dev/null)
        set -l p (string replace -- "$f[2]/" '' $e)
        string match -q '*/*' -- $p; or echo $p
    end
end
