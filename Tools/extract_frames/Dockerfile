FROM python:3.11-slim-bookworm

WORKDIR /app

# ffmpeg/ffprobe da Debian bookworm (versão fixada pela imagem base)
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY ./utils/requirements.txt utils/requirements.txt
RUN pip install --no-cache-dir -r utils/requirements.txt

COPY ./extract_frames .
COPY ./utils ./utils

CMD [ "python", "-u", "extract_frames.py"]
