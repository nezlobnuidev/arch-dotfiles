function mkcd --description "Create and enter a directory"
    if test (count $argv) -lt 1
        echo "usage: mkcd <dir>"
        return 1
    end

    mkdir -p $argv[1]
    and cd $argv[1]
end
