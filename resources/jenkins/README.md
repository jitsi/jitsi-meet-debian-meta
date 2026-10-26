# CI scripts for the debian repository

Scripts used by the Jitsi CI to publish packages to the download.jitsi.org debian repository.
The repository is a [mini-dinstall](https://manpages.debian.org/mini-dinstall) flat archive with
the `unstable`, `testing`, `stable` and `alpha` distributions.

All scripts read their settings from the environment:

| Variable | Description |
|---|---|
| `REPO_DIR` | the root of the archive, e.g. `/var/www/repo/debian` |
| `MINID_CONF_FILE` | the mini-dinstall config, see `mini-dinstall.conf.tmpl` |
| `GNUPGHOME` | the gpg home holding the signing key |
| `GPG_KEY_ID` | the signing key, default `Jitsi` |
| `GPG_PASSPHRASE_FILE` | file with the key passphrase, default `$GNUPGHOME/passphrase` |
| `REPO_SYNC_TARGET` | rsync destination of the archive (local path or `host:path`), sync is skipped when empty |
| `DRY_RUN` | when set, nothing is synced, pushed or released |

| Script | Description |
|---|---|
| `add-to-incoming.sh <dist> <files...>` | signs the `.deb` files and moves the packages to the mini-dinstall incoming dir |
| `update-repo.sh` | runs mini-dinstall to process incoming |
| `clean-oldies.sh <dist> <package>` | removes the oldest builds of a package from a distribution |
| `sync-repo.sh <dist>` | syncs a distribution to `REPO_SYNC_TARGET` |
| `promote.sh <from> <to> <version> [<package glob>...]` | promotes a jitsi-meet release (or the given packages) between distributions |
| `move-and-clean-signatures.sh` | copies the signatures of promoted packages to stable and drops stale ones from unstable |
| `sign-release.sh` | mini-dinstall `release_signscript`, signs the `Release` files |
| `github-release.sh` | creates the github releases and release notes when promoting to stable |
| `tag-release.sh <meta version>` | tags the component repos with `jitsi-meet_<meta version>` |
