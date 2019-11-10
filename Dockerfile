FROM iron/base

ADD build/accountservice-amd64-linux /
ENTRYPOINT ["./accountservice-amd64-linux"]