function __seer_recent_branches
    set -l root (__seer_require_repo)
    or return 1

    set -l data_dir (__seer_data_dir)
    set -l log_file "$data_dir/branches.log"
    set -l current_branch (__seer_branch_name)

    if test -f "$log_file"
        awk -F '\t' -v repo="$root" '$2 == repo {print $1 "\t" $3}' "$log_file" | sort -r -n | awk -F '\t' '!seen[$2]++ {print $2}' | head -n 10 | while read -l branch
            set -l marker " "
            if test "$branch" = "$current_branch"
                set marker "*"
            end
            set -l subject (git log -1 --pretty="format:%s" "$branch" 2>/dev/null)
            echo "$marker $branch"
            if test -n "$subject"
                echo "  $subject"
            end
        end
        return 0
    end

    git for-each-ref refs/heads --sort=-committerdate --format='%(refname:short)%09%(subject)' | head -n 10 | while read -l line
        set -l parts (string split \t -- $line)
        set -l branch $parts[1]
        set -l marker " "
        if test "$branch" = "$current_branch"
            set marker "*"
        end
        echo "$marker $branch"
        if test -n "$parts[2]"
            echo "  $parts[2]"
        end
    end
end
