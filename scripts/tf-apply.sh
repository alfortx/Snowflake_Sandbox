#!/bin/bash
set -euo pipefail
set -a && source "$(dirname "$0")/../.env" && set +a
terraform -chdir=terraform apply -auto-approve
