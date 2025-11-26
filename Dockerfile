FROM ghcr.io/takahiro-kawaguchi/autossh-jump-base:main

COPY entrypoint-remote.sh /entrypoint-remote.sh
RUN chmod +x /entrypoint-remote.sh

CMD ["/entrypoint-remote.sh"]