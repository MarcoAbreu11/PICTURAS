# Versões fixadas (REQ-VID-CONV-043): Python 3.11.10 sobre Debian 12, cujo ffmpeg é a série 5.1
FROM python:3.11.10-slim-bookworm

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY ./utils/requirements.txt utils/requirements.txt
RUN pip install --no-cache-dir -r utils/requirements.txt
COPY ./video_convert/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY ./video_convert .
COPY ./utils ./utils

CMD ["python", "-u", "video_convert.py"]
