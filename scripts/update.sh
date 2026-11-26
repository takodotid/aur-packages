#!/usr/bin/env bash
# update.sh PACKAGE VERSION SHA256SUMS sets PACKAGE/PKGBUILD to that release: pkgver, pkgrel 1, and each architecture's
# sha256sums from the release's SHA256SUMS. .SRCINFO is written after, by makepkg --printsrcinfo.
set -euo pipefail

pkg=$1 version=$2 sums=$3
file=$pkg/PKGBUILD
[[ -f $file ]] || { echo "no $file" >&2; exit 1; }
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "$version is not a stable version" >&2; exit 1; }

current=$(sed -n 's/^pkgver=//p' "$file")
if [[ $current != "$version" ]]; then
	sed -i -e "s/^pkgver=.*/pkgver=$version/" -e 's/^pkgrel=.*/pkgrel=1/' "$file"
fi

for arch in x86_64 aarch64; do
	# The archive's name, as the PKGBUILD builds it from pkgver.
	name=$(bash -c 'source "$1" && basename "$(eval echo "\${source_$2[0]}")"' _ "$file" "$arch")
	sum=$(awk -v f="$name" '$2 == f { print $1 }' "$sums")
	[[ $sum =~ ^[0-9a-f]{64}$ ]] || { echo "SHA256SUMS has no $name" >&2; exit 1; }
	sed -i "s/^sha256sums_$arch=.*/sha256sums_$arch=('$sum')/" "$file"
done
