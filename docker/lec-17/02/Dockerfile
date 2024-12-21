FROM node:alpine as abc
ARG PORT=8000
ENV PORT=$PORT
WORKDIR /app
COPY . .
EXPOSE $PORT
RUN npm install --only=prod
CMD npm run start:prod

FROM abc as xyz
RUN npm install --only=dev
CMD npm start

