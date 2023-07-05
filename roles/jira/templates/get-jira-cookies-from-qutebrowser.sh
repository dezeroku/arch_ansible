#!/usr/bin/env bash
set -e

echoerr() { echo "$@" 1>&2; }

echoerr "[AUTH] Obtaining auth cookies from qutebrowser storage"

(
sqlite3 -json "file:${HOME}/.local/share/qutebrowser/webengine/Cookies?immutable=1" << HEREDOC
    SELECT host_key, name, value
    FROM cookies
    WHERE host_key
    LIKE '%{{ work.jira_endpoint | regex_replace('.*://','') }}%' AND (name = 'atlassian.xsrf.token' OR name = 'JSESSIONID')
HEREDOC
) | (
jq "$( cat <<HEREDOC
    [.[] | {
        "Name": .name,
        "Value": .value,
        "Path": .host_key,
        "Domain": "{{ work.jira_endpoint | regex_replace('.*://','') }}",
        "Expires": .expires,
        "Secure": .secure}]
HEREDOC
)"
) > "${HOME}/.jira.d/cookies.js"

echoerr "[AUTH] Got cookies! Saved to ${HOME}/.jira.d/cookies.js"
echoerr "[AUTH] If you are asked to login now, you should go to qutebrowser, log in there and try the cmd again"
