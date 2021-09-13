FROM spurin/hexo:latest

ENV WORKDIR=/app
WORKDIR ${WORKDIR}
ENV NPM_CONFIG_REGISTRY="https://registry.npm.taobao.org"
ENV PHANTOMJS_CDNURL="https://npm.taobao.org/mirrors/phantomjs/"
ENV SASS_BINARY_SITE="https://npm.taobao.org/mirrors/node-sass/"
ENV ELECTRON_MIRROR="https://npm.taobao.org/mirrors/electron/"

COPY package.json .

RUN npm install hexo --save && hexo generate

COPY . .

EXPOSE 4000

CMD ["./node_modules/.bin/hexo", "server"]
