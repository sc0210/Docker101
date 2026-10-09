FROM python:3.12-slim

WORKDIR /app

# Deps first → better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m app && chown -R app:app /app
USER app

EXPOSE 8000

CMD ["python", "app.py"]
