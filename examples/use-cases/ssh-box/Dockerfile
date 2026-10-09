# SSH-able Linux container (demo).
# Docker best practice is `docker exec` instead of running sshd — this exists only
# to show HOW when a real SSH login is genuinely required. Read the folder README.
FROM alpine:3.20

# OpenSSH server + a non-root login user.
# Alpine's `adduser -D` locks the account (shadow field `!`), which sshd refuses even
# for key auth. Rewrite `!` → `*`: password login stays disabled, pubkey login works.
RUN apk add --no-cache openssh \
 && ssh-keygen -A \
 && adduser -D -s /bin/sh dev \
 && sed -i 's/^dev:!/dev:*/' /etc/shadow

# Harden the daemon: no root login, key-based auth only.
RUN { \
      echo "PermitRootLogin no"; \
      echo "PasswordAuthentication no"; \
      echo "PubkeyAuthentication yes"; \
      echo "AuthorizedKeysFile .ssh/authorized_keys"; \
      echo "AllowUsers dev"; \
    } >> /etc/ssh/sshd_config \
 && mkdir -p /home/dev/.ssh \
 && chown -R dev:dev /home/dev/.ssh \
 && chmod 700 /home/dev/.ssh

# Bind-mounted keys are owned by the *host* UID, which sshd's StrictModes rejects.
# The entrypoint installs them with the right owner/permissions at start-up.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
