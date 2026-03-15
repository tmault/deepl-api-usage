#!/usr/bin/env bash

set -euo pipefail

SCRIPT_UNDER_TEST=${SCRIPT_UNDER_TEST:-/Users/tmault/dev/deepl-api-usage/bin/deepl}
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack=$1
  local needle=$2
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"$'\n'"actual: $haystack"
  fi
}

assert_equals() {
  local actual=$1
  local expected=$2
  if [[ "$actual" != "$expected" ]]; then
    fail "expected: $expected"$'\n'"actual: $actual"
  fi
}

FAKE_BIN="$TEST_ROOT/bin"
FAKE_HOME="$TEST_ROOT/home"
mkdir -p "$FAKE_BIN" "$FAKE_HOME"

cat >"$FAKE_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >"$TMP_CURL_ARGS_FILE"
if [[ -n "${MOCK_CURL_RESPONSE:-}" ]]; then
  printf '%s' "$MOCK_CURL_RESPONSE"
else
  printf '%s' '{"character_count":123,"character_limit":1000}'
fi
EOF
chmod +x "$FAKE_BIN/curl"

run_cli() {
  HOME="$FAKE_HOME" \
  PATH="$FAKE_BIN:/usr/bin:/bin:/opt/homebrew/bin" \
  "$SCRIPT_UNDER_TEST" "$@"
}

output=$(run_cli usage 2>&1) && status=$? || status=$?
assert_equals "$status" "1"
assert_contains "$output" "No DeepL API key found"

MOCK_CURL_RESPONSE='{"character_count":250,"character_limit":1000}'
export MOCK_CURL_RESPONSE
export TMP_CURL_ARGS_FILE="$TEST_ROOT/curl-args-env.txt"
output=$(DEEPL_API_KEY="env-key" run_cli usage)
assert_contains "$output" "Used: 250 / 1000 characters (25.00%)"
assert_contains "$output" "Remaining: 750"
curl_args=$(cat "$TMP_CURL_ARGS_FILE")
assert_contains "$curl_args" "DeepL-Auth-Key env-key"
assert_contains "$curl_args" "https://api-free.deepl.com/v2/usage"

output=$(run_cli auth set saved-key)
assert_contains "$output" "Saved API key"
config_file="$FAKE_HOME/.config/deepl/config"
test -f "$config_file" || fail "expected config file to be created"
config_contents=$(cat "$config_file")
assert_equals "$config_contents" "DEEPL_API_KEY=saved-key"

export TMP_CURL_ARGS_FILE="$TEST_ROOT/curl-args-config.txt"
output=$(run_cli usage)
assert_contains "$output" "Used: 250 / 1000 characters (25.00%)"
curl_args=$(cat "$TMP_CURL_ARGS_FILE")
assert_contains "$curl_args" "DeepL-Auth-Key saved-key"

output=$(run_cli auth show)
assert_contains "$output" "saved-key"

output=$(run_cli auth clear)
assert_contains "$output" "Removed saved API key"
test ! -f "$config_file" || fail "expected config file to be removed"

echo "PASS"
