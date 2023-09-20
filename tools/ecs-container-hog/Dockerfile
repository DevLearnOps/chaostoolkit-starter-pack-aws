FROM alpine:3

RUN apk update \
    && apk add stress-ng \
    && rm -rf /var/cache/apk

COPY hog.sh /opt/hog.sh

RUN chmod +x /opt/hog.sh

ENV HOG_CONFIG="--cpu 1 --timeout 10s"

CMD ["/opt/hog.sh"]
