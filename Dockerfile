FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y wget patch build-essential

# Kopia plików do katalogu /app wewnątrz obrazu
COPY . /app
WORKDIR /app

CMD ["/bin/bash", "/app/rpi_5g.sh"]

