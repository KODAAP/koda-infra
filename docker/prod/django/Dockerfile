# Set the base Python version (slim-bookworm for a lightweight and secure image)
ARG PYTHON_VERSION=3.14.8-slim-bookworm@sha256:48b13b003dda20b16f9442b8475aa05fe21bf6579a8c881db92ffb4d8fd20f83
FROM docker.io/python:${PYTHON_VERSION} AS python

# Stage 1: Build dependency wheels
FROM python AS python-build-stage

ARG BUILD_ENVIRONMENT=prod

RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ./backend/requirements /requirements

RUN pip --default-timeout=100 wheel --wheel-dir /usr/src/app/wheels -r /requirements/${BUILD_ENVIRONMENT}.txt --retries 5

# Stage 2: Python run stage
FROM python AS python-run-stage

ARG BUILD_ENVIRONMENT=prod
ARG APP_HOME=/app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV BUILD_ENV=${BUILD_ENVIRONMENT}
ENV DJANGO_ENV=prod

WORKDIR ${APP_HOME}

# Install runtime dependencies (including GDAL for GIS/GeoPandas) and clean apt cache
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

# Create django system user and group
RUN addgroup --system django && \
    adduser --system --ingroup django django

# Install Python dependencies from wheels and remove wheels layer
COPY --from=python-build-stage /usr/src/app/wheels /wheels/
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ /wheels/* \
    && rm -rf /wheels/

# Copy entrypoint and start scripts
COPY --chown=django:django ./docker/prod/django/entrypoint /entrypoint
COPY --chown=django:django ./docker/prod/django/start /start
COPY --chown=django:django ./docker/prod/django/celery/worker/start /start-celeryworker
# COPY --chown=django:django ./docker/prod/django/celery/beat/start /start-celerybeat
COPY --chown=django:django ./docker/prod/django/celery/flower/start /start-flower

# Consolidate script permissions into a single RUN layer
RUN sed -i 's/\r$//g' /entrypoint /start /start-celeryworker /start-flower \
    && chmod +x /entrypoint /start /start-celeryworker /start-flower

# Copy application code
COPY --chown=django:django ./backend ${APP_HOME}

# Create static and media directories under django ownership
RUN mkdir -p ${APP_HOME}/staticfiles ${APP_HOME}/media && \
    chown -R django:django ${APP_HOME}/staticfiles ${APP_HOME}/media

USER django

ENTRYPOINT [ "/entrypoint" ]