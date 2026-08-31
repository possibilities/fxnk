#!/bin/bash

# Shared by the producer and consumer of an exact-SHA local gate receipt.
fxnk_gate_contract_digest() {
    local contract_root="$1" manifest="$2" contract_file
    for contract_file in \
        "$contract_root/scripts/gate-contract.sh" \
        "$contract_root/scripts/local-gate.sh" \
        "$contract_root/scripts/classify-quarantine.py" \
        "$contract_root/tests/local-gate/fixtures/model-catalog-server.ts" \
        "$manifest"; do
        shasum -a 256 "$contract_file" | awk '{print $1}'
    done | shasum -a 256 | awk '{print $1}'
}
