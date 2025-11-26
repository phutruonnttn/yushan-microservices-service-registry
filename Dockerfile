# Use Eclipse Temurin JDK 21 (LTS) as base image
FROM eclipse-temurin:21-jdk-jammy AS build

# Set working directory
WORKDIR /app

# Copy Maven wrapper and pom.xml first (for better caching)
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Make mvnw executable
RUN chmod +x ./mvnw

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Copy checkstyle.xml for code quality checks
COPY checkstyle.xml checkstyle.xml

# Build the application (skip tests for faster builds)
RUN ./mvnw package -DskipTests

# ===== Second stage: Runtime image =====
FROM eclipse-temurin:21-jre-jammy

# Set working directory
WORKDIR /app

# Copy only the built JAR from build stage
COPY --from=build /app/target/service-registry-1.0.0.jar app.jar

# Create a non-root user for security
RUN useradd -m -u 1001 eureka && \
    chown -R eureka:eureka /app

# Switch to non-root user
USER eureka

# Expose Eureka port
EXPOSE 8761

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8761/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]