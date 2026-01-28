#!/bin/bash
#
# generate-collections.sh
#
# Generates Hyperledger Fabric private data collections configuration for
# bilateral data sharing between N organizations.
#
# For N orgs, generates N*(N-1)/2 bilateral collection pairs.
# Collection names use alphabetical sorting (smaller org first) so both
# orgs in a pair resolve to the same collection name.
#
# Usage:
#   ./generate-collections.sh Org1 Org2 Org3 Org4
#   ./generate-collections.sh -o output.json Org1 Org2 Org3
#   ORGS="Org1 Org2 Org3" ./generate-collections.sh
#
# Options:
#   -o, --output FILE    Write output to FILE instead of stdout
#   -h, --help           Show this help message
#   --required-peers N   Set requiredPeerCount (default: 1)
#   --max-peers N        Set maxPeerCount (default: 2)
#   --block-to-live N    Set blockToLive (default: 0)
#
# Environment Variables:
#   ORGS                 Space-separated list of org names (used if no args)
#   REQUIRED_PEER_COUNT  Override requiredPeerCount (default: 1)
#   MAX_PEER_COUNT       Override maxPeerCount (default: 2)
#   BLOCK_TO_LIVE        Override blockToLive (default: 0)
#
# Copyright 2016-2026 Milligan Partners LLC
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# Default configuration (suitable for local development)
REQUIRED_PEER_COUNT="${REQUIRED_PEER_COUNT:-1}"
MAX_PEER_COUNT="${MAX_PEER_COUNT:-2}"
BLOCK_TO_LIVE="${BLOCK_TO_LIVE:-0}"
OUTPUT_FILE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] ORG1 ORG2 [ORG3 ...]

Generate Hyperledger Fabric private data collections configuration for
bilateral data sharing between organizations.

Options:
  -o, --output FILE      Write output to FILE instead of stdout
  -h, --help             Show this help message
  --required-peers N     Set requiredPeerCount (default: $REQUIRED_PEER_COUNT)
  --max-peers N          Set maxPeerCount (default: $MAX_PEER_COUNT)
  --block-to-live N      Set blockToLive (default: $BLOCK_TO_LIVE)

Environment Variables:
  ORGS                   Space-separated list of org names (used if no args)
  REQUIRED_PEER_COUNT    Override requiredPeerCount
  MAX_PEER_COUNT         Override maxPeerCount
  BLOCK_TO_LIVE          Override blockToLive

Examples:
  $(basename "$0") Org1 Org2 Org3 Org4
  $(basename "$0") -o collections_config.json Org1 Org2 Org3
  ORGS="Org1 Org2 Org3" $(basename "$0")
  $(basename "$0") --required-peers 2 --max-peers 4 Org1 Org2 Org3

For N orgs, generates N*(N-1)/2 bilateral collection pairs.
Collection names use alphabetical sorting (smaller org first).
EOF
}

# Parse command line arguments
ORGS_ARRAY=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --required-peers)
            REQUIRED_PEER_COUNT="$2"
            shift 2
            ;;
        --max-peers)
            MAX_PEER_COUNT="$2"
            shift 2
            ;;
        --block-to-live)
            BLOCK_TO_LIVE="$2"
            shift 2
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            ORGS_ARRAY+=("$1")
            shift
            ;;
    esac
done

# If no orgs provided via args, try ORGS environment variable
if [[ ${#ORGS_ARRAY[@]} -eq 0 ]] && [[ -n "${ORGS:-}" ]]; then
    read -ra ORGS_ARRAY <<< "$ORGS"
fi

# Validate we have at least 2 orgs
if [[ ${#ORGS_ARRAY[@]} -lt 2 ]]; then
    echo "Error: At least 2 organizations are required" >&2
    usage >&2
    exit 1
fi

# Sort orgs alphabetically for consistent ordering
IFS=$'\n' SORTED_ORGS=($(sort <<<"${ORGS_ARRAY[*]}")); unset IFS

# Generate the JSON collections configuration
generate_collections() {
    local first=true
    echo "["

    # Generate all N*(N-1)/2 bilateral pairs
    for ((i=0; i<${#SORTED_ORGS[@]}; i++)); do
        for ((j=i+1; j<${#SORTED_ORGS[@]}; j++)); do
            local org1="${SORTED_ORGS[$i]}"
            local org2="${SORTED_ORGS[$j]}"

            # Add comma before all entries except the first
            if [[ "$first" == "true" ]]; then
                first=false
            else
                printf ",\n"
            fi

            # Generate the collection entry (no trailing newline on closing brace)
            printf '  {\n'
            printf '    "name": "charges_%s_%s",\n' "$org1" "$org2"
            printf '    "policy": "OR('\''%sMSP.member'\'', '\''%sMSP.member'\'')",\n' "$org1" "$org2"
            printf '    "requiredPeerCount": %s,\n' "$REQUIRED_PEER_COUNT"
            printf '    "maxPeerCount": %s,\n' "$MAX_PEER_COUNT"
            printf '    "blockToLive": %s,\n' "$BLOCK_TO_LIVE"
            printf '    "memberOnlyRead": true,\n'
            printf '    "memberOnlyWrite": true\n'
            printf '  }'
        done
    done

    printf '\n]\n'
}

# Output the configuration
if [[ -n "$OUTPUT_FILE" ]]; then
    generate_collections > "$OUTPUT_FILE"
    echo "Generated collections config with ${#SORTED_ORGS[@]} orgs -> $OUTPUT_FILE" >&2
    echo "Total collections: $(( ${#SORTED_ORGS[@]} * (${#SORTED_ORGS[@]} - 1) / 2 ))" >&2
else
    generate_collections
fi
