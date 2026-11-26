#!/usr/bin/env bash
# publish.sh PACKAGE copies PACKAGE/PKGBUILD and PACKAGE/.SRCINFO of this checkout into a clone of the package's AUR
# repository, shows the change and commits it. It does not push: the maintainer reviews, then runs the push it prints.
# The clone is kept in ${AUR_CLONES:-~/.cache/aur-clones}.
set -euo pipefail

pkg=$1
here=$(cd "$(dirname "$0")/.." && pwd)
[[ -f $here/$pkg/PKGBUILD && -f $here/$pkg/.SRCINFO ]] || { echo "no $pkg/PKGBUILD and $pkg/.SRCINFO" >&2; exit 1; }
[[ -z $(git -C "$here" status --porcelain -- "$pkg") ]] || { echo "$pkg has changes that are not committed" >&2; exit 1; }

# .SRCINFO must be what makepkg writes for this PKGBUILD.
diff -u "$here/$pkg/.SRCINFO" <(cd "$here/$pkg" && makepkg --printsrcinfo) || { echo "$pkg/.SRCINFO is stale" >&2; exit 1; }

clone=${AUR_CLONES:-$HOME/.cache/aur-clones}/$pkg
if [[ -d $clone/.git ]]; then
	git -C "$clone" pull -q --ff-only
else
	git clone -q "ssh://aur@aur.archlinux.org/$pkg.git" "$clone"
fi

cp "$here/$pkg/PKGBUILD" "$here/$pkg/.SRCINFO" "$clone/"
if [[ -z $(git -C "$clone" status --porcelain) ]]; then
	if [[ -n $(git -C "$clone" log --oneline '@{u}..' 2>/dev/null) ]]; then
		echo "$pkg is committed but not pushed. Push it with: git -C '$clone' push"
	else
		echo "the AUR has this $pkg already"
	fi
	exit 0
fi
git -C "$clone" add PKGBUILD .SRCINFO
git -C "$clone" --no-pager diff --cached
version=$(sed -n 's/^pkgver=//p' "$clone/PKGBUILD")-$(sed -n 's/^pkgrel=//p' "$clone/PKGBUILD")
git -C "$clone" commit -qm "$version"
echo
echo "Committed $pkg $version. Push it with: git -C '$clone' push"
