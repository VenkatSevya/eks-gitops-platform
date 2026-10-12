FROM python:3.12-alpine AS build
RUN python -m venv /venv
COPY requirements.txt .
RUN /venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.12-alpine
RUN apk upgrade --no-cache && adduser -D -u 10001 app
WORKDIR /app
COPY --from=build /venv /venv
COPY worker.py .
ENV PATH="/venv/bin:$PATH" PYTHONUNBUFFERED=1
USER 10001
CMD ["python", "worker.py"]
