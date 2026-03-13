function __seer_recent_repos
    set -l data_dir (__seer_data_dir)
    set -l log_file "$data_dir/repos.log"
    set -l roots "$HOME/Documents/repos/personal" "$HOME/Documents/repos/work"
    set -l temp_file (mktemp)

    if test -f "$log_file"
        awk -F '\t' '{print $1 "\t" $2}' "$log_file" >> $temp_file
    end

    for root in $roots
        if test -d "$root"
            find "$root" -maxdepth 4 -type d -name .git -printf '%T@\t%h\n' 2>/dev/null >> $temp_file
        end
    end

    if not test -s $temp_file
        echo "No recent repositories found."
        rm -f $temp_file
        return 0
    end

    sort -r -n $temp_file | awk -F '\t' '!seen[$2]++ {print $2}' | head -n 10 | while read -l repo
        set -l label (basename $repo)
        set -l context (__seer_repo_context $repo)[1]
        echo "$label [$context]"
        echo "  $repo"
    end

    rm -f $temp_file
end
