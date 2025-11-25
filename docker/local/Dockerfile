FROM node:25-alpine

RUN npm config set registry https://registry.npmmirror.com \
    && npm install hexo-cli -g
ADD ./package.json ./package-lock.json /home/
WORKDIR /home

RUN npm install

ENTRYPOINT [ "hexo" ]
CMD [ "server" ]