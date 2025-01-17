# Set base_context in the downstream Bake file
# hadolint ignore=DL3006
FROM base_context AS base

# Sourced from https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user
ARG USER=
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG EXTRA_GID_ARGS

# Create the user
# hadolint ignore=SC2034
RUN DEBIAN_FRONTEND=noninteractive \
  && groupadd --gid $USER_GID $USER \
  && useradd --uid $USER_UID --gid $USER_GID $EXTRA_GID_ARGS -m $USER \
  #
  # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
  && apt-get update \
  && apt-get install --allow-unauthenticated --no-install-recommends -y \
    sudo=1.9.13* \
  && rm -rf /var/lib/apt/lists/*

# Make use of the USER directive optional via target
FROM base AS with_user
USER $USER
