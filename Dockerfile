# --------- Étape 1 : Builder pour SearXNG ---------
FROM python:3.11-slim as builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git build-essential libxslt-dev libffi-dev libxml2-dev zlib1g-dev \
        libjpeg-dev libyaml-dev libssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG SEARXNG_REPO=https://github.com/searxng/searxng.git
ARG SEARXNG_BRANCH=main
ENV SEARXNG_SRC=/usr/local/searxng

RUN git clone --depth=1 --branch ${SEARXNG_BRANCH} ${SEARXNG_REPO} ${SEARXNG_SRC}
WORKDIR ${SEARXNG_SRC}
RUN pip install --upgrade pip setuptools && pip install .

# --------- Étape 2 : Builder pour LibreTranslate ---------
FROM python:3.11-slim as lt-builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libicu-dev python3-dev g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip && \
    pip install libretranslate==1.3.9

# --------- Étape 3 : Image finale ---------
FROM python:3.11-slim

ENV SEARXNG_SRC=/usr/local/searxng
ENV INSTANCE_NAME="lusk.bzh"
ENV SEARX_PORT=8080
ENV LT_PORT=5000
ENV LT_API_KEY="votre_cle_secrete"  # Changez ceci !

# Copie depuis les builders
COPY --from=builder ${SEARXNG_SRC} ${SEARXNG_SRC}
COPY --from=lt-builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=lt-builder /usr/local/bin/libretranslate /usr/local/bin/libretranslate

# Installation des dépendances runtime
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libicu72 libjpeg62-turbo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR ${SEARXNG_SRC}
COPY ./settings.yml ./settings.yml

# Script de démarrage
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Ports exposés
EXPOSE ${SEARX_PORT}
EXPOSE ${LT_PORT}

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:${SEARX_PORT} || exit 1

CMD ["/start.sh"]
