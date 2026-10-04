#!/usr/bin/env bash
set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

cp "$repository_dir/update.sh" "$test_root/update.sh"
mkdir -p "$test_root/packages/releases" "$test_root/bin" "$test_root/fixtures"
cat >"$test_root/packages/default.nix" <<'EOF'
  currentStableVersion = "0.0.0.0";
  currentBetaVersion = "0.0.0.0";
EOF

public_url="https://drivers.swiftpoint.com/pro/public/linux/Swiftpoint X1 Control Panel 3.1.3.1-abcdef.tar.xz"
beta_url="https://drivers.swiftpoint.com/pro/beta/linux/Swiftpoint X1 Control Panel 3.1.3.39-abcdef.tar.xz"
public_manifest_url="${public_url// /%20}"
beta_manifest_url="${beta_url// /%20}"

printf '{"version":"3.1.3.1","url":"%s"}\n' "$public_url" >"$test_root/fixtures/public"
printf '{"version":"3.1.3.39","url":"%s"}\n' "$beta_url" >"$test_root/fixtures/beta"

bash_path="$(command -v bash)"
cat >"$test_root/bin/curl" <<EOF
#!$bash_path
case "\${*: -1}" in
	*/public/linux/X1Driver.json) cat "\$FIXTURES/public" ;;
	*/beta/linux/X1Driver.json) cat "\$FIXTURES/beta" ;;
	*) exit 22 ;;
esac
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
	env PATH="$test_path" FIXTURES="$test_root/fixtures" bash "$test_root/update.sh"
}

run_update
grep -qF 'currentStableVersion = "3.1.3.1"' "$test_root/packages/default.nix"
grep -qF 'currentBetaVersion = "3.1.3.39"' "$test_root/packages/default.nix"
grep -qF "$public_manifest_url" "$test_root/packages/releases/3.1.3.1.nix"
grep -qF "$beta_manifest_url" "$test_root/packages/releases/3.1.3.39.nix"
if grep -Rq firmware "$test_root/packages/releases"; then
	echo "Release manifests unexpectedly contain firmware metadata" >&2
	exit 1
fi

cp -R "$test_root/packages" "$test_root/packages.before"
run_update
diff -r "$test_root/packages.before" "$test_root/packages"

printf '%s\n' '{"version":"3.1.3.1","url":"https://example.com/archive.tar.xz"}' >"$test_root/fixtures/public"
if run_update; then
	echo "Updater unexpectedly accepted an invalid archive URL" >&2
	exit 1
fi
diff -r "$test_root/packages.before" "$test_root/packages"

printf '%s\n' '{"version":"3.1.3.1"}' >"$test_root/fixtures/public"
if run_update; then
	echo "Updater unexpectedly accepted a feed without a URL" >&2
	exit 1
fi
diff -r "$test_root/packages.before" "$test_root/packages"

printf '%s\n' 'not JSON' >"$test_root/fixtures/public"
if run_update; then
	echo "Updater unexpectedly accepted malformed JSON" >&2
	exit 1
fi
diff -r "$test_root/packages.before" "$test_root/packages"

echo "Passed: feed discovery, URL normalization, immutable manifests, idempotence, and invalid feeds"
