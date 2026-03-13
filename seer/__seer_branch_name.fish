function __seer_branch_name
    git symbolic-ref --quiet --short HEAD 2>/dev/null
    or git rev-parse --short HEAD 2>/dev/null
end
