FROM node:10

ENV WORKDIR=/app
WORKDIR ${WORKDIR}
ENV NPM_CONFIG_REGISTRY="https://registry.npmmirror.com"
ENV PHANTOMJS_CDNURL="https://npm.taobao.org/mirrors/phantomjs/"
ENV SASS_BINARY_SITE="https://npm.taobao.org/mirrors/node-sass/"
ENV ELECTRON_MIRROR="https://npm.taobao.org/mirrors/electron/"

COPY . .

RUN npm i && ./node_modules/.bin/hexo generate

EXPOSE 4000

CMD ["./node_modules/.bin/hexo", "server"]
