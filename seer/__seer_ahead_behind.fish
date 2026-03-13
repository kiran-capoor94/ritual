function __seer_ahead_behind
    set -l upstream (__seer_upstream)
    if test -z "$upstream"
        printf "%s\n" 0 0
        return
    end

    set -l counts (git rev-list --left-right --count HEAD...$upstream 2>/dev/null | string split \t)
    printf "%s\n" $counts[1] $counts[2]
end
