FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc gnucobol4 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace


# ADDED
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py index.html main.cob accounts.txt ./


# Added
RUN cobc -x -o main main.cob

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
