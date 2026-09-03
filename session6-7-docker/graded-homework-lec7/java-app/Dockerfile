FROM eclipse-temurin:21-alpine
WORKDIR /app
COPY index.html .
EXPOSE 8000
CMD ["jwebserver", "-b", "0.0.0.0", "-p", "8000", "-d", "/app"]