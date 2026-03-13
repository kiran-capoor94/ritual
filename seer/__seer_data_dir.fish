function __seer_data_dir
    set -l base_dir "$HOME/.local/share"
    if set -q XDG_DATA_HOME
        set base_dir $XDG_DATA_HOME
    end

    set -l dir "$base_dir/ritual/seer"
    mkdir -p $dir
    echo $dir
end
