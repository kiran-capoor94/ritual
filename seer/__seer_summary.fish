function __seer_summary
    set -l root (__seer_require_repo)
    or return 1

    set -l branch (__seer_branch_name)
    set -l upstream (__seer_upstream)
    set -l counts (__seer_status_counts)
    set -l staged $counts[1]
    set -l unstaged $counts[2]
    set -l untracked $counts[3]
    set -l ahead_behind (__seer_ahead_behind)
    set -l ahead $ahead_behind[1]
    set -l behind $ahead_behind[2]
    set -l stash_count (count (git stash list))
    set -l last_commit (git log -1 --pretty="format:%h %s" 2>/dev/null)
    set -l context_parts (__seer_repo_context $root)
    set -l context $context_parts[1]
    set -l identity $context_parts[2]
    set -l remote_host $context_parts[3]
    set -l repo_name (basename $root)
    set -l status_label clean

    if test $staged -gt 0
        set status_label dirty
    else if test $unstaged -gt 0
        set status_label dirty
    else if test $untracked -gt 0
        set status_label dirty
    end

    echo "$repo_name [$context]"
    echo "  branch:   $branch"
    echo "  upstream: "(test -n "$upstream"; and echo $upstream; or echo "-")
    echo "  sync:     ahead $ahead / behind $behind"
    echo "  status:   $status_label (staged $staged, unstaged $unstaged, untracked $untracked)"
    echo "  stash:    $stash_count"
    echo "  remote:   $remote_host"
    echo "  identity: "(test -n "$identity"; and echo $identity; or echo "-")
    echo "  commit:   $last_commit"

    if contains -- --full $argv
        echo "  root:     $root"
        echo "  remotes:"
        git remote -v | sed 's/^/    /'
    end

    __seer_mark_repo_recent $root
    __seer_mark_branch_recent $root $branch
end
