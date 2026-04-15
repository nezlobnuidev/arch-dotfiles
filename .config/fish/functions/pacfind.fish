function pacfind --description "Search installed pacman packages"
    if test (count $argv) -lt 1
        echo "usage: pacfind <pattern>"
        return 1
    end

    pacman -Q | grep -i --color=auto $argv[1]
end
