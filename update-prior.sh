#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq gnugrep coreutils nixfmt

set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
releases_dir="$repository_dir/packages/releases"
release_page="https://support.swiftpoint.com/portal/en/kb/articles/x1-control-panel-linux"

usage() {
	cat <<'EOF'
Usage: update-prior.sh VERSION

Add a historical release listed on Swiftpoint's support page without changing
the current stable or beta pointer.
EOF
}

if [[ "$#" != 1 ]]; then
	usage >&2
	exit 2
fi
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	usage
	exit 0
fi

version="$1"
if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
	echo "Invalid Swiftpoint version: $version" >&2
	exit 1
fi

manifest="$releases_dir/$version.nix"
if [[ -e "$manifest" ]]; then
	echo "Release manifest already exists: $manifest"
	exit 0
fi

page="$(curl -fsSL "$release_page")"
encoded_version="${version//./\.}"
url="$(grep -oE 'https://swiftpointdrivers[^"< ]+\.tar\.xz' <<<"$page" | grep -m1 -E "%20${encoded_version}-[0-9a-f]+\.tar\.xz$" || true)"
if [[ -z "$url" ]]; then
	echo "Swiftpoint Linux archive for $version was not found on $release_page" >&2
	exit 1
fi

echo "Fetching Swiftpoint X1 Control Panel $version" >&2
prefetch_result="$(nix store prefetch-file --json --name "swiftpoint-x1-control-panel-$version.tar.xz" "$url")"
hash="$(jq -er .hash <<<"$prefetch_result")"
temporary_manifest="$(mktemp "$releases_dir/.swiftpoint-release.XXXXXX")"
trap 'rm -f "$temporary_manifest"' EXIT

cat >"$temporary_manifest" <<EOF
{
  version = "$version";
  channel = "historical";

  source = {
    url = "$url";
    hash = "$hash";
  };
}
EOF

mv "$temporary_manifest" "$manifest"
trap - EXIT
nixfmt "$manifest"
echo "Added Swiftpoint X1 Control Panel $version without changing a pointer"
