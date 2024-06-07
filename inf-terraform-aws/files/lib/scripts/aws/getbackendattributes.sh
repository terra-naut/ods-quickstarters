#!/usr/bin/env bash
#
# Author: Erhard Wais
#         erhard.wais@boehringer-ingelheim.com
#
# This script does return terraform statefile attributes required to describe the location
# of a statefile when using S3 as backend.

# Assumtions:
# TF_BACKEND_S3KEY (provided by shared LIB)
# project name and component name are always part of the repository name

# needs to be resolved:
# - what about master and release branches
# - how to get current environment?

set -o errexit
set -o pipefail
set -o nounset

function main() {

  local branch_name
  local branch_hash
  local backend_prefix
  local environment

  # Check for AWS
  local account_id=$(aws sts get-caller-identity --query 'Account' --output text)

  # TODO: check if called from jenkins and set environment to the value stored in
  # TF_BACKEND_S3KEY usually is derived via shared library (Jenkins run)
  TF_BACKEND_S3KEY=${TF_BACKEND_S3KEY:-}
  if [[ -n "$TF_BACKEND_S3KEY" ]]; then
    environment="${TF_BACKEND_S3KEY##*/}"
  else
    environment="dev"
    branch_name=$(git rev-parse --abbrev-ref HEAD)
    # branch_hash=$(echo -n "$branch_name" | sha256sum | awk '{print substr($1,1,8)}')

    # no prefix when on master
    # TODO: check for release branches also
    if [[ "$branch_name" != master* ]]; then
      backend_prefix="-${branch_name//\//-}"
    else
      backend_prefix=""
    fi
  fi

  # parse project and component from repository name
  local repo_name=$(basename $(git rev-parse --show-toplevel))
  local project_name=$(echo $repo_name | cut -d'-' -f1)
  local component_name=$(echo $repo_name | cut -d'-' -f2)

  # generate backend attributes
  local backend_table="$account_id$backend_prefix-terraform-state-lock-table"
  local backend_bucket="$account_id-terraform-state-bucket"
  local backend_key="$account_id/$project_name-$component_name-$environment$backend_prefix/terraform-state"

  # Return String Array
  echo -e "$backend_table $backend_bucket $backend_key"
}

# check if called via jenkins
main
