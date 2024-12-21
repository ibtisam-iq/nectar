FROM node:alpine
ARG PORT=8000
ENV PORT=$PORT
WORKDIR /app
# The trailing slash in src/ specifies that you want to copy the contents of the directory.
# So, to copy the entire src directory as a whole into /app, you should use:
#COPY src/ . 
# /app # ls
# index.js           node_modules       package-lock.json  package.json

# COPY src .
#####Docker will attempt to create a new directory named src inside /app and then copy the contents into that directory, 
#resulting in /app/src/ instead of just /app/.
# /app # ls
# index.js           node_modules       package-lock.json  package.json
# /app # 
#COPY src src
# /app # ls
# node_modules       package-lock.json  package.json       src
# /app # cd src/
# /app/src # ls
# index.js
#COPY package.json .
COPY . .
EXPOSE $PORT
RUN npm install
CMD npm start

