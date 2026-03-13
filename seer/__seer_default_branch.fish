function __seer_default_branch
    git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | string replace "refs/remotes/origin/" ""
end
