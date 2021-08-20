FROM alpine:3.13
RUN apk add --no-cache rclone mysql-client postgresql-client bash curl
RUN curl -o /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it

COPY docker-entrypoint.sh /app/docker-entrypoint.sh
COPY commands /app/commands

RUN chmod +x /app/docker-entrypoint.sh \
    && chmod -R +x /app/commands

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
