# Set base_context in the downstream Bake file
FROM base_context AS base

# Sourced from https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user
ARG USERNAME=
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Make use of the USER directive optional via target
FROM base AS with_user
USER $USERNAME
