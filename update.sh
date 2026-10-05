#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils gnugrep gnused nixfmt

set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
releases_dir="$repository_dir/packages/releases"
default_file="$repository_dir/packages/default.nix"

usage() {
	cat <<'EOF'
Usage: update.sh

Synchronize and promote the latest stable and beta releases.
EOF
}

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
	*)
		usage >&2
		exit 2
		;;
esac

feed_version=""
feed_url=""
read_feed() {
	local channel="$1"
	local upstream_channel="$2"
	local json raw_url expected_prefix archive_suffix

	json="$(curl -fsSL "https://drivers.swiftpoint.com/pro/$upstream_channel/linux/X1Driver.json")"
	feed_version="$(jq -er '
      if type == "object" and (.version | type == "string")
      then .version
      else error("Missing string version")
      end
    ' <<<"$json")"
	raw_url="$(jq -er '
      if type == "object" and (.url | type == "string")
      then .url
      else error("Missing string URL")
      end
    ' <<<"$json")"

	if [[ ! "$feed_version" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
		echo "Invalid $channel version in Swiftpoint feed: $feed_version" >&2
		exit 1
	fi

	feed_url="${raw_url// /%20}"
	expected_prefix="https://drivers.swiftpoint.com/pro/$upstream_channel/linux/Swiftpoint%20X1%20Control%20Panel%20$feed_version-"
	archive_suffix="${feed_url#"$expected_prefix"}"
	if [[ "$archive_suffix" == "$feed_url" || ! "$archive_suffix" =~ ^[0-9a-f]+\.tar\.xz$ ]]; then
		echo "Invalid $channel archive URL in Swiftpoint feed: $raw_url" >&2
		exit 1
	fi
}

add_release() {
	local version="$1"
	local channel="$2"
	local url="$3"
	local channel_dir manifest prefetch_result hash temporary_manifest

	channel_dir="$releases_dir/$channel"
	manifest="$channel_dir/$version.nix"
	if [[ -e "$manifest" ]]; then
		echo "Release manifest already exists: $manifest"
		return
	fi

	mkdir -p "$channel_dir"
	echo "Fetching Swiftpoint X1 Control Panel $version" >&2
	prefetch_result="$(nix store prefetch-file --json --name "swiftpoint-x1-control-panel-$version.tar.xz" "$url")"
	hash="$(jq -er .hash <<<"$prefetch_result")"
	temporary_manifest="$(mktemp "$channel_dir/.swiftpoint-release.XXXXXX")"
	trap 'rm -f "$temporary_manifest"' RETURN

	cat >"$temporary_manifest" <<EOF
{
  version = "$version";

  source = {
    url = "$url";
    hash = "$hash";
  };
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

read_feed stable public
stable_version="$feed_version"
stable_url="$feed_url"

read_feed beta beta
beta_version="$feed_version"
beta_url="$feed_url"

add_release "$stable_version" stable "$stable_url"
add_release "$beta_version" beta "$beta_url"
promote currentStableVersion "$stable_version"
promote currentBetaVersion "$beta_version"
nixfmt "$default_file"

echo "Current stable: $stable_version"
echo "Current beta:   $beta_version"
