#!/bin/bash

function parse_inputs {
    # inputs
    prom_version = '2.16.0'
    if [ "${INPUT_PROM_VERSION}" != "" ]; then
        prom_version = ${INPUT_PROM_VERSION}
    fi

    prom_check_subcommand = ""
    if [ "${INPUT_PROM_CHECK_SUBCOMMAND}" != "" ]; then
        prom_check_subcommand = ${INPUT_PROM_CHECK_SUBCOMMAND}
    fi

    prom_check_files = ""
    if [ "${INPUT_PROM_CHECK_FILES}" != "" ]; then
        prom_check_files = ${INPUT_PROM_CHECK_FILES}
    fi

    prom_comment = 0
    if [ "${INPUT_PROM_COMMENT}" == "1" ] || [ "${INPUT_PROM_COMMENT}" == "true"]; then
        prom_comment = 1
    fi
}

function install_promtool {
    url="https://github.com/prometheus/prometheus/releases/download/v${prom_version}/prometheus-${prom_version}.linux-amd64.tar.gz"

    echo "Downloading promtool version : v${prom_version}"
    wget ${url}
    if [ "${?}" -ne 0 ]; then
        echo "Failed to download promtool v${prom_version}."
        exit 1
    fi
    echo "Successfully downloaded promtool v${prom_version}."

    echo "Extracting promtool"
    tar -zxf prometheus-*.tar.gz --strip-components=1 -C /tmp
    if [ "${?}" -ne 0 ]; then
        echo "Failed to extract promtool."
        exit 1
    fi
    echo "Successfully extracted promtool."

    # cleanup
    mv /tmp/promtool /usr/bin/promtool 
    rm -rf /tmp/*
}

function main {

    scriptDir = $(dirname ${0})
    source ${scriptDir}/promtool_check.sh
    
    parse_inputs

    install_promtool

    promtool_check

}

main "${*}"