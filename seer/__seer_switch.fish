function __seer_switch --argument-names target
    set -l root (__seer_require_repo)
    or return 1

    if test -z "$target"
        echo "Usage: seer switch <branch|->"
        return 1
    end

    if test "$target" = "-"
        git switch -
        or return 1
        set -l branch (__seer_branch_name)
        __seer_mark_repo_recent $root
        __seer_mark_branch_recent $root $branch
        __seer_summary
        return 0
    end

    if git show-ref --verify --quiet "refs/heads/$target"
        git switch $target
        or return 1
    else
        set -l remote_pattern ".*/"(string escape --style=regex -- $target)'$'
        set -l remote_matches (git for-each-ref refs/remotes --format='%(refname:short)' | string match -r $remote_pattern)
        if test (count $remote_matches) -eq 1
            git switch --track $remote_matches[1]
            or return 1
        else
            set -l data_dir (__seer_data_dir)
            set -l log_file "$data_dir/branches.log"
            set -l suggestion

            if test -f "$log_file"
                set -l branch_pattern '^'(string escape --style=regex -- $target)'.*'
                set suggestion (awk -F '\t' -v repo="$root" '$2 == repo {print $3}' "$log_file" | awk '!seen[$1]++' | string match -r $branch_pattern | head -n 1)
            end

            if test -n "$suggestion"
                git switch $suggestion
                or return 1
            else
                echo "seer: branch not found: $target"
                return 1
            end
        end
    end

    set -l branch (__seer_branch_name)
    __seer_mark_repo_recent $root
    __seer_mark_branch_recent $root $branch
    __seer_summary
end
