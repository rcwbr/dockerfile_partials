# hadolint ignore=DL3006
FROM common_context AS common_context

# hadolint ignore=DL3006
FROM base_context
ARG USER=root
USER $USER
ARG DEVCONTAINER_PRE_COMMIT_IMAGE

# Burn the pre-commit image ref into the image for use in the caller script
ENV DEVCONTAINER_PRE_COMMIT_IMAGE=$DEVCONTAINER_PRE_COMMIT_IMAGE

# Configure pre-commit caller executable
COPY pre-commit/pre-commit /usr/local/bin

# Include pre-commit initialization in config for devcontainers onCreateCommand, postCreateCommand
COPY --from=common_context on_create_command /opt/devcontainers/on_create_command
COPY --from=common_context post_create_command /opt/devcontainers/post_create_command
COPY pre-commit/on_create_command /opt/devcontainers/on_create_command
COPY pre-commit/post_create_command /opt/devcontainers/post_create_command
