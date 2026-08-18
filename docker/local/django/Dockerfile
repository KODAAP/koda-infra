FROM docker.io/python:3.12.2-slim-bookworm AS python

# Stage 1: Build dependency wheels
FROM python AS python-build-stage

ARG BUILD_ENVIRONMENT=local

# NETTOYAGE: Ajout du rm -rf pour alléger l'image
RUN apt-get update && apt-get install --no-install-recommends -y \
  build-essential \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/*

COPY ./backend/requirements /requirements

RUN pip --default-timeout=100 wheel --wheel-dir /usr/src/app/wheels -r /requirements/${BUILD_ENVIRONMENT}.txt --retries 5

# Stage 2: Python run stage
FROM python AS python-run-stage
ARG BUILD_ENVIRONMENT=local

ARG APP_HOME=/app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV BUILD_ENV ${BUILD_ENVIRONMENT}

WORKDIR ${APP_HOME}

# NETTOYAGE: Suppression de sudo, nano, bash-completion, ssh, python3-gdal
RUN apt-get update && apt-get install --no-install-recommends -y \
  git \
  libpq-dev \
  gettext \
  gdal-bin \
  libgdal-dev \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/*

ENV GDAL_CONFIG=/usr/bin/gdal-config
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

# Create django user and group
RUN addgroup --system django && \
  adduser --system --ingroup django django

# Install Python dependencies
COPY --from=python-build-stage /usr/src/app/wheels /wheels/
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ /wheels/* \
  && rm -rf /wheels/

# NETTOYAGE: Retrait des lignes commentées pour Celery Beat
COPY --chown=django:django ./docker/local/django/entrypoint.sh /entrypoint
COPY --chown=django:django ./docker/local/django/start.sh /start
COPY --chown=django:django ./docker/local/django/celery/worker/start.sh /start-celeryworker
#COPY --chown=django:django ./docker/local/django/celery/beat/start.sh /start-celerybeat
COPY --chown=django:django ./docker/local/django/celery/flower/start.sh /start-flower

RUN sed -i 's/\r$//g' /entrypoint /start /start-celeryworker /start-flower \
  && chmod +x /entrypoint /start /start-celeryworker /start-flower

# Copy application code
COPY --chown=django:django backend/ ${APP_HOME}

# NETTOYAGE: Simplification de la création des dossiers (déjà sous ownership django)
RUN mkdir -p ${APP_HOME}/staticfiles ${APP_HOME}/media && \
  chown -R django:django ${APP_HOME}/staticfiles ${APP_HOME}/media

USER django

ENTRYPOINT [ "/entrypoint" ]