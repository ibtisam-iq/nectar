FROM ubuntu
WORKDIR /app
COPY entrypoint.sh app.py .
RUN apt update -y && apt install npm -y && apt install apache2 -y && chmod +x entrypoint.sh && useradd -m ibtisam
CMD ["/app/entrypoint.sh"]
USER ibtisam
EXPOSE 80


