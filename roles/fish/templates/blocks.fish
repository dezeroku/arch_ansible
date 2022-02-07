function fail_command_with_logs
    if test -z "$argv[1]"
        echo "fail_command_with_logs <command>"
    end

    set -l tmp_log
    set tmp_log (mktemp)

    eval "$argv[1..]" > $tmp_log 2>&1

    if not test $status -eq 0
        cat $tmp_log
        return 1
    end
end
