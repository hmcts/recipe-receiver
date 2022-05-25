FROM gcr.io/distroless/base-debian11
COPY service-bus-reciever /
CMD ["/service-bus-reciever"]