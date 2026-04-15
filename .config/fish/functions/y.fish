function y --description "Launch yazi and cd into the last visited directory"
    if not command -q yazi
        echo "yazi is not installed"
        return 1
    end

    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    or return 1

    yazi $argv --cwd-file="$tmp"

    if test -s "$tmp"
        set -l cwd (command cat -- "$tmp")
        if test -n "$cwd"
            and test "$cwd" != "$PWD"
            cd -- "$cwd"
        end
    end

    rm -f -- "$tmp"
end
