#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <test-case>" >&2
    exit 2
fi

readonly TEST_CASE="$1"
readonly REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly ENV_FILE="${REPO_DIR}/.env"

: "${SLURM_JOB_ID:?SLURM_JOB_ID is not defined; run this script inside a Slurm job}"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Missing ${ENV_FILE}; copy .env-template to .env and set TEST_DATA_DIR" >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${TEST_DATA_DIR:?Set TEST_DATA_DIR in .env}"

readonly TEST_DIR="/scratch/${SLURM_JOB_ID}/${TEST_CASE}"
readonly OUTPUT_DIR="${TEST_DIR}/output"

mkdir -p "${OUTPUT_DIR}"
cd "${TEST_DIR}"

export NFT_INIT="${REPO_DIR}"
export NFT_PIPELINE="${REPO_DIR}"
export NFT_TESTDIR="${REPO_DIR}"
export NFT_OUTPUT="${OUTPUT_DIR}"
export NFT_TEMP="${TEST_DIR}"

echo "Test case: ${TEST_CASE}"
echo "Output and work directory: ${TEST_DIR}"

nftest run -c "${REPO_DIR}/nftest.yml" "${TEST_CASE}"
