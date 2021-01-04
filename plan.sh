#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color

export ARM_CLIENT_ID=$(CLIENT_ID)
export ARM_CLIENT_SECRET=$(CLIENT_SECRET)
export ARM_SUBSCRIPTION_ID=$(SUBSCRIPTION_ID)
export ARM_TENANT_ID=$(TENANT_ID)

base_dir=$(pwd)
last_commit=$(git rev-parse HEAD)
current_branch=$(git branch --contains ${last_commit})

# Get new files or changed in the current branch
file_changed=$(git diff --diff-filter=AM --name-only ${current_banch}..origin/master | grep terragrunt.hcl)

# task output status code
output_status_code=0

for item in ${file_changed}
do
    cd ${base_dir}
    wdir=$(dirname $item)

    cd ${wdir}
    terragrunt plan

    # if plan fails and output_status_code is 0
    # set output_status_code to 1 (error)
    if [[ $? -ne 0 ]]; then
    echo -e "${RED}${wdir} plan failed${NC}"
    if [[ ${output_status_code} -eq 0 ]]; then
        output_status_code=1
    fi
    fi
done

# get file deleted in the current branch.
file_deleted=$(git diff --diff-filter=D --name-only origin/master | grep terragrunt.hcl)
for item in ${file_deleted}
do
    echo "Deleted file: ${item}."
    echo "TODO: Run terragrung destroy"
done

exit ${output_status_code}
