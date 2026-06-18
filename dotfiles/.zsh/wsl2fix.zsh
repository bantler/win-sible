# Fix Interop Error that randomly occurs in vscode terminal when using WSL2
fix_wsl2_interop() {
    for i in $(pstree -np -s $$ | grep -o -E '[0-9]+'); do
        if [[ -e "/run/WSL/${i}_interop" ]]; then
            export WSL_INTEROP=/run/WSL/${i}_interop
        fi
    done
}

fixdns() {
  command sudo bash -c "sed -i '/management.azure.com/d' /etc/hosts" ; sudo bash -c 'echo "$(dig management.azure.com | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}$") management.azure.com" >> /etc/hosts'
}