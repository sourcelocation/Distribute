#!/bin/sh
set -e
chown -R appuser:appuser /app/data/db
chown -R appuser:appuser /app/storage
exec su-exec appuser:appuser "$@"
