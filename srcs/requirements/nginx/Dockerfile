FROM debian:12

RUN apt update && apt install nginx -y

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]