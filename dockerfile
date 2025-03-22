FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y bind9 samba cron rsync && \
    mkdir -p /srv/nas/backups /var/log/samba /var/run/samba /var/lib/samba && \
    chmod 777 /srv/nas/backups && \
    rm -rf /var/lib/apt/lists/*

COPY smb.conf /etc/samba/smb.conf
COPY named.conf.local /etc/bind/named.conf.local
COPY db.local.zone /etc/bind/db.local.zone
COPY start.sh /start.sh

RUN chmod +x /start.sh

CMD ["/start.sh"]
