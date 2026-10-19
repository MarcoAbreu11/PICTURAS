# Versões fixadas (REQ-VID-CONV-043): Node 22.11 sobre Debian 12, cujo ffmpeg é a série 5.1
FROM node:22.11.0-bookworm
# ffprobe para ler duração, resolução e codecs dos vídeos no upload (o processamento é nas tools)
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
WORKDIR /app

COPY . .
RUN npm install

EXPOSE 9001
CMD ["npm", "start"]
