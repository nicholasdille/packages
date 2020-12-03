# packages

Installation script for tools I use regularly

## Prerequisites

Most functionality: bash, jq, curl

`list` command: column

Several packages require Docker to compile the binaries from source

Some packages: envsubst, unzip

## Usage

Install the package manager:

```bash
curl --silent https://pkg.dille.io/pkgctl.sh | sudo tee /usr/local/bin/pkgctl >/dev/null
sudo chmod +x /usr/local/bin/pkgctl
```

Cache the package definition:

```bash
pkgctl cache
```

List available packages:

```bash
pkgctl list
```

Search packages:

```bash
pkgctl search docker
pkgctl search --tags docker
```

Install a package:

```bash
pkgctl install kind
```

Install a specific version of a package:

```bash
pkgctl install kind@v0.9.0
```

Install a package that is already installed:

```bash
pkgctl install --force kind
```

Install multiple packages:

```bash
pkgctl install kind kubectl
```

Install multiple packages from a file:

```bash
$ cat packages.txt
kind
kubectl
$ pkgctl install --file packages.txt
```

## Completion

`pkgctl` includes completion:

```bash
source completion.sh
```
