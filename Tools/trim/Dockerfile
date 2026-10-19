# Versões fixadas: Python 3.11.10 sobre Debian 12, cujo ffmpeg é a série 5.1
FROM python:3.11.10-slim-bookworm

WORKDIR /app

# ffmpeg/ffprobe do Debian 12 (série 5.1, fixada pela imagem base)
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY ./utils/requirements.txt utils/requirements.txt
RUN pip install --no-cache-dir -r utils/requirements.txt

COPY ./trim .
COPY ./utils ./utils

CMD [ "python", "-u", "trim.py"]
