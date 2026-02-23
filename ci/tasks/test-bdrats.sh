#!/bin/bash

set -euo 'pipefail'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
src_dir="${script_dir}/../../.."

BOSH_RELEASE_PATH="${PWD}/bosh-release/$(basename bosh-release/*.tgz)"
export BOSH_RELEASE_PATH

mkdir -p bbr-binary
export BBR_BINARY_PATH="${PWD}/bbr-binary/bbr"
cp bbr-cli-binary/bbr-[0-9]*-linux-amd64 "${BBR_BINARY_PATH}"
chmod +x "${BBR_BINARY_PATH}"

export BOSH_DEPLOYMENT_PATH="${src_dir}/bosh-deployment"

STEMCELL_PATH="${STEMCELL_PATH:-file://${PWD}/stemcell/$(basename stemcell/*.tgz)}"
STEMCELL_SHA1="${STEMCELL_SHA1:-$(sha1sum "${PWD}/stemcell/$(basename stemcell/*.tgz)" | awk '{print $1}')}"

cat > "${BOSH_DEPLOYMENT_PATH}/local-stemcell.yml" <<'OPSEOF'
- name: stemcell
  path: /resource_pools/name=vms/stemcell?
  type: replace
  value:
    url: ((local_stemcell_url))
    sha1: ((local_stemcell_sha1))
OPSEOF

# Retry start-bosh up to 3 times
MAX_ATTEMPTS=3
for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo "Starting BOSH (attempt $attempt/$MAX_ATTEMPTS)..."
  
  if bash start-bosh \
    -o bbr.yml \
    -o local-bosh-release-tarball.yml \
    -o hm/disable.yml \
    -v local_bosh_release="${BOSH_RELEASE_PATH}" \
    -v local_stemcell_url="${STEMCELL_PATH}" \
    -v local_stemcell_sha1="${STEMCELL_SHA1}"; then
    
    echo "BOSH started successfully, sourcing environment..."
    source /tmp/local-bosh/director/env
    break
  else
    EXIT_CODE=$?
    echo "BOSH start failed with exit code $EXIT_CODE on attempt $attempt"
    
    if [ $attempt -lt $MAX_ATTEMPTS ]; then
      echo "Retrying in 5 seconds..."
      sleep 5
    else
      echo "All $MAX_ATTEMPTS attempts failed"
      exit 1
    fi
  fi
done

source /tmp/local-bosh/director/env

BOSH_SSH_KEY="$(bosh int /tmp/local-bosh/director/creds.yml --path /jumpbox_ssh/private_key --json | jq .Blocks[0])"
BOSH_HOST="${BOSH_ENVIRONMENT}"

stemcell_os="ubuntu-jammy"
bosh_ca_cert_json_value="$(awk '{printf "%s\\n", $0}' "${BOSH_CA_CERT}")"

cat > integration-config.json <<EOF
{
  "bosh_host": "${BOSH_HOST}",
  "bosh_ssh_username": "jumpbox",
  "bosh_ssh_private_key": ${BOSH_SSH_KEY},
  "bosh_client": "${BOSH_CLIENT}",
  "bosh_client_secret": "${BOSH_CLIENT_SECRET}",
  "bosh_ca_cert": "${bosh_ca_cert_json_value}",
  "timeout_in_minutes": 30,
  "stemcell_src": "${STEMCELL_PATH}",
  "stemcell_os": "${stemcell_os}",
  "include_deployment_testcase": true,
  "include_truncate_db_blobstore_testcase": true
}
EOF

export INTEGRATION_CONFIG_PATH="${PWD}/integration-config.json"

./bosh-disaster-recovery-acceptance-tests/scripts/_run_acceptance_tests.sh
