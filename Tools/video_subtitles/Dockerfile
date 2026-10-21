FROM python:3.11.10-slim-bookworm
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*
COPY ./video_subtitles/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY ./video_subtitles .
COPY ./utils ./utils
CMD ["python", "-u", "video_subtitles.py"]
