#!/usr/bin/env bash
set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

cp "$repository_dir/update-prior.sh" "$test_root/update-prior.sh"
mkdir -p "$test_root/packages/releases" "$test_root/bin" "$test_root/fixtures"

historical_url="https://swiftpointdrivers.blob.core.windows.net/pro/public/linux/Swiftpoint%20X1%20Control%20Panel%202.0.0.1-abcdef.tar.xz"
printf '<a href="%s">Historical archive</a>\n' "$historical_url" >"$test_root/fixtures/page"

bash_path="$(command -v bash)"
cat >"$test_root/bin/curl" <<EOF
#!$bash_path
cat "\$FIXTURES/page"
EOF

cat >"$test_root/bin/nix" <<EOF
#!$bash_path
printf '%s\n' '{"hash":"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="}'
EOF

cat >"$test_root/bin/nixfmt" <<EOF
#!$bash_path
exit 0
EOF

chmod +x "$test_root/bin/curl" "$test_root/bin/nix" "$test_root/bin/nixfmt"
test_path="$test_root/bin:$PATH"

run_update() {
	env PATH="$test_path" FIXTURES="$test_root/fixtures" bash "$test_root/update-prior.sh" "$@"
}

run_update 2.0.0.1
manifest="$test_root/packages/releases/2.0.0.1.nix"
grep -qF 'channel = "historical";' "$manifest"
grep -qF "$historical_url" "$manifest"
if grep -q firmware "$manifest"; then
	echo "Historical manifest unexpectedly contains firmware metadata" >&2
	exit 1
fi

cp "$manifest" "$test_root/manifest.before"
run_update 2.0.0.1
cmp "$test_root/manifest.before" "$manifest"

if run_update 1.0.0.0; then
	echo "Historical updater unexpectedly accepted a missing version" >&2
	exit 1
fi
if run_update invalid; then
	echo "Historical updater unexpectedly accepted an invalid version" >&2
	exit 1
fi

echo "Passed: historical discovery, immutable manifests, missing versions, and invalid versions"
