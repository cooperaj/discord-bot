FROM node:argon

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD . /usr/src/app
RUN npm install
RUN npm run-script build

EXPOSE 8080
CMD ["npm", "start"]
