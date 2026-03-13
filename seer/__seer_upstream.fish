function __seer_upstream
    git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null
end
