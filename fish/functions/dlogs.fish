function dlogs --description "docker logs -f with tail"
    if test (count $argv) -lt 1
        echo "usage: dlogs <container> [extra args]"
        return 1
    end

    docker logs -f --tail=200 $argv
end
