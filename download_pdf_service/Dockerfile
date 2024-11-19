FROM node:20-slim

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3004

ENTRYPOINT ["/usr/src/app/bin/docker-entrypoint"]

CMD ["sh", "-c", "node server.js"]