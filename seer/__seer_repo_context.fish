function __seer_repo_context --argument-names repo_root
    set -l remote_url (git -C $repo_root config --get remote.origin.url 2>/dev/null)
    set -l identity_email (git -C $repo_root config --get user.email 2>/dev/null)
    set -l context unknown
    set -l remote_host "-"

    if test -n "$remote_url"
        set remote_host (string replace -r '^git@([^:]+):.*$' '$1' $remote_url)
        if string match -q "*github-personal*" $remote_url
            set context personal
        else if string match -q "*github-work*" $remote_url
            set context work
        end
    end

    if test "$context" = unknown
        if string match -q "$HOME/Documents/repos/personal*" $repo_root
            set context personal
        else if string match -q "$HOME/Documents/repos/work*" $repo_root
            set context work
        end
    end

    if test "$context" = unknown
        if string match -q "*@gmail.com" $identity_email
            set context personal
        else if test -n "$identity_email"
            set context work
        end
    end

    printf "%s\n" $context $identity_email $remote_host
end
