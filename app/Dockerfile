FROM maven:3.9-eclipse-temurin-17-alpine AS build
WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline -q

COPY src ./src
RUN mvn package -DskipTests -q

FROM eclipse-temurin:17-jre-alpine AS runtime
WORKDIR /app

RUN addgroup -S taskflow && adduser -S taskflow -G taskflow \
    && apk add --no-cache wget

COPY --from=build /build/target/*.jar app.jar

USER taskflow

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=150s --retries=5 \
  CMD wget -q -O- http://localhost:8080/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
