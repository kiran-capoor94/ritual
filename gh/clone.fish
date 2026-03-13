function gh-clone
    if test (count $argv) -ne 2
        echo "Usage: gh-clone <personal|work> <owner/repo>"
        return 1
    end

    set -l config_bin (type -p ritual-config)
    if test -z "$config_bin"
        echo "ritual-config is required. Run 'bash ritual.sh configure'."
        return 1
    end

    set -l personal_host ($config_bin get github.personal.host)
    set -l work_host ($config_bin get github.work.host)
    set -l personal_name ($config_bin get identity.personal.name)
    set -l personal_email ($config_bin get identity.personal.email)
    set -l work_name ($config_bin get identity.work.name)
    set -l work_email ($config_bin get identity.work.email)
    set -l personal_dir ($config_bin get repos.personal_dir)
    set -l work_dir ($config_bin get repos.work_dir)

    set -l account $argv[1]
    set -l repo $argv[2]

    switch $account
        case personal
            set host $personal_host
            set git_name $personal_name
            set git_email $personal_email
            set target_dir $personal_dir
        case work
            set host $work_host
            set git_name $work_name
            set git_email $work_email
            set target_dir $work_dir
        case '*'
            echo "Invalid account. Use personal or work."
            return 1
    end

    set -l repo_name (basename $repo)
    set -l clone_url git@$host:$repo.git

    mkdir -p $target_dir
    cd $target_dir

    git clone $clone_url
    cd $repo_name

    git config user.name "$git_name"
    git config user.email "$git_email"

    git status --short --branch
end
