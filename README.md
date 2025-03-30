# Gentoo Overlay by Sergey Murzin

This Gentoo overlay was originally created for my own use only. However, it can
be useful for other Gentoo users too. So feel free to connect it.

Detailed information about the overlay and the packages contained in it can be
found in [the wiki](https://github.com/atlant-t/gentoo-overlay/wiki).

## Adding the overlay

**Note:** Don't forget to sync the repository after adding it.

```bash
emerge --sync sergey_murzin
```

### Using Repository Eselect

This repository is not yet in the official list of Eselect Repositories.
However, Eselect Repositories provides the ability to add third-party
repositories using the add action.

```bash
eselect repository add sergey_murzin git https://github.com/atlant-t/gentoo-overlay.git
```

### Manually

```bash
cat <<__EOF__ > /etc/portage/repos.conf/sergey_murzin
[sergey_murzin]
location = /var/db/repos/sergey_murzin
sync-type = git
sync-uri = https://github.com/atlant-t/gentoo-overlay.git
auto-sync = true
__EOF__
```

