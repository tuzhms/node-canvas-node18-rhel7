# Сборка node-canvas под rhel7 nodejs18

docker build -t build-canvas:latest .
docker run --name build-canvas build-canvas
docker cp build-canvas:/home/node/canvas-v2.11.2-node-v108-linux-glibc-x64.tar.gz .
