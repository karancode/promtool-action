#!/bin/bash

function promtool_check {

    # gather check promtool output
    echo "check: info: promtool check for ${prom_check_files}."

    # NOTE(arthurb): If you use the pull_request.paths feature, the grep here is unnecessary
    set -o noglob
    changed_files="$(git diff HEAD^ --name-only | grep "$(dirname "${prom_check_files}")")"
    set +o noglob

    full_output=""
    for c in $changed_files; do
      check_output="$(promtool check "${prom_check_subcommand}" <(oq -i yaml '.spec' "${c}"))"
      check_exit_code=${?}
      full_output="${c}:\n${check_output}\n${full_output}"

      # no rules round - failure
      if [[ ${check_output} == *" 0 rules found"* ]]; then
          check_comment_status="Failed"
          echo "check: error: failed to execute \`promtool check ${prom_check_subcommand}\` for ${c}."
          echo "${check_output}"
          check_exit_code=1
          echo
          break
      fi

      # exit code 0 - success
      if [ ${check_exit_code} -eq 0 ];then
          check_comment_status="Success"
          echo "check: info: successfully executed \`promtool check ${prom_check_subcommand}\` for ${c}."
          echo "${check_output}"
          echo
      fi

      # exit code !0 - failure
      # NOTE(arthurb): This fast fails, which isn't ideal, but good enough for now
      if [ ${check_exit_code} -ne 0 ]; then
          check_comment_status="Failed"
          echo "check: error: failed to execute \`promtool check ${prom_check_subcommand}\` for ${c}."
          echo "${check_output}"
          echo
          break
      fi
    done

    # comment
    if [ "${GITHUB_EVENT_NAME}" == "pull_request" ] && [ "${prom_comment}" == "1" ]; then
        check_comment_wrapper="#### \`promtool check ${prom_check_subcommand}\` ${check_comment_status}
\`\`\`shell
$(echo -e "${full_output}")
\`\`\`

* Workflow: \`${GITHUB_WORKFLOW}\`
* Action: \`${GITHUB_ACTION}\`
* Check Files: \`$(echo -e "${changed_files}")\`"

        echo "check: info: creating json"
        check_payload=$(echo "${check_comment_wrapper}" | jq -R --slurp '{body: .}')
        check_comment_url=$(jq -r .pull_request.comments_url "${GITHUB_EVENT_PATH}")
        echo "check: info: commenting on the pull request"
        echo "${check_payload}" | curl -s -S -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" --header "Content-Type: application/json" --data @- "${check_comment_url}" > /dev/null
    fi

    echo ::set-output name=promtool_output::"${full_output}"
    exit ${check_exit_code}
}
