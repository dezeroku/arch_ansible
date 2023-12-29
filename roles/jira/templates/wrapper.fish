function jira
    # Obtain the "real binary" path to avoid infinite loop
    set -l jira_bin
    set jira_bin (which jira)

    "$HOME/.jira.d/get-jira-cookies-from-qutebrowser.sh" && "$jira_bin" $argv
end
