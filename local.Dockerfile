FROM golang:1.19.3

RUN apt update && apt upgrade -y && \
	apt install -y git \
	make openssh-client

# all the code lives here. We gonna mount the volume here
WORKDIR .

# install goose for db migrations
RUN go install github.com/pressly/goose/v3/cmd/goose@latest
RUN go install github.com/joho/godotenv
RUN go install github.com/lib/pq

# will run from an entrypoint.sh file
ADD migrations/ migrations/
ADD cmd/ cmd/
COPY entrypoint.sh /entrypoint.sh
ADD .env .env
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]