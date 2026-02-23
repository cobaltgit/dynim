FROM nimlang/nim:alpine AS build

WORKDIR /usr/src/app
COPY . .

RUN ln -s /usr/bin/gcc /usr/bin/musl-gcc
RUN nimble static

FROM scratch
COPY --from=build /usr/src/app/bin/dynim /
COPY --from=build /usr/src/app/dynim.json /

CMD ["/dynim"]
