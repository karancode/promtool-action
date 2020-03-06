#!/bin/bash

function promtool_check {

    # gather check promtool output
    echo "check: info: promtool check for ${prom_check_files}."

    check_output=$(promtool check ${prom_check_subcommand} ${prom_check_files} 2>&1)

    check_exit_code=${?}

    # exit code 0 - success
    if [ ${check_exit_code} -eq 0 ];then
        check_comment_status="Success"
        echo "check: info: successfully executed promtool check for ${prom_check_files}."
        echo "${check_output}"
        echo
    fi

    # exit code !0 - failure
    if [ ${check_exit_code} -ne 0 ]; then
        check_comment_status="Failed"
        echo "check: error: failed to execute promtool check for ${prom_check_files}."
        echo "${check_output}"
        echo
    fi

    # comment
    if [ "${GITHUB_EVENT_NAME}" == "pull_request" ] && [ "${prom_comment}" == "1" ]; then
        check_comment_wrapper="#### \`promtool check ${prom_check_subcommand}\` ${check_comment_status}
<details><summary>Show Output</summary>
<pre><code>
${check_output}
</code></pre>
</details>

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Check Files: \`${prom_check_files}\`*"

        echo "check: info: creating json"
        check_payload=$(echo "${check_comment_wrapper}" | jq -R --slurp '{body: .}')
        check_comment_url=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
        echo "check: info: commenting on the pull request"
        echo "${check_payload}" | curl -s -S -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" --header "Content-Type: application/json" --data @- "${check_comment_url}" > /dev/null
    fi

    echo ::set-output name=promtool_output::${check_output}
    exit ${check_exit_code}
}