#!/bin/bash
set -eo pipefail

export IS_KUBECTL_ACTION_BASE=1
if [ -n "${INPUT_DEBUG}" ] || [ -n "${RUNNER_DEBUG}" ]; then
    export IS_DEBUG=1
fi

# Logging function
# log [level] [msg] [msg]
log() {
    local log_level="${1}"
    shift
    if [ "${log_level}" == "info" ]; then
        echo -e "${*}"
    else
        echo -e "${*}" | sed "s/^/::${log_level}:: /g"
    fi
}

# Prepare kubeconfig
if [ -n "${INPUT_CONFIG}" ]; then
    log info "Writing kube config."
    if [[ "${INPUT_CONFIG}" =~ ^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$ ]]; then
        log debug "Assuming provided kube config is encoded in base64."
        echo "${INPUT_CONFIG}" | base64 -d > "${KUBECONFIG}"
    else
        log debug "Assuming provided kube config is in plain text:"
        echo "${INPUT_CONFIG}" > "${KUBECONFIG}"
        
    fi
elif [ -n "${INPUT_EKS_CLUSTER}" ]; then
    log info "Getting kube config for cluster ${INPUT_EKS_CLUSTER}"
    if [ -n "${INPUT_EKS_ROLE_ARN}" ]; then
        log debug "$(aws eks update-kubeconfig --name "${INPUT_EKS_CLUSTER}" --role-arn "${INPUT_EKS_ROLE_ARN}")"
    else
        log debug "$(aws eks update-kubeconfig --name "${INPUT_EKS_CLUSTER}")"
    fi
else
    echo "::error:: Either config or eks_cluster must be specified."
    exit 2
fi

if [ -n "${INPUT_CONTEXT}" ]; then
    log info "Setting kubectl context to ${INPUT_CONTEXT}"
    kubectl config set-context "${INPUT_CONTEXT}"
fi
log debug "Current kubectl context: $(kubectl config current-context)"

if [ "$(ls -A /usr/local/bin/docker-entrypoint.d/)" ]; then
    # shellcheck disable=SC1090
    source /usr/local/bin/docker-entrypoint.d/*
fi
