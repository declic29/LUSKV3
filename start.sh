#!/bin/bash

# Démarrer LibreTranslate en arrière-plan (port 5000)
libretranslate \
  --host 0.0.0.0 \
  --port $LT_PORT \
  --load-only fr,en,br \
  --api-key $LT_API_KEY \
  --disable-files-translation \
  --metrics &

# Démarrer SearXNG (port 8080)
exec gunicorn \
  --bind 0.0.0.0:$SEARX_PORT \
  --workers 4 \
  --threads 2 \
  "searx.webapp:app"
