FROM alpine

WORKDIR /

RUN apk add --no-cache curl bash choose

COPY slack_status_updater.sh /

ENTRYPOINT ["/slack_status_updater.sh"]
