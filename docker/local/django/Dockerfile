FROM docker.io/python:3.12.2-slim-bookworm AS python

# Stage 1: Build our dependency wheels
FROM python AS python-build-stage

ARG BUILD_ENVIRONMENT=local

RUN apt-get update && apt-get install --no-install-recommends -y \
  build-essential \
  libpq-dev

COPY ./backend/requirements /requirements

#RUN pip wheel --wheel-dir /usr/src/app/wheels -r /requirements/${BUILD_ENVIRONMENT}.txt
RUN pip --default-timeout=100 wheel --wheel-dir /usr/src/app/wheels -r /requirements/${BUILD_ENVIRONMENT}.txt --retries 5

# Stage 2: Python run stage.
FROM python AS python-run-stage
ARG BUILD_ENVIRONMENT=local

ARG APP_HOME=/app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV BUILD_ENV ${BUILD_ENVIRONMENT}

WORKDIR ${APP_HOME}
# Install system dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
  sudo git bash-completion nano ssh \
  libpq-dev \
  gettext \
  gdal-bin \
  libgdal-dev \
  python3-gdal \
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

# Copy and set up scripts
COPY --chown=django:django ./docker/local/django/entrypoint.sh /entrypoint
COPY --chown=django:django ./docker/local/django/start.sh /start
COPY --chown=django:django ./docker/local/django/celery/worker/start.sh /start-celeryworker
#COPY --chown=django:django ./docker/local/django/celery/beat/start.sh /start-celerybeat
COPY --chown=django:django ./docker/local/django/celery/flower/start.sh /start-flower

RUN sed -i 's/\r$//g' /entrypoint /start /start-celeryworker /start-flower \
  && chmod +x /entrypoint /start /start-celeryworker /start-flower

#RUN sed -i 's/\r$//g' /start-celerybeat \
#  && chmod +x /start-celerybeat

# Copy application code
COPY --chown=django:django backend/ ${APP_HOME}

# Create staticfiles and media directories with proper permissions AFTER copying code
RUN mkdir -p ${APP_HOME}/staticfiles ${APP_HOME}/media && \
  chown -R django:django ${APP_HOME} && \
  chmod -R 755 ${APP_HOME}/staticfiles ${APP_HOME}/media

USER django

ENTRYPOINT [ "/entrypoint" ]

