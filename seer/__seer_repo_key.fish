function __seer_repo_key --argument-names repo_root
    echo $repo_root | string replace -a "/" "__"
end
