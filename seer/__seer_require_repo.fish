function __seer_require_repo
    set -l root (__seer_repo_root)
    if test -z "$root"
        echo "seer: not inside a git repository"
        return 1
    end

    echo $root
end
