#!/bin/bash
set -euo pipefail

# Run Redpanda 3-node cluster tests
# Usage: ./run-tests.sh [install_dir]

INSTALL_DIR="${1:-$HOME/redpanda}"
BROKERS="${REDPANDA_BROKERS:-127.0.0.1:19092}"
TEST_TOPIC="${TEST_TOPIC:-test-topic}"
MESSAGE_COUNT="${MESSAGE_COUNT:-10}"

RPK_BIN="$INSTALL_DIR/opt/redpanda/libexec/rpk"

echo "=== Running Redpanda cluster tests ==="
echo "Brokers: $BROKERS"
echo "Test topic: $TEST_TOPIC"
echo "Message count: $MESSAGE_COUNT"
echo ""

# Test 1: Create test topic
echo "--- Test: Create topic ---"
"$RPK_BIN" topic create "$TEST_TOPIC" --partitions 3 -X brokers="$BROKERS"
"$RPK_BIN" topic list -X brokers="$BROKERS"
echo ""

# Test 2: Produce test messages
echo "--- Test: Produce messages ---"
for i in $(seq 1 "$MESSAGE_COUNT"); do
    echo "message-$i" | "$RPK_BIN" topic produce "$TEST_TOPIC" -X brokers="$BROKERS"
done
echo "Produced $MESSAGE_COUNT messages"
echo ""

# Test 3: Consume and verify messages
echo "--- Test: Consume and verify messages ---"
messages=$("$RPK_BIN" topic consume "$TEST_TOPIC" --num "$MESSAGE_COUNT" -X brokers="$BROKERS" -f '%v\n')
echo "Consumed messages:"
echo "$messages"

count=$(echo "$messages" | grep -c "message-" || true)
echo "Message count: $count"

if [ "$count" -ne "$MESSAGE_COUNT" ]; then
    echo "ERROR: Expected $MESSAGE_COUNT messages, got $count"
    exit 1
fi
echo "All messages verified successfully"
echo ""

# Test 4: Topic describe
echo "--- Test: Topic describe ---"
"$RPK_BIN" topic describe "$TEST_TOPIC" -X brokers="$BROKERS"
echo ""

echo "=== All tests passed! ==="
