FROM python:3.12-slim

WORKDIR /dbt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
ENV DBT_PROFILES_DIR=/dbt

# La imagen es "dbt": lo que pases al ejecutarla son los argumentos (build, run-operation...).
ENTRYPOINT ["dbt"]
CMD ["build", "--target", "dev"]