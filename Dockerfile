FROM nimlang/nim:alpine AS build

WORKDIR /usr/src/app
COPY . .

RUN nimble build -d:static

FROM scratch
COPY --from=build /usr/src/app/dynim /
COPY --from=build /usr/src/app/dynim.json /

CMD ["/dynim"]
