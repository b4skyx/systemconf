function fix_patch --description 'Normalize a git patch to UTF-8/no-BOM/LF so it applies on Linux'
    if test (count $argv) -ne 1
        echo "usage: fix_patch <patch-file>"
        return 1
    end

    set -l file $argv[1]
    if not test -f $file
        echo "fix_patch: no such file: $file"
        return 1
    end

    set -l head (head -c 2 $file | xxd -p)

    if test "$head" = "fffe"
        iconv -f UTF-16LE -t UTF-8 $file >$file.tmp
    else if test "$head" = "feff"
        iconv -f UTF-16BE -t UTF-8 $file >$file.tmp
    else
        cp $file $file.tmp
    end

    # strip stray UTF-8 BOM, then CRLF -> LF
    sed -i '1s/^\xef\xbb\xbf//' $file.tmp
    sed -i 's/\r$//' $file.tmp

    mv $file.tmp $file
    echo "fix_patch: normalized $file (UTF-8, no BOM, LF)"

    # only verify against a working tree if we're actually inside one
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        if git apply --check $file
            echo "fix_patch: $file applies cleanly against current repo"
        else
            echo "fix_patch: normalized, but does not apply against current repo - inspect manually"
            return 1
        end
    else
        echo "fix_patch: not inside a git repo, skipped apply check"
    end
end
