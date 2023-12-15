function dez_pushover
    apprise pover://{{ apprise_pushover_user_key }}@{{ apprise_pushover_api_key }} $argv
end
