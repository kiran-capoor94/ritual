function __seer_status_counts
    set -l staged (count (git diff --name-only --cached))
    set -l unstaged (count (git diff --name-only))
    set -l untracked (count (git ls-files --others --exclude-standard))
    printf "%s\n" $staged $unstaged $untracked
end
