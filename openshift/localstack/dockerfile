FROM localstack/localstack:0.10.8

RUN chgrp -R 0 /etc/passwd && \
    chmod -R g+rwX /etc/passwd && \
    rm -rf /tmp/localstack/*

COPY custom-entrypoint.sh /custom-entrypoint.sh
ENTRYPOINT ["/custom-entrypoint.sh"]

USER 1001
