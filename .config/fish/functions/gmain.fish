function gmain --description "Checkout main or master"
    git show-ref --verify --quiet refs/heads/main
    and git checkout main
    or git checkout master
end
