# dockerfile-partials<a name="dockerfile-partials"></a>

Dockerfile partials and devcontainer [bake](https://docs.docker.com/build/bake/introduction/) files
for re-use across multiple applications.

<!-- mdformat-toc start --slug=github --maxlevel=6 --minlevel=1 -->

- [dockerfile-partials](#dockerfile-partials)
  - [GitHub cache bake file](#github-cache-bake-file)
    - [GitHub cache bake file usage](#github-cache-bake-file-usage)
    - [GitHub cache bake file inputs](#github-cache-bake-file-inputs)
  - [Devcontainer bake files](#devcontainer-bake-files)
    - [Devcontainer bake files devcontainer-cache-build usage](#devcontainer-bake-files-devcontainer-cache-build-usage)
      - [Devcontainer bake files devcontainer-cache-build initializeCommand config](#devcontainer-bake-files-devcontainer-cache-build-initializecommand-config)
      - [Devcontainer bake files devcontainer-cache-build .devcontainer/devcontainer-bake.hcl config](#devcontainer-bake-files-devcontainer-cache-build-devcontainerdevcontainer-bakehcl-config)
    - [Devcontainer bake files direct usage](#devcontainer-bake-files-direct-usage)
  - [Dockerfile partials](#dockerfile-partials)
    - [docker-client](#docker-client)
      - [docker-client Dockerfile usage](#docker-client-dockerfile-usage)
      - [docker-client bake file usage](#docker-client-bake-file-usage)
      - [docker-client devcontainer usage](#docker-client-devcontainer-usage)
    - [pre-commit](#pre-commit)
      - [pre-commit Dockerfile usage](#pre-commit-dockerfile-usage)
      - [pre-commit bake file usage](#pre-commit-bake-file-usage)
      - [pre-commit Codespaces usage](#pre-commit-codespaces-usage)
    - [useradd](#useradd)
      - [useradd Dockerfile usage](#useradd-dockerfile-usage)
      - [useradd bake file usage](#useradd-bake-file-usage)
      - [useradd Codespaces usage](#useradd-codespaces-usage)
  - [Contributing](#contributing)
    - [devcontainer](#devcontainer)
      - [devcontainer basic usage](#devcontainer-basic-usage)
      - [devcontainer Codespaces usage](#devcontainer-codespaces-usage)
    - [CI/CD](#cicd)
    - [Settings](#settings)

<!-- mdformat-toc end -->

## GitHub cache bake file<a name="github-cache-bake-file"></a>

The `github-cache-bake.hcl` [bake](https://docs.docker.com/build/bake/introduction/) config file
provides a basic bake configuration for use in repos that produce container images using
[GitHub Actions](https://docs.github.com/en/actions) and targeted to the
[GitHub container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

The file configures
[registry outputs](https://docs.docker.com/reference/cli/docker/buildx/build/#registry) and registry
[cache-to](https://docs.docker.com/reference/cli/docker/buildx/build/#cache-to) and
[cache-from](https://docs.docker.com/reference/cli/docker/buildx/build/#cache-from), all directed to
the specified registry. It infers naming and tagging config for the image based on the context
(local vs. CI, protected vs. development versions), such that while each context can push both image
and cache content, development and local contexts do not collide with each other or with releases.

### GitHub cache bake file usage<a name="github-cache-bake-file-usage"></a>

The configuration of the bake file requires the use of a
[Docker builder with the docker-container driver](https://docs.docker.com/build/builders/drivers/docker-container/).
To set one up, use the following command:

```bash
docker builder create --use --bootstrap --driver docker-container
```

The bake file requires at least `IMAGE_NAME` variable to be set, and `REGISTRY` should nearly always
be overridden (see [GitHub cache bake file inputs](#github-cache-bake-file-inputs)). Export them:

```bash
REGISTRY=ghcr.io/[your account]
IMAGE_NAME=[image name]
```

By default, the `github-cache-bake.hcl` file expects a Dockerfile in the bake command execution
directory (via `cwd://Dockerfile`), which is used for the build. It sets the default
[`context`](https://docs.docker.com/build/bake/reference/#targetcontext) to `BAKE_CMD_CONTEXT` such
that the filesystem local to the bake execution are available to the image build.

To build your image using the GitHub cache bake file via
[remote bake definition](https://docs.docker.com/build/bake/remote-definition/), run this command:

```bash
REGISTRY=ghcr.io/[your account] IMAGE_NAME=[image name] docker buildx bake --file github-cache-bake.hcl https://github.com/rcwbr/dockerfile-partials.git#0.1.0
```

### GitHub cache bake file inputs<a name="github-cache-bake-file-inputs"></a>

The GitHub cache bake file can be configured using the following inputs:

| Variable               | Required | Default                         | Effect                                                                                                                           |
| ---------------------- | -------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `IMAGE_NAME`           | ✓        | N/A                             | The name of the image, specifically not fully-qualified. This is the reference loaded to the host Docker daemon.                 |
| `GITHUB_REF_NAME`      | ✗        | `"local-${HOST}"`               | The human-friendly ref name for the GitHub context. Used to inform the image tag.                                                |
| `GITHUB_REF_PROTECTED` | ✗        | `"false"`                       | Indicates if the CI context is for a protected (vs. development) ref. Indicates whether to append a unique version ID to the tag |
| `GITHUB_SHA`           | ✗        | `"local"`                       | The commit SHA of the CI context. Appended to tags after `VERSION` unless `GITHUB_REF_PROTECTED` is true.                        |
| `HOST`                 | ✗        | `$HOSTNAME`                     | The name of the host device. Used to qualify image and cache names and avoid collisions between users.                           |
| `HOSTNAME`             | ✗        | N/A                             | The name of the host device, for some OSs.                                                                                       |
| `REGISTRY`             | ✗        | `"ghcr.io/"`                    | The registry to which to push remote content. Generally, `"ghcr.io/[user/org]/"`.                                                |
| `IMAGE_REF`            | ✗        | `"${REGISTRY}${IMAGE_NAME}"`    | The fully-qualified image name used as the base for version and cache references.                                                |
| `VERSION`              | ✗        | `${GITHUB_REF_NAME}`, sanitized | This is the default tag for the image.                                                                                           |

## Devcontainer bake files<a name="devcontainer-bake-files"></a>

Each Dockerfile partial is accompanied by a `devcontainer-bake.hcl`
[bake](https://docs.docker.com/build/bake/introduction/) config file, and a common bake file is
defined at the repository root. These are intended to make composition of devcontainer image
contents trivial. They are designed to work with the
[devcontainer-cache-build initialize script](https://github.com/rcwbr/devcontainer-cache-build/tree/main?tab=readme-ov-file#initialize-script).

Using these bake files remotely requires setting the primary build context to this repo by
[remote definition](https://docs.docker.com/build/bake/remote-definition/). Because of
[this limitation of remote bake build contexts](https://github.com/docker/buildx/blob/056cf8a7ca083d91eccf9200e7e2c99ff170bbaf/bake/bake.go#L1213C6-L1213C73)

> `We don't currently support reading a remote Dockerfile with a local context when doing a remote invocation because we automatically derive the dockerfile from the context atm`

this means that any build contexts required by the Dockerfile partial must be provided via a
[local directory `contexts` context](https://docs.docker.com/build/bake/reference/#targetcontexts)
rather than the primary build context. For example, the `pre-commit` Dockerfile
[reads from the `local_context` context](https://github.com/rcwbr/dockerfile-partials/blob/086902fb92beb8ab2bf887ff6a6a141804762eb9/pre-commit/Dockerfile#L10C26-L10C39)
[set to `BAKE_CMD_CONTEXT`](https://github.com/rcwbr/dockerfile-partials/blob/086902fb92beb8ab2bf887ff6a6a141804762eb9/pre-commit/devcontainer-bake.hcl#L11).
This allows it to consume contents of the downstream build context.

### Devcontainer bake files devcontainer-cache-build usage<a name="devcontainer-bake-files-devcontainer-cache-build-usage"></a>

In a `devcontainer.json` leveraging the
[devcontainer-cache-build initialize script](https://github.com/rcwbr/devcontainer-cache-build/tree/main?tab=readme-ov-file#initialize-script),
add the following configuration to the script called by `initializeCommand` before the `curl` to the
initialize script:

#### Devcontainer bake files devcontainer-cache-build initializeCommand config<a name="devcontainer-bake-files-devcontainer-cache-build-initializecommand-config"></a>

```bash
# .devcontainer/initialize
export DEVCONTAINER_DEFINITION_TYPE=bake
export DEVCONTAINER_DEFINITION_FILES="devcontainer-bake.hcl [path to each desired partial bake file] cwd://.devcontainer/devcontainer-bake.hcl"
export DEVCONTAINER_BUILD_ADDITIONAL_ARGS=https://github.com/rcwbr/dockerfile-partials.git#0.1.0
curl https://raw.githubusercontent.com/rcwbr/devcontainer-cache-build/0.3.0/devcontainer-cache-build-initialize | bash
```

`DEVCONTAINER_DEFINITION_FILES` must begin with `devcontainer-bake.hcl` and end with
`cwd://.devcontainer/devcontainer-bake.hcl` (see
[Devcontainer bake files devcontainer-cache-build .devcontainer/devcontainer-bake.hcl config](#devcontainer-bake-files-devcontainer-cache-build-devcontainerdevcontainer-bakehcl-config)),
and with each desired partial bake file in between (ordering is important for override priority).
For example:

```bash
export DEVCONTAINER_DEFINITION_FILES="devcontainer-bake.hcl useradd/devcontainer-bake.hcl pre-commit/devcontainer-bake.hcl cwd://.devcontainer/devcontainer-bake.hcl"
```

#### Devcontainer bake files devcontainer-cache-build .devcontainer/devcontainer-bake.hcl config<a name="devcontainer-bake-files-devcontainer-cache-build-devcontainerdevcontainer-bakehcl-config"></a>

To join the devcontainer partial bake files, you must define a bake file local to your project that
configures targets from each partial you select. It must define at least the `devcontainer_layers`
variable as a list with the names of each selected partial, and override the `base_context` for at
least the first partial target. For example:

```hcl
variable "devcontainer_layers" {
  default = [
    "useradd",
    "pre-commit"
  ]
}

target "useradd" {
  contexts = {
    base_context = "docker-image://python:3.12.4"
  }
}
```

Optionally, `target`s may be configured for each layer. Values provided to these will override those
defined in the partials `devcontainer-bake.hcl`.

### Devcontainer bake files direct usage<a name="devcontainer-bake-files-direct-usage"></a>

The partial bake files may be used manually through a command like this:

```bash
docker buildx bake --file devcontainer-bake.hcl [--file arg for each desired partial bake file] --file cwd://.devcontainer/devcontainer-bake.hcl https://github.com/rcwbr/dockerfile-partials.git#0.1.0
```

## Dockerfile partials<a name="dockerfile-partials"></a>

### docker-client<a name="docker-client"></a>

The docker-client Dockerfile defines steps to install the
[Docker CLI client](https://docs.docker.com/reference/cli/docker/) in a Docker image. It copies the
CLI executable from the [Docker docker image](https://hub.docker.com/_/docker).

#### docker-client Dockerfile usage<a name="docker-client-dockerfile-usage"></a>

The recommended usage is via the [Devcontainer bake files](#devcontainer-bake-files). It is also
possible to use the Dockerfile partial directly.

Use a [Bake](https://docs.docker.com/reference/cli/docker/buildx/bake/) config file, and set the
`base_context` context as the image to which to apply the docker-client installation. For example:

```hcl
target "base" {
  dockerfile = "Dockerfile"
}

target "default" {
  context = "https://github.com/rcwbr/dockerfile_partials.git#0.1.0"
  dockerfile = "docker-client/Dockerfile"
  contexts = {
    base_context = "target:base"
  }
}
```

The args accepted by the Dockerfile include:

| Variable     | Required | Default  | Effect                                        |
| ------------ | -------- | -------- | --------------------------------------------- |
| `DOCKER_GID` | ✗        | `800`    | Group ID of the docker user group             |
| `USER`       | ✗        | `"root"` | Username to grant access to the Docker daemon |

#### docker-client bake file usage<a name="docker-client-bake-file-usage"></a>

The docker-client partial contains a devcontainer bake config file. See
[Devcontainer bake files](#devcontainer-bake-files) for general usage. The docker-client bake config
file accepts the following inputs:

| Variable     | Required | Default  | Effect                                                          |
| ------------ | -------- | -------- | --------------------------------------------------------------- |
| `DOCKER_GID` | ✗        | `800`    | See [docker-client Dockerfile](#docker-client-dockerfile-usage) |
| `USER`       | ✗        | `"root"` | See [docker-client Dockerfile](#docker-client-dockerfile-usage) |

#### docker-client devcontainer usage<a name="docker-client-devcontainer-usage"></a>

The docker-client partial installs only the client CLI by default. To leverage the container host's
Docker daemon, the relevant socket must be mounted at runtime. In a
[`devcontainer.json`](https://containers.dev/implementors/json_reference/), the following content
must be included:

```jsonc
{
  "image": "[image including docker-client layers]",
  "mounts": [
    { "source": "/var/run/docker.sock", "target": "/var/run/docker.sock", "type": "bind" }
  ]
}
```

### pre-commit<a name="pre-commit"></a>

The pre-commit Dockerfile defines steps to install [pre-commit](https://pre-commit.com/) and install
the hooks required by a repo configuration.

#### pre-commit Dockerfile usage<a name="pre-commit-dockerfile-usage"></a>

The recommended usage is via the [Devcontainer bake files](#devcontainer-bake-files). It is also
possible to use the Dockerfile partial directly.

Use a [Bake](https://docs.docker.com/reference/cli/docker/buildx/bake/) config file, and set the
`base_context` context as the image to which to apply the pre-commit installation, and the
`local_context` to the directory from which the `.pre-commit-config.yaml` can be loaded (generally
[`BAKE_CMD_CONTEXT`](https://docs.docker.com/build/bake/reference/#built-in-variables)).
Additionally, provide appropriate values for the `USER` build arg. For example:

```hcl
target "base" {
  dockerfile = "Dockerfile"
}

target "default" {
  context = "https://github.com/rcwbr/dockerfile_partials.git#0.1.0"
  dockerfile = "pre-commit/Dockerfile"
  contexts = {
    base_context = "target:base"
    local_context = BAKE_CMD_CONTEXT
  }
  args = {
    USER = "myuser"
  }
}
```

The args accepted by the Dockerfile include:

| Variable | Required | Default  | Effect                                  |
| -------- | -------- | -------- | --------------------------------------- |
| `USER`   | ✗        | `"root"` | Username to assume for hook pre-loading |

#### pre-commit bake file usage<a name="pre-commit-bake-file-usage"></a>

The pre-commit partial contains a devcontainer bake config file. See
[Devcontainer bake files](#devcontainer-bake-files) for general usage. The pre-commit bake config
file accepts the following inputs:

| Variable | Required | Default  | Effect                                                    |
| -------- | -------- | -------- | --------------------------------------------------------- |
| `USER`   | ✗        | `"root"` | See [pre-commit Dockerfile](#pre-commit-dockerfile-usage) |

#### pre-commit Codespaces usage<a name="pre-commit-codespaces-usage"></a>

For use in [Codespaces](https://github.com/features/codespaces) devcontainers, the build args must
be set to the following values:

- `USER`: `codespace`

These values may be hard-coded in the Bake config file, or may be exposed as variables for
compatibility with local environments.

```hcl
variable "USER" {
  default = "root"
}
...
  args = {
    USER = "${USER}"
  }
...
```

If exposed as variables, the appropriate values for Codespaces use must be
[set as secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces#adding-a-secret)
so as to be available during Codespace provisioning.

### useradd<a name="useradd"></a>

The useradd Dockerfile defines steps to add a user to the image, with configurable user name, id,
and group id.

#### useradd Dockerfile usage<a name="useradd-dockerfile-usage"></a>

The recommended usage is via the [Devcontainer bake files](#devcontainer-bake-files). It is also
possible to use the Dockerfile partial directly.

Use a [Bake](https://docs.docker.com/reference/cli/docker/buildx/bake/) config file, and set the
`base_context` context as the image to which to apply the user addition. Additionally, provide
appropriate values for the `USER`, `USER_UID`, and `USER_GID` build args. For example:

```hcl
target "base" {
  dockerfile = "Dockerfile"
}

target "default" {
  context = "https://github.com/rcwbr/dockerfile_partials.git#0.1.0"
  dockerfile = "useradd/Dockerfile"
  contexts = {
    base_context = "target:base"
  }
  args = {
    USER = "myuser"
    USER_UID = 1000
    USER_GID = 1000
  }
}
```

The args accepted by the Dockerfile include:

| Variable         | Required | Default     | Effect                                                  |
| ---------------- | -------- | ----------- | ------------------------------------------------------- |
| `USER`           | ✓        | N/A         | Username of the user to create                          |
| `EXTRA_GID_ARGS` | ✗        | `""`        | Extra `--gid [id]` args to apply to the useradd command |
| `USER_UID`       | ✗        | `1000`      | User UID for the user to create                         |
| `USER_GID`       | ✗        | `$USER_UID` | User GID for the user to create                         |

#### useradd bake file usage<a name="useradd-bake-file-usage"></a>

The useradd partial contains a devcontainer bake config file. See
[Devcontainer bake files](#devcontainer-bake-files) for general usage. The useradd bake config file
accepts the following inputs:

| Variable         | Required | Default                                           | Effect                                                                  |
| ---------------- | -------- | ------------------------------------------------- | ----------------------------------------------------------------------- |
| `USER`           | ✗        | `"root"`                                          | See [useradd Dockerfile](#useradd-dockerfile-usage)                     |
| `EXTRA_GID_ARGS` | ✗        | `""` or `DOCKER_CLIENT_EXTRA_GID_ARGS` if defined | See [useradd Dockerfile](#useradd-dockerfile-usage)                     |
| `UID`            | ✗        | `0`                                               | Maps to `USER_UID`. See [useradd Dockerfile](#useradd-dockerfile-usage) |
| `GID`            | ✗        | `${UID}`                                          | Maps to `USER_GID`.See [useradd Dockerfile](#useradd-dockerfile-usage)  |

#### useradd Codespaces usage<a name="useradd-codespaces-usage"></a>

For use in [Codespaces](https://github.com/features/codespaces) devcontainers, the build args must
be set to the following values:

- `USER`: `codespace`
- `UID`: `1000`

These values may be hard-coded in the Bake config file, or may be exposed as variables for
compatibility with local environments.

```hcl
variable "USER" {
  default = "root"
}
variable "UID" {
  default = 0
}
variable "GID" {
  // Use the user id as group id unless set
  default = "${UID}"
}

...
  args = {
    USER = "${USER}"
    USER_UID = "${UID}"
    USER_GID = "${GID}"
  }
...
```

If exposed as variables, the appropriate values for Codespaces use must be
[set as secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces#adding-a-secret)
so as to be available during Codespace provisioning.

## Contributing<a name="contributing"></a>

### devcontainer<a name="devcontainer"></a>

This repo contains a [devcontainer definition](https://containers.dev/) in the `.devcontainer`
folder. It leverages the
[devcontainer cache build tool](https://github.com/rcwbr/devcontainer-cache-build) and the
Dockerfile partials defined in this repo.

#### devcontainer basic usage<a name="devcontainer-basic-usage"></a>

The [devcontainer cache build tool](https://github.com/rcwbr/devcontainer-cache-build) requires
authentication to the GitHub package registry, as a token stored as
`DOCKERFILE_PARTIALS_DEVCONTAINER_INITIALIZE` (see
[instructions](https://github.com/rcwbr/devcontainer-cache-build/tree/main?tab=readme-ov-file#initialize-script-github-container-registry-setup)).

#### devcontainer Codespaces usage<a name="devcontainer-codespaces-usage"></a>

For use with Codespaces, the `DOCKERFILE_PARTIALS_DEVCONTAINER_INITIALIZE` token (see
[devcontainer basic usage](#devcontainer-basic-usage)) must be stored as a Codespaces secret (see
[instructions](https://github.com/rcwbr/devcontainer-cache-build/tree/main?tab=readme-ov-file#initialize-script-github-container-registry-setup)),
as must values for `USER`, and `UID` (see [useradd Codespaces usage](#useradd-codespaces-usage)).

### CI/CD<a name="cicd"></a>

This repo uses the [release-it-gh-workflow](https://github.com/rcwbr/release-it-gh-workflow), with
the conventional-changelog image defined at any given ref, as its automation.

### Settings<a name="settings"></a>

The GitHub repo settings for this repo are defined as code using the
[Probot settings GitHub App](https://probot.github.io/apps/settings/). Settings values are defined
in the `.github/settings.yml` file. Enabling automation of settings via this file requires
installing the app.

The settings applied are as recommended in the
[release-it-gh-workflow usage](https://github.com/rcwbr/release-it-gh-workflow/blob/4dea4eaf328b60f92dab1b5bd2a63daefa85404b/README.md?plain=1#L58),
including tag and branch protections, GitHub App and environment authentication, and required
checks.
