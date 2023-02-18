FROM nimlang/nim:alpine

RUN apk update
RUN apk add --no-cache pcre-dev

WORKDIR /app
COPY . .

RUN ["nimble", "-y", "--gc:orc", "-d:release", "--opt:speed", "build"]

ENTRYPOINT [ "./bin/genai_generator" ]