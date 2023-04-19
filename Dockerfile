# pull official base image
FROM node:18.15.0-alpine as build

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install app dependencies
COPY ./package.json .
COPY ./package-lock.json .
RUN npm ci --silent

# add app
COPY . .

RUN npm run build


# production environment
FROM nginx:1.23.2-alpine

RUN apk add bash

COPY --from=build /app/dist /usr/share/nginx/html

COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf

RUN adduser --disabled-password \
  --home /app \
  --gecos '' appuser && chown -R appuser /app

RUN chown -R appuser:appuser /usr/share/nginx/html && chmod -R 755 /usr/share/nginx/html && \
  chown -R appuser:appuser /var/cache/nginx && \
  chown -R appuser:appuser /var/log/nginx && \
  chown -R appuser:appuser /etc/nginx/conf.d && \
  chown -R appuser:appuser /var/run/

RUN touch /var/run/nginx.pid && \
  chown -R appuser:appuser /var/run/nginx.pid

WORKDIR /usr/share/nginx/html

USER appuser

EXPOSE 8080

CMD ["/bin/bash", "-c", "nginx -g \"daemon off;\""]