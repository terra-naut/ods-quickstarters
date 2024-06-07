#!/usr/bin/env bash
#
# Author: Erhard Wais
#         erhard.wais@boehringer-ingelheim.com
#
# This script does some cleaning activities regarding statefiles during
# usage with kitchen and/or local deployments

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace


function cleanfixturestate() {
  rm -rf .kitchen/
	rm -rf ./test/fixtures/default//terraform.tfstate.d/
  rm -rf ./test/fixtures/default/.terraform/
	rm -f  ./test/fixtures/default/.terraform.lock.hcl
}

function cleanlocalstate() {
  rm -rf .terraform/
	rm -f .terraform.lock.hcl
}

function main() {
  if [ "$1" == "fixture" ]; then
    cleanfixturestate
  elif [ "$1" == "root" ]; then
    # clean local stateinformation assuming using an s3 bucket as backend
    cleanlocalstate
  else
    echo "Usage: cleanstate fixture|root"
    exit 1
  fi
}

main $1
