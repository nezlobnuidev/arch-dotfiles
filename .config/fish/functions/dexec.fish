function dexec --description "Open a shell in a running container"
    if test (count $argv) -lt 1
        echo "usage: dexec <container>"
        return 1
    end

    docker exec -it $argv[1] sh
end
