#!/bin/bash
# shellcheck disable=SC2034
set -eo pipefail

# This ninja function "simplifies" input parsing in GHA context.
# It takes in a list of inputs, and as a result sets the value of the input
# whether the input was provided using an environment variable (SOME_VAR),
# or using GHA with statement (INPUT_SOME_VAR).
#   $ export INPUT_VAR_ONE=value-one # Passed from GHA with
#   $ export VAR_TWO=value-two       # typical env var
#   $ get_inputs var_one var_two
#   $ echo $var_one
#   value-one
#   $ echo $var_two
#   value-two
# GHA with statement takes precedence over env vars.
get_inputs() {
    local input
    # shellcheck disable=SC2048
    for input in ${*}; do
        local env_var="${input^^}"
        local with_var="INPUT_${input^^}"
        eval "${input}"="\"${!with_var:-${!env_var}}\""
    done
}

# Logging function
# log [level] [msg]
log() {
    local log_level="${1}"
    shift
    if [ "${log_level}" == "info" ]; then
        echo -e "${*}"
    else
        echo -e "${*}" | sed "s/^/::${log_level}:: /g"
    fi
}


get_inputs DEBUG CONFIG EKS_CLUSTER EKS_ROLE_ARN CONTEXT NAMESPACE RUN
IS_KUBECTL_ACTION_BASE=1
if [ -n "${DEBUG}" ] || [ -n "${RUNNER_DEBUG}" ]; then
    export IS_DEBUG=1
fi


# Prepare kubeconfig
if [ -n "${CONFIG}" ]; then
    log info "Writing kube config to ${KUBECONFIG}."
    if [[ "${CONFIG}" =~ ^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$ ]]; then
        log debug "Assuming provided kube config is encoded in base64."
        echo "${CONFIG}" | base64 -d > "${KUBECONFIG}"
    else
        log debug "Assuming provided kube config is in plain text."
        echo "${CONFIG}" > "${KUBECONFIG}"
    fi
elif [ -n "${EKS_CLUSTER}" ]; then
    if [ -n "${EKS_ROLE_ARN}" ]; then
        log info "Getting kube config for cluster ${EKS_CLUSTER} using role ${EKS_ROLE_ARN}"
        log debug "$(aws eks update-kubeconfig --name "${EKS_CLUSTER}" --role-arn "${EKS_ROLE_ARN}")"
    else
        log info "Getting kube config for cluster ${EKS_CLUSTER}"
        log debug "$(aws eks update-kubeconfig --name "${EKS_CLUSTER}")"
    fi
else
    log error "Either config or eks_cluster must be specified."
    exit 2
fi
log debug "${KUBECONFIG} contents:"
log debug "$(cat "${KUBECONFIG}")"

if [ -n "${CONTEXT}" ]; then
    log info "Setting kubectl context to ${CONTEXT}"
    kubectl config use-context "${CONTEXT}"
fi
current_context="$(kubectl config current-context)"
log debug "Current kubectl context: ${current_context}"

if [ -n "${NAMESPACE}" ]; then
    log info "Setting namespace to ${NAMESPACE}"
    kubectl config set-context --current --namespace "${NAMESPACE}"
fi
current_namespace="$(kubectl config view --minify -o jsonpath='{..namespace}')"
log debug "Current kubectl namespace: ${current_namespace}"

echo "${RUN}" | awk 'NF' | while read -r line; do
  log debug "Running ${line}"
  eval "${line}"
done

if [ "$(ls -A /usr/local/bin/kubectl-action.d/)" ]; then
    for file in /usr/local/bin/kubectl-action.d/*; do
        # shellcheck source=/dev/null
        source "${file}"
    done
fi
