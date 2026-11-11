# Load API keys from gopass into interactive shells (see: keys help).
# Never prompts: if gopass is locked, prints a hint to run `keys unlock`.
if status is-interactive; and type -q gopass; and test -r ~/.config/keys/groups.conf
    keys reload --quiet
end
