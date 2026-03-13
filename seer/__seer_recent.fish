function __seer_recent
    set -l mode repos
    if test (count $argv) -gt 0
        set mode $argv[1]
    end

    switch $mode
        case repos
            __seer_recent_repos
        case branches
            __seer_recent_branches
        case '*'
            echo "seer recent supports: repos, branches"
            return 1
    end
end
