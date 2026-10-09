#!/bin/sh
# Install the mounted public key(s) with the ownership sshd requires, then run sshd.
set -e

SRC=/run/keys/authorized_keys
DST=/home/dev/.ssh/authorized_keys

if [ -f "$SRC" ]; then
  cp "$SRC" "$DST"
  chown dev:dev "$DST"
  chmod 600 "$DST"
  echo "[entrypoint] installed $(grep -c . "$SRC") authorized key(s) for user dev"
else
  echo "[entrypoint] WARNING: no $SRC mounted — ssh login will fail (mount ./authorized_keys)" >&2
fi

# -D = foreground (container needs a PID 1 that doesn't fork), -e = log to stderr.
exec /usr/sbin/sshd -D -e
