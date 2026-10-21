FROM python:3.11.10-slim-bookworm

WORKDIR /app

# ffmpeg/ffprobe da Debian bookworm (versão fixada pela imagem base)
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY ./utils/requirements.txt utils/requirements.txt
RUN pip install --no-cache-dir -r utils/requirements.txt

# OpenCV (deteção YuNet) com versão fixada
COPY ./blur_faces/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# inclui o modelo de deteção (models/): corre localmente, sem serviços externos
COPY ./blur_faces .
COPY ./utils ./utils

CMD [ "python", "-u", "blur_faces.py"]
