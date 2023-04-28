FROM golang:1.19.3

RUN apt update && apt upgrade -y && \
	apt install -y git \
	make openssh-client

# All the code lives here. We will mount the volume here
WORKDIR /migrations

COPY . .

RUN go mod download

RUN chmod +x /migrations/entrypoint.sh

CMD ["/migrations/entrypoint.sh"]