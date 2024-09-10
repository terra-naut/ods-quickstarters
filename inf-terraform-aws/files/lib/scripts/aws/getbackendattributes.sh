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
  local backend_prefix=""

  local environment
  local project_name
  local component_name

  # get AWS account ID
  local account_id=$(aws sts get-caller-identity --query 'Account' --output text)

  TF_BACKEND_S3KEY=${TF_BACKEND_S3KEY:-}
  if [[ -n "$TF_BACKEND_S3KEY" ]]; then

    # Ugly but we need to cut TF_BACKEND_S3KEY into pieces 
    # to get env, project & component
    # 047562615754/awstest/awsn/dev
    # xxxxxxx-terraform-state-bucket/xxxxxxx/bear-awscomp-dev-terraform-state
    environment=$(echo ${TF_BACKEND_S3KEY} | cut -d'/' -f4)
    project_name=$(echo ${TF_BACKEND_S3KEY} | cut -d'/' -f2)
    component_name=$(echo ${TF_BACKEND_S3KEY} | cut -d'/' -f3)    
  else
    environment="dev"
    branch_name=$(git rev-parse --abbrev-ref HEAD)

    # no prefix when on master
    # TODO: check for release branches also
    if [[ "$branch_name" != master* ]]; then
      backend_prefix="-${branch_name//\//-}"
    fi
    local repo_name=$(basename $(git rev-parse --show-toplevel))

    project_name=$(echo $repo_name | cut -d'-' -f1)
    component_name=$(echo $repo_name | cut -d'-' -f2)
  fi

  # generate backend attributes
  local backend_table="${account_id}${backend_prefix}-terraform-state-lock-table"
  local backend_bucket="${account_id}-terraform-state-bucket"
  local backend_key="${account_id}/${project_name}-${component_name}-${environment}${backend_prefix}-terraform-state"

  # Return String Array
  echo -e "$backend_table $backend_bucket $backend_key"
}

# check if called via jenkins
main
