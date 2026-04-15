function groot --description "Go to git repository root"
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    or return 1

    cd $root
end
