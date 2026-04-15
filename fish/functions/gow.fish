function gow --description "Run project with air if available"
    if command -q air
        air
    else
        go run ./...
    end
end
