function dez_pushover
    set argc (count $argv)
    if test $argc -eq 0
        echo "dez_pushover [BODY] [apprise args]"
        return 1
    else if test $argc -eq 1
        apprise pover://{{ apprise_pushover_user_key }}@{{ apprise_pushover_api_key }} -b $argv
    else
        apprise pover://{{ apprise_pushover_user_key }}@{{ apprise_pushover_api_key }} $argv
    end
end
