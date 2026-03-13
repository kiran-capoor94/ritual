function gh-clone
    if test (count $argv) -ne 2
        echo "Usage: gh-clone <personal|work> <owner/repo>"
        return 1
    end

    set ACCOUNT $argv[1]
    set REPO $argv[2]

    switch $ACCOUNT
        case personal
            set HOST github-personal
            set GIT_NAME "Kiran Capoor"
            set GIT_EMAIL "kiran.capoor94@gmail.com"
            set TARGET_DIR ~/Documents/repos/personal

        case work
            set HOST github-work
            set GIT_NAME "Kiran Capoor"
            set GIT_EMAIL "kiran.capoor@sisuhealth.co.uk"
            set TARGET_DIR ~/Documents/repos/work

        case '*'
            echo "Invalid account. Use personal or work."
            return 1
    end

    set REPO_NAME (basename $REPO)
    set CLONE_URL git@$HOST:$REPO.git

    mkdir -p $TARGET_DIR
    cd $TARGET_DIR

    git clone $CLONE_URL
    cd $REPO_NAME

    git config user.name "$GIT_NAME"
    git config user.email "$GIT_EMAIL"

    git status
end
