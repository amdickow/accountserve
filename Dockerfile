FROM iron/base

COPY build/accountservice-amd64-linux  /
ENTRYPOINT ["./accountservice-amd64-linux"]
