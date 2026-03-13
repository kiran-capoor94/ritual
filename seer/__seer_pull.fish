function __seer_pull
    set -l root (__seer_require_repo)
    or return 1

    if test -n "$(git status --porcelain)"
        echo "seer: pull blocked because the working tree is dirty"
        echo "Run `seer summary` to inspect the repo state first."
        return 1
    end

    set -l branch (__seer_branch_name)
    set -l upstream (__seer_upstream)
    if test -z "$upstream"
        echo "seer: no upstream configured for $branch"
        return 1
    end

    echo "Fetching and rebasing $branch against $upstream"
    git fetch --prune
    or return 1
    git pull --rebase
    or return 1

    __seer_mark_repo_recent $root
    __seer_mark_branch_recent $root $branch
    __seer_summary
end
