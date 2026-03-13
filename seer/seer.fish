function seer
    set -l command summary
    if test (count $argv) -gt 0
        set command $argv[1]
        set -e argv[1]
    end

    switch $command
        case summary
            __seer_summary $argv
        case recent
            __seer_recent $argv
        case switch
            __seer_switch $argv
        case pull
            __seer_pull $argv
        case push
            __seer_push $argv
        case help -h --help
            __seer_help
        case '*'
            echo "Unknown seer command: $command"
            __seer_help
            return 1
    end
end
