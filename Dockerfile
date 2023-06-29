ARG AWS_CLI_VERSION=2.12.0
ARG ALPINE_VERSION=3.18

FROM ghcr.io/sparkfabrik/docker-alpine-aws-cli:${AWS_CLI_VERSION}-alpine${ALPINE_VERSION} as awscli

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache file gettext jq rclone mysql-client mariadb-connector-c postgresql-client bash curl

# Install AWS CLI v2 using the binary builded in the awscli stage
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

RUN curl -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it

# Make the terminal pretty and add node_modules binaries to PATH
RUN echo "whoami &>/dev/null && PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] ' || PS1='\[\033[1;36m\]unknown\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '" >> /etc/profile \
    && echo "export TERM=xterm" >> /etc/profile

COPY app /app

RUN chmod +x /app/docker-entrypoint.sh \
    && chmod -R +x /app/commands

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
