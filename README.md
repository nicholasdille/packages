# packages

Installation script for tools I use regularly

## Using the package manager

Install the package manager:

```bash
curl --silent https://pkg.dille.io/pkg.sh > sudo tee /usr/local/bin/pkg
sudo chmod +x /usr/local/bin/pkg
```

List available packages:

```bash
pkg list
```

Search packages:

```bash
pkg search docker
pkg search --tags docker
```

Install a package:

```bash
pkg install kind
```

## Installing a package without the package manager

Install a package, e.g. `kind`:

```bash
curl --silent https://pkg.dille.io/kind/install.sh | bash
```

## Writing a new packages

Installation scripts for new packages can be composed from the function library:

```bash
set -o errexit

source <(curl --silent --location --fail https://pkg.dille.io/.scripts/source.sh)

unlock_sudo

github_install \
    --repo nektos/act \
    --match suffix \
    --asset _Linux_x86_64.tar.gz \
    --type tarball \
    --include act
```
