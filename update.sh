#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq gnugrep coreutils gnused nixfmt

set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
releases_dir="$repository_dir/packages/releases"
default_file="$repository_dir/packages/default.nix"
release_page="https://support.swiftpoint.com/portal/en/kb/articles/x1-control-panel-linux"

usage() {
	cat <<'EOF'
Usage:
  update.sh                Synchronize and promote the latest stable and beta releases
  update.sh --add VERSION  Add a listed historical release without changing either pointer
EOF
}

requested_version=""
case "$#" in
	0) ;;
	1)
		if [[ "$1" == "-h" || "$1" == "--help" ]]; then
			usage
			exit 0
		fi
		usage >&2
		exit 2
		;;
	2)
		if [[ "$1" != "--add" ]]; then
			usage >&2
			exit 2
		fi
		requested_version="$2"
		;;
	*)
		usage >&2
		exit 2
		;;
esac

page="$(curl -fsSL "$release_page")"
page_text="$(sed -E 's/<[^>]+>/\n/g; s/&nbsp;/ /g; s/&amp;/\&/g' <<<"$page")"
latest_beta="$(grep -oE 'Beta Version [0-9]+(\.[0-9]+){3}' <<<"$page_text" | head -n1 | grep -oE '[0-9]+(\.[0-9]+){3}')"
latest_stable="$(grep -oE 'Stable(\(ish\))? Version [0-9]+(\.[0-9]+){3}' <<<"$page_text" | head -n1 | grep -oE '[0-9]+(\.[0-9]+){3}')"

validate_version() {
	local version="$1"
	if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
		echo "Invalid or undiscoverable Swiftpoint version: $version" >&2
		exit 1
	fi
}

add_release() {
	local version="$1"
	local channel="$2"
	local encoded_version url firmware_block z3_firmware receiver_firmware
	local manifest prefetch_result hash temporary_manifest firmware

	validate_version "$version"
	encoded_version="${version//./\.}"
	url="$(grep -oE 'https://swiftpointdrivers[^"< ]+\.tar\.xz' <<<"$page" | grep -m1 -E "%20${encoded_version}-[0-9a-f]+\.tar\.xz$")"

	if [[ -z "$url" ]]; then
		echo "Swiftpoint Linux archive for $version was not found on $release_page" >&2
		exit 1
	fi

	manifest="$releases_dir/$version.nix"
	if [[ -e "$manifest" ]]; then
		echo "Release manifest already exists: $manifest"
		return
	fi

	firmware_block="$(grep -A40 -m1 -E "(Beta|Stable(\(ish\))?) Version ${encoded_version}" <<<"$page_text" || true)"
	z3_firmware="$(grep -oE -m1 'Z3 Firmware V[0-9]+' <<<"$firmware_block" | grep -oE '[0-9]+' || true)"
	receiver_firmware="$(grep -oE -m1 'SwiftLink Receiver Firmware V[0-9]+' <<<"$firmware_block" | grep -oE '[0-9]+' || true)"

	echo "Fetching Swiftpoint X1 Control Panel $version" >&2
	prefetch_result="$(nix store prefetch-file --json --name "swiftpoint-x1-control-panel-$version.tar.xz" "$url")"
	hash="$(jq -er .hash <<<"$prefetch_result")"
	temporary_manifest="$(mktemp "$releases_dir/.swiftpoint-release.XXXXXX")"
	trap 'rm -f "$temporary_manifest"' RETURN

	if [[ -n "$z3_firmware" && -n "$receiver_firmware" ]]; then
		firmware="{
    z3 = $z3_firmware;
    receiver = $receiver_firmware;
  }"
	else
		firmware="null"
	fi

	cat >"$temporary_manifest" <<EOF
{
  version = "$version";
  channel = "$channel";

  source = {
    url = "$url";
    hash = "$hash";
  };

  firmware = $firmware;
}
EOF

	mv "$temporary_manifest" "$manifest"
	trap - RETURN
	nixfmt "$manifest"
	echo "Added Swiftpoint X1 Control Panel $version ($channel)"
}

promote() {
	local pointer="$1"
	local version="$2"
	sed -i -E "s|^  $pointer = \"[^\"]*\";|  $pointer = \"$version\";|" "$default_file"
	if ! grep -qxF "  $pointer = \"$version\";" "$default_file"; then
		echo "Failed to update $pointer in $default_file" >&2
		exit 1
	fi
}

if [[ -n "$requested_version" ]]; then
	channel="historical"
	if [[ "$requested_version" == "$latest_stable" ]]; then
		channel="stable"
	elif [[ "$requested_version" == "$latest_beta" ]]; then
		channel="beta"
	fi
	add_release "$requested_version" "$channel"
	echo "Swiftpoint X1 Control Panel $requested_version was added without changing a pointer"
	exit 0
fi

add_release "$latest_stable" stable
add_release "$latest_beta" beta
promote currentStableVersion "$latest_stable"
promote currentBetaVersion "$latest_beta"
nixfmt "$default_file"

echo "Current stable: $latest_stable"
echo "Current beta:   $latest_beta"
