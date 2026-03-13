function __seer_mark_repo_recent --argument-names repo_root
    set -l data_dir (__seer_data_dir)
    printf "%s\t%s\n" (date +%s) $repo_root >> "$data_dir/repos.log"
end
