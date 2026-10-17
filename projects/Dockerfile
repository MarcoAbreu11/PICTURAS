from node
# ffprobe para ler duração/resolução dos vídeos no upload
run apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
workdir /app

copy . .
run npm install

expose 9001
cmd ["npm", "start"]