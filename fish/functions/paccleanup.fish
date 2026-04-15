function paccleanup --description "Remove pacman orphans"
    set -l orphans (pacman -Qdtq)

    if test (count $orphans) -eq 0
        echo "no orphan packages"
        return 0
    end

    sudo pacman -Rns $orphans
end
