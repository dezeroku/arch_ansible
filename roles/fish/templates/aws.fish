function lambda_python_venv
    python3 -m venv lambda_venv && \
    . lambda_venv/bin/activate.fish
end

# Quite a mouthful :D
function lambda_python_venv_deactivate
    deactivate
end

function lambda_python_package
    set -l output_file
    set output_file lambda_deployment.zip

    if test -n "$argv[1]"
        set output_file $argv[1]
    end

    pushd lambda_venv/lib/python3*/site-packages && \
    zip -r ../../../../$output_file . && \
    popd && \
    zip -g $output_file lambda_function.py
end

function lambda_invoke_dummy
    if test -z "$argv[1]"
        echo "lambda_invoke_dummy <function_name> [output_file]"
        return
    end

    set -l call_output_file
    set call_output_file /tmp/lambda_dummy_output

    if test -n "$argv[2]"
        set call_output_file $argv[2]
    end

    aws lambda invoke --function-name $argv[1] --payload '{"key1":"value1"}' $call_output_file
end

function lambda_update_function_zip
    if test -z "$argv[1]"; or test -z "$argv[2]"
        echo "lambda_update_function_zip <function_name> <zip_file>"
        return
    end

    aws lambda update-function-code --function-name $argv[1] --zip-file fileb://$argv[2]
end

function lambda_python_full_test_run_zip
    if test -z "$argv[1]"
        echo "lambda_full_test_run_zip <function_name>"
        return
    end

    set -l tmp_log
    set tmp_log (mktemp)

    fail_command_with_logs lambda_python_package && \
    fail_command_with_logs lambda_update_function_zip $argv[1] lambda_deployment.zip && \
    aws lambda wait function-updated --function-name $argv[1] && \
    lambda_invoke_dummy $argv[1]
end

# Set up the autocompletion
if type -f aws > /dev/null 2>&1
    complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'
end