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
curl --silent https://pkg.dille.io/pkg.sh | sudo tee /usr/local/bin/pkg >/dev/null
sudo chmod +x /usr/local/bin/pkg
```

Cache the package definition:

```bash
pkg cache
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

Install a specific version of a package:

```bash
pkg install kind@v0.9.0
```

Install a package that is already installed:

```bash
pkg install --force kind
```
