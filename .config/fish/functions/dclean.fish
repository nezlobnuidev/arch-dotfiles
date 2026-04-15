function dclean --description "Prune unused docker data"
    docker system prune -af --volumes
end
