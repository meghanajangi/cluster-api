#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "${REPO_ROOT}" || exit 1

# shellcheck source=./scripts/ci-e2e-lib.sh
source "${REPO_ROOT}/scripts/ci-e2e-lib.sh"

# shellcheck source=./hack/ensure-go.sh
source "${REPO_ROOT}/hack/ensure-go.sh"
# shellcheck source=./hack/ensure-kubectl.sh
source "${REPO_ROOT}/hack/ensure-kubectl.sh"
# shellcheck source=./hack/ensure-kustomize.sh
source "${REPO_ROOT}/hack/ensure-kustomize.sh"
# shellcheck source=./hack/ensure-kind.sh
source "${REPO_ROOT}/hack/ensure-kind.sh"

# Make sure the tools binaries are on the path.
export PATH="${REPO_ROOT}/hack/tools/bin:${PATH}"

# Builds CAPI (and CAPD) images.
capi:buildDockerImages

# Prepare kindest/node images for all the required Kubernetes version; this implies
# 1. Kubernetes version labels (e.g. latest) to the corresponding version numbers.
# 2. Pre-pulling the corresponding kindest/node image if available; if not, building the image locally.
# Following variables are currently checked (if defined):
# - KUBERNETES_VERSION
# - KUBERNETES_VERSION_UPGRADE_TO
# - KUBERNETES_VERSION_UPGRADE_FROM
k8s::prepareKindestImages

# pre-pull all the images that will be used in the e2e, thus making the actual test run
# less sensible to the network speed. This includes:
# - cert-manager images
kind:prepullAdditionalImages

# Configure e2e tests
export GINKGO_NODES=3
export GINKGO_NOCOLOR=true
export GINKGO_ARGS="--failFast" # Other ginkgo args that need to be appended to the command.
export E2E_CONF_FILE="${REPO_ROOT}/test/e2e/config/docker.yaml"
export ARTIFACTS="${ARTIFACTS:-${REPO_ROOT}/_artifacts}"
export SKIP_RESOURCE_CLEANUP=false
export USE_EXISTING_CLUSTER=false

# Run e2e tests
mkdir -p "$ARTIFACTS"
echo "+ run tests!"
make -C test/e2e/ run
