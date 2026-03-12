FROM python:3.9-slim

WORKDIR /usr/app

RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    dbt-postgres==1.7.0 \
    psycopg2-binary

COPY . /usr/app/

RUN dbt deps || true

CMD ["dbt", "run"]
