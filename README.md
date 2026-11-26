# Tako's AUR packages

The PKGBUILDs of Tako's command-line tools on the [AUR](https://aur.archlinux.org), for Arch Linux on `x86_64` and `aarch64`.

| Package | Installs |
|---|---|
| [`strait-bin`](strait-bin/PKGBUILD) | [Strait](https://strait.tako.id): `strait`, `kubectl-strait` and `kubectl_complete-strait` as links to it, the man pages, and bash, zsh and fish completions |
| [`tack-bin`](tack-bin/PKGBUILD) | [Tack](https://tack.tako.id): `tack`, the man pages, the completions, and the CRD in `/usr/share/tack` |

Each package installs the binary of the project's GitHub release, checked against the release's `SHA256SUMS`.

## Updates

| Step | Who |
|---|---|
| The workflow `update` checks each hour for a new stable release. It verifies the attestation of the release's `SHA256SUMS`, moves the PKGBUILD to it, builds the package, runs `namcap`, and opens a pull request | GitHub Actions |
| Read the release notes for a new file, dependency or licence that the PKGBUILD must follow, then merge | a maintainer |
| `scripts/publish.sh PACKAGE` on an Arch host with the maintainer's AUR key: it checks `.SRCINFO`, commits the package in a clone of its AUR repository and shows the change. Then run the push it prints | a maintainer |

The AUR accepts automation only with a person's review ([AUR submission guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines#Rules_of_submission)), so no workflow holds an AUR key.

GitHub turns off a public repository's scheduled workflows after 60 days without activity. Run `update` by hand, or turn it on again under Actions, after a quiet stretch.

A change to a PKGBUILD by hand: bump `pkgrel`, run `makepkg --printsrcinfo > .SRCINFO` in its directory, and build it with `makepkg -f` before the pull request.
