function __seer_mark_branch_recent --argument-names repo_root branch_name
    if test -z "$branch_name"
        return
    end

    set -l data_dir (__seer_data_dir)
    printf "%s\t%s\t%s\n" (date +%s) $repo_root $branch_name >> "$data_dir/branches.log"
end
