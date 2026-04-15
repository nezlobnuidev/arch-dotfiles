function gundo --description "Undo last commit, keep changes"
    git reset --soft HEAD~1
end
