function check_certificate
    if test (count $argv) -lt 1
        echo "check_certificate URL [PORT]"
        return 1
    end

    set URL "$argv[1]"

    if test (count $argv) -ge 2
        set port "$argv[2]"
    else
        set port "443"
    end

    set tmpfile "$(mktemp)"

    echo | openssl s_client -showcerts -servername "$URL" -connect "$URL:$port" 2>/dev/null > "$tmpfile"
    step-cli certificate inspect "$tmpfile" --short

    rm "$tmpfile"
end

function capture_wireshark
    # Connect to a remote node,
    # run tcpdump on it and forward the captured traffic to
    # wireshark
    if test (count $argv) -lt 2
        echo "capture_wireshark REMOTE_ADDRESS TCPDUMP_RULESET"
        return 1
    end

    set remote "$argv[1]"
    set tcpdump_ruleset "$argv[2]"

    ssh $remote "sudo tcpdump -U -n -w - -i any '"$tcpdump_ruleset"'" | wireshark -k -i -
end

function list_vault_secrets
    # TODO: add support for recursive (with parametrizable depth) querying
    if test (count $argv) -lt 1
        echo "list_vault_secrets PATH"
        return 1
    end

    set VAULT_PATH "$argv[1]"

    for key in (vault kv list -format json "$VAULT_PATH" | yq -r '.[]');
        vault kv get "$VAULT_PATH/$key"
    end
end
