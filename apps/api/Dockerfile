# ---- build stage: install dependencies into a virtualenv ----
FROM python:3.12-alpine AS build
WORKDIR /app
RUN python -m venv /venv
COPY requirements.txt .
RUN /venv/bin/pip install --no-cache-dir -r requirements.txt

# ---- runtime stage: small image, non-root user ----
FROM python:3.12-alpine
RUN apk upgrade --no-cache && adduser -D -u 10001 app
WORKDIR /app
COPY --from=build /venv /venv
COPY app.py .
ENV PATH="/venv/bin:$PATH" PYTHONUNBUFFERED=1
USER 10001
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
