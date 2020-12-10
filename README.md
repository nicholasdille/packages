# packages

Installer for tools I use regularly on Linux

## Why

I am many tools which are either not included in my favourite Linux distribution or which are not updated fast enough. These tools are also used in my talks and workshops where I need to install them in environments provided to participants.

For a few years, I have maintained a list of commands to download and install these tools. But I ended up with outdated versions and duplicate instructions.

So, I started working on an installer for these tools.

Yes, this project seems to be competing with other tools:

- [bin](https://github.com/marcosnils/bin) by [marcosnils](https://www.twitter.com/marcosnils) - I wanted to be able to cover projects which are not publishing precompiled binaries
- [homebrew](https://brew.sh/) - This felt too complex for my use case

## Features

- Install a tool with dependencies
- Automatically track latest version

## Non-Goals

- Configure and start daemons
- Track installed tools and versions

## Prerequisites

Most functionality is available with `bash`, `curl` and `jq`

The subcommands `list` and `search` also require `column` for formatting the output

Several packages require Docker and/or Git to compile the binaries from source

Some packages require some logic to install which is based on `envsubst`, `make`, `xz` and `unzip`

## Usage

Install the package manager:

```bash
curl --silent https://pkg.dille.io/pkgctl.sh | sudo tee /usr/local/bin/pkgctl >/dev/null
sudo chmod +x /usr/local/bin/pkgctl
```

... or...

```bash
curl --silent https://pkg.dille.io/pkgctl.sh | bash -s bootstrap
```

Cache the package definitions:

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
