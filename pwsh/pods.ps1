# Example of creating pods for kuberbetes
function pod() {
    kubectl get pods --all-namespaces | fzf.exe --info=inline --height 40% --layout=reverse --header-lines=1 `
        --prompt "$(kubectl config current-context | sed 's/-context$//')> " `
        --header "Enter (kubectl exec) / CTRL-O (open log in editor) / CTRL-R (reload) /`n`n" `
        --bind 'ctrl-/:change-preview-window(80%,border-bottom|hidden|)' `
        --bind "enter:execute-silent(wt.exe -w main sp -V pwsh -NoLogo -NoProfile -c kubectl exec -i -t -n {1} {2} -- sh)+abort" `
        --bind 'ctrl-o:execute(kubectl logs --all-containers --namespace {1} {2} | code -)' `
        --bind "ctrl-r:reload(kubectl get pods --all-namespaces)" `
        --preview-window up:follow `
        --preview 'kubectl logs --all-containers --tail=1000 --namespace {1} {2}'
}
