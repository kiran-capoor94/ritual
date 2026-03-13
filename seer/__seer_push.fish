function __seer_push
    set -l root (__seer_require_repo)
    or return 1

    set -l branch (__seer_branch_name)
    set -l upstream (__seer_upstream)
    set -l default_branch (__seer_default_branch)

    if test -n "$default_branch"; and test "$branch" = "$default_branch"
        echo "seer: warning: pushing the default branch ($default_branch)"
    end

    if test -z "$upstream"
        echo "Pushing $branch and setting upstream"
        git push --set-upstream origin $branch
        or return 1
    else
        echo "Pushing $branch to $upstream"
        git push
        or return 1
    end

    __seer_mark_repo_recent $root
    __seer_mark_branch_recent $root $branch
    __seer_summary
end
