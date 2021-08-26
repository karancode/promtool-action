#!/bin/bash

function promtool_check {

    # gather check promtool output
    echo "check: info: promtool check for ${prom_check_files}."
    echo "test the cmd:${prom_check_subcommand}"

    # NOTE(arthurb): If you use the pull_request.paths feature, the grep here is unnecessary
    set -o noglob
    if [[ ${prom_check_subcommand} == *"check"* ]]; then
      check_files="$(git diff HEAD^ --name-only | grep "$(dirname "${prom_check_files}")")"
    fi

    if [[ ${prom_check_subcommand} == *"test"* ]]; then
      check_files="${prom_check_files}"
    fi
    set +o noglob

    full_output=""
    for c in $check_files; do

      echo "testing file ${c}"
      if [[ ${prom_check_subcommand} == *"check"* ]]; then
        check_output="$(promtool check "${prom_check_subcommand}" <(oq -i yaml '.spec' "${c}"))"
      fi

      if [[ ${prom_check_subcommand} == *"test"* ]]; then
        #target_file=(oq -i yaml '.rule_files' ${c}) | xargs -I{} basename {}
        full_path_target_file=$(oq -c -i yaml '.rule_files' "test-eth2.yaml")
        target_file=${full_path_target_file#"[\"../"}
        target_file=${target_file%"\"]"}
        echo "target file -> ${target_file}"
        echo "$(oq -i yaml '.spec' ${target_file})" > ${c}
        cat ${c}

        check_output="$(promtool "${prom_check_subcommand}" rules ${c})"
      fi

      check_exit_code=${?}
      echo "testing output ${check_output}"
      full_output="${c}:\n${check_output}\n${full_output}"

      if [[ ${prom_check_subcommand} == *"check"* ]]; then
        # no rules round - failure
        if [[ ${check_output} == *" 0 rules found"* ]]; then
            check_comment_status="Failed"
            echo "check: error: failed to execute \`promtool ${prom_check_subcommand}\` for ${c}."
            echo "${check_output}"
            check_exit_code=1
            echo
            break
        fi
      fi

      # exit code 0 - success
      if [ ${check_exit_code} -eq 0 ];then
          check_comment_status="Success"
          echo "check: info: successfully executed \`promtool ${prom_check_subcommand}\` for ${c}."
          echo "${check_output}"
          echo
      fi

      # exit code !0 - failure
      # NOTE(arthurb): This fast fails, which isn't ideal, but good enough for now
      if [ ${check_exit_code} -ne 0 ]; then
          check_comment_status="Failed"
          echo "check: error: failed to execute \`promtool ${prom_check_subcommand}\` for ${c}."
          echo "${check_output}"
          echo
          break
      fi
    done

    # comment
    if [ "${GITHUB_EVENT_NAME}" == "pull_request" ] && [ "${prom_comment}" == "1" ]; then
        check_comment_wrapper="#### \`promtool ${prom_check_subcommand}\` ${check_comment_status}
\`\`\`shell
$(echo -e "${full_output}")
\`\`\`

* Workflow: \`${GITHUB_WORKFLOW}\`
* Action: \`${GITHUB_ACTION}\`
* Check Files: \`$(echo -e "${check_files}")\`"

        echo "check: info: creating json"
        check_payload=$(echo "${check_comment_wrapper}" | jq -R --slurp '{body: .}')
        check_comment_url=$(jq -r .pull_request.comments_url "${GITHUB_EVENT_PATH}")
        echo "check: info: commenting on the pull request"
        echo "${check_payload}" | curl -s -S -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" --header "Content-Type: application/json" --data @- "${check_comment_url}" > /dev/null
    fi

    echo ::set-output name=promtool_output::"${full_output}"
    exit ${check_exit_code}
}
