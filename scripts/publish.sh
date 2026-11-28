#!/usr/bin/env bash
# publish.sh PACKAGE copies PACKAGE/PKGBUILD and PACKAGE/.SRCINFO of this checkout into a clone of the package's AUR
# repository, shows the change and commits it. It does not push: the maintainer reviews, then runs the push it prints.
# The clone is kept in ${AUR_CLONES:-~/.cache/aur-clones}.
set -euo pipefail

pkg=${1:?usage: scripts/publish.sh PACKAGE, such as strait-bin}
here=$(cd "$(dirname "$0")/.." && pwd)
[[ -f $here/$pkg/PKGBUILD && -f $here/$pkg/.SRCINFO ]] || { echo "no $pkg/PKGBUILD and $pkg/.SRCINFO" >&2; exit 1; }
[[ -z $(git -C "$here" status --porcelain -- "$pkg") ]] || { echo "$pkg has changes that are not committed" >&2; exit 1; }

# .SRCINFO must be what makepkg writes for this PKGBUILD.
diff -u "$here/$pkg/.SRCINFO" <(cd "$here/$pkg" && makepkg --printsrcinfo) || { echo "$pkg/.SRCINFO is stale" >&2; exit 1; }

# The AUR takes pushes to master only. A new package's repository is empty: master starts there.
clone=${AUR_CLONES:-$HOME/.cache/aur-clones}/$pkg
[[ -d $clone/.git ]] || git clone -q "ssh://aur@aur.archlinux.org/$pkg.git" "$clone" 2>/dev/null
git -C "$clone" fetch -q origin
if git -C "$clone" rev-parse -q --verify origin/master >/dev/null; then
	git -C "$clone" checkout -q -B master
	git -C "$clone" merge -q --ff-only origin/master
	upstream=origin/master
else
	git -C "$clone" symbolic-ref HEAD refs/heads/master
	upstream=
fi
push="git -C '$clone' push origin master"

cp "$here/$pkg/PKGBUILD" "$here/$pkg/.SRCINFO" "$clone/"
if [[ -z $(git -C "$clone" status --porcelain) ]]; then
	if [[ -n $(git -C "$clone" log --oneline ${upstream:+"$upstream.."}HEAD 2>/dev/null) ]]; then
		echo "$pkg is committed but not pushed. Push it with: $push"
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
echo "Committed $pkg $version. Push it with: $push"
