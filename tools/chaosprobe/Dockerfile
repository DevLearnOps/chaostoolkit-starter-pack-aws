FROM python:3.11-alpine

WORKDIR /app
COPY requirements.txt .
RUN pip3 install -U -r requirements.txt

ARG APP_MODULE="main"
RUN { \
    echo "#!/bin/sh"; \
    echo "exec uvicorn --port 8000 --host 0.0.0.0 ${APP_MODULE}:app"; \
    } > run.sh \
    && chmod 500 run.sh

COPY . .

EXPOSE 8000

CMD ["/app/run.sh"]
