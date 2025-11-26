# 🌟 Yushan Platform Service Registry

[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.java.net/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4.10-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-2024.0.2-blue.svg)](https://spring.io/projects/spring-cloud)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Table of Contents

- [Overview](#-overview)
- [What is Service Discovery?](#-what-is-service-discovery)
- [Quick Start](#-quick-start)
- [Repository Structure](#-repository-structure)
- [Configuration Details](#-configuration-details)
- [How Microservices Connect](#-how-microservices-connect)
- [Monitoring & Health Checks](#-monitoring--health-checks)
- [Troubleshooting](#-troubleshooting)
- [Production Deployment](#-production-deployment)
- [Team Workflow](#-team-workflow)

---

## 🎯 Overview

This repository contains the **Eureka Service Discovery Server** for the Yushan web novel platform. It acts as a centralized registry where all microservices register themselves and discover each other dynamically.

### Why Do We Need This?

Without a service registry:
```
❌ User Service needs to know Content Service is at 192.168.1.100:8082
❌ If Content Service moves to 192.168.1.105:8082, everything breaks
❌ Hard to scale services (can't run multiple instances easily)
```

With Eureka:
```
✅ User Service asks: "Where is content-service?"
✅ Eureka responds: "Here are all available instances"
✅ Automatic load balancing across multiple instances
✅ Services can move/scale without manual configuration
```

---

## 🤔 What is Service Discovery?

Think of Eureka as a **phone book for microservices**:

1. **Registration**: When a service starts, it calls Eureka and says:
    - "Hi! I'm `analytics-service` and I'm available at `192.168.1.100:8083`"

2. **Discovery**: When a service needs to call another service:
    - User Service: "Hey Eureka, where is `content-service`?"
    - Eureka: "It's at `192.168.1.105:8082`"

3. **Health Monitoring**: Services send heartbeats every 30 seconds
    - If Eureka doesn't receive a heartbeat, it removes the dead service

4. **Load Balancing**: If multiple instances exist:
    - Eureka returns all available instances
    - Client automatically distributes requests

---

## 🚀 Quick Start

### Prerequisites

- **Java 21** (LTS) installed
- **Maven 3.6+** or use the included Maven wrapper
- **Docker & Docker Compose** (optional, recommended)

### Option 1: Using Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/phutruonnttn/yushan-microservices-service-registry.git
cd yushan-microservices-service-registry

# Start Eureka Server
docker-compose up -d

# View logs
docker-compose logs -f eureka-server

# Verify it's running
open http://localhost:8761
```

### Option 2: Using Maven (Local Development)

```bash
# Clone the repository
git clone https://github.com/phutruonnttn/yushan-microservices-service-registry.git
cd yushan-microservices-service-registry

# Run with Maven wrapper
./mvnw spring-boot:run

# Or with installed Maven
mvn spring-boot:run
```

### Verify Installation

1. **Dashboard**: Open http://localhost:8761
    - You should see the Eureka dashboard
    - Initially, no services will be registered

2. **Health Check**:
   ```bash
   curl http://localhost:8761/actuator/health
   ```
   Expected response:
   ```json
   {"status":"UP"}
   ```

---

## 📁 Repository Structure

```
yushan-microservices-service-registry/
├── README.md                          # This file
├── pom.xml                           # Maven configuration
├── .gitignore                        # Git ignore rules
├── Dockerfile                        # Docker image definition
├── docker-compose.yml                # Docker orchestration
├── mvnw                              # Maven wrapper (Unix)
├── mvnw.cmd                          # Maven wrapper (Windows)
├── .mvn/                            # Maven wrapper files
└── src/
    └── main/
        ├── java/
        │   └── com/yushan/registry/
        │       └── ServiceRegistryApplication.java  # Main application
        └── resources/
            └── application.yml       # Eureka configuration
```

---

## ⚙️ Configuration Details

### Key Settings in `application.yml`

| Setting | Value | Purpose |
|---------|-------|---------|
| `server.port` | 8761 | Standard Eureka port |
| `eureka.client.register-with-eureka` | false | Registry doesn't register with itself |
| `eureka.client.fetch-registry` | false | Registry doesn't fetch from itself |
| `eureka.server.enable-self-preservation` | false (dev) | Remove dead services quickly |
| `eureka.server.eviction-interval-timer-in-ms` | 10000 | Check for dead services every 10s |

### Important Notes

⚠️ **Self-Preservation Mode**: Currently disabled for development
- **Development**: Disabled (removes dead services immediately)
- **Production**: MUST be enabled (handles network issues gracefully)

---

## 🔗 How Microservices Connect

### Step 1: Add Eureka Client Dependency

In your microservice's `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

### Step 2: Configure Eureka Client

In your microservice's `application.yml`:

```yaml
spring:
  application:
    name: analytics-service  # ⚠️ IMPORTANT: This is your service name!

eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/  # Eureka server URL
    fetch-registry: true        # Fetch other services
    register-with-eureka: true  # Register this service
  
  instance:
    prefer-ip-address: true
    lease-renewal-interval-in-seconds: 30  # Send heartbeat every 30s
    lease-expiration-duration-in-seconds: 90  # Remove if no heartbeat for 90s
```

### Step 3: Enable Discovery Client

Add annotation to your main application class:

```java
@SpringBootApplication
@EnableDiscoveryClient  // ← Add this annotation
public class AnalyticsServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AnalyticsServiceApplication.class, args);
    }
}
```

### Step 4: Call Other Services Using Feign

```java
@FeignClient(name = "content-service")  // Use service name from Eureka
public interface ContentClient {
    
    @GetMapping("/api/novels/{id}")
    NovelDTO getNovel(@PathVariable("id") Long id);
}
```

**Usage:**
```java
@Service
public class AnalyticsService {
    
    @Autowired
    private ContentClient contentClient;
    
    public void analyzeNovel(Long novelId) {
        // Feign automatically discovers content-service from Eureka
        NovelDTO novel = contentClient.getNovel(novelId);
        // ... your logic
    }
}
```

---

## 🔍 Monitoring & Health Checks

### Eureka Dashboard

Access: http://localhost:8761

**What You'll See:**
- **Instances currently registered with Eureka**: List of all active services
- **General Info**: Eureka server status and configuration
- **Instance Info**: Detailed information about each service
    - Status (UP/DOWN)
    - IP Address
    - Port
    - Last heartbeat time

### Health Check Endpoint

```bash
# Check Eureka server health
curl http://localhost:8761/actuator/health

# Check specific service (example)
curl http://localhost:8761/eureka/apps/ANALYTICS-SERVICE
```

### Docker Health Check

```bash
# View container health status
docker ps

# View detailed health logs
docker inspect yushan-eureka-registry
```

---

## 🔧 Troubleshooting

### Problem 1: Services Not Appearing in Eureka

**Symptoms:**
- Service starts successfully
- Eureka dashboard shows no registered instances

**Solutions:**
1. Verify `@EnableDiscoveryClient` annotation exists
2. Check `eureka.client.serviceUrl.defaultZone` points to correct URL
3. Ensure Eureka server is running: http://localhost:8761
4. Check application logs for connection errors
5. Verify network connectivity (especially in Docker)

```bash
# Check if service can reach Eureka
curl http://localhost:8761/eureka/apps

# View service logs
docker-compose logs -f [service-name]
```

---

### Problem 2: Services Showing as DOWN

**Symptoms:**
- Service appears in Eureka but status is DOWN
- Red status indicator in dashboard

**Solutions:**
1. Check service health endpoint:
   ```bash
   curl http://[service-ip]:[service-port]/actuator/health
   ```
2. Verify firewall rules allow traffic on service port
3. Check if service is actually running:
   ```bash
   docker ps  # or
   ps aux | grep java
   ```
4. Review heartbeat configuration:
   ```yaml
   eureka:
     instance:
       lease-renewal-interval-in-seconds: 30
   ```

---

### Problem 3: Stale Service Instances

**Symptoms:**
- Dead services still appear in Eureka
- Requests fail because service no longer exists

**Solutions:**
1. Check if self-preservation mode is enabled:
   ```yaml
   eureka:
     server:
       enable-self-preservation: false  # Development only
   ```
2. Adjust eviction interval:
   ```yaml
   eureka:
     server:
       eviction-interval-timer-in-ms: 10000  # Check every 10s
   ```
3. Restart Eureka server to clear cache:
   ```bash
   docker-compose restart eureka-server
   ```

---

### Problem 4: Port 8761 Already in Use

**Symptoms:**
```
Port 8761 is already in use
```

**Solutions:**
1. Find process using port 8761:
   ```bash
   # macOS/Linux
   lsof -i :8761
   
   # Windows
   netstat -ano | findstr :8761
   ```
2. Kill the process or use a different port:
   ```yaml
   # application.yml
   server:
     port: 8762  # Change to different port
   ```

---

### Problem 5: Docker Container Won't Start

**Symptoms:**
- Container exits immediately
- `docker ps` shows no eureka-server

**Solutions:**
1. View container logs:
   ```bash
   docker-compose logs eureka-server
   ```
2. Check if port is already mapped:
   ```bash
   docker ps -a
   ```
3. Rebuild image:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

---

## 🚀 Production Deployment

### 1. Enable Self-Preservation Mode

**⚠️ CRITICAL**: Always enable in production!

```yaml
eureka:
  server:
    enable-self-preservation: true
```

**Why?** Prevents removing services during network issues.

---

### 2. Add Security

Protect the Eureka dashboard with authentication:

**Add dependency to `pom.xml`:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

**Configure in `application.yml`:**
```yaml
spring:
  security:
    user:
      name: admin
      password: ${EUREKA_PASSWORD}  # Use environment variable
```

**Update clients:**
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: http://admin:${EUREKA_PASSWORD}@eureka-server:8761/eureka/
```

---

### 3. High Availability (Multiple Eureka Instances)

Run 2-3 Eureka servers for redundancy:

**Eureka Server 1:**
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: http://eureka-server-2:8761/eureka/,http://eureka-server-3:8761/eureka/
```

**Eureka Server 2:**
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: http://eureka-server-1:8761/eureka/,http://eureka-server-3:8761/eureka/
```

**Eureka Server 3:**
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: http://eureka-server-1:8761/eureka/,http://eureka-server-2:8761/eureka/
```

---

### 4. Use Proper Hostnames

Replace `localhost` with actual hostnames or IPs:

```yaml
eureka:
  instance:
    hostname: eureka.yushan.com  # Production hostname
    prefer-ip-address: false
```

---

### 5. Resource Limits (Docker)

Add resource constraints in `docker-compose.yml`:

```yaml
services:
  eureka-server:
    # ... other config
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

---

## 👥 Team Workflow

### One-Time Setup (Each Developer)

```bash
# 1. Clone the registry repository
git clone https://github.com/phutruonnttn/yushan-microservices-service-registry.git
cd yushan-microservices-service-registry

# 2. Start Eureka (keep it running)
docker-compose up -d

# 3. Verify it's working
open http://localhost:8761
```

---

### Daily Development

1. **Start Eureka** (if not already running):
   ```bash
   cd yushan-microservices-service-registry
   docker-compose start
   ```

2. **Start your microservice** (it will auto-register):
   ```bash
   cd yushan-analytics-service
   ./mvnw spring-boot:run
   ```

3. **Check registration**:
    - Open http://localhost:8761
    - Your service should appear in the list

4. **Stop services** at end of day:
   ```bash
   # Stop your microservice (Ctrl+C)
   
   # Stop Eureka (optional)
   cd yushan-microservices-service-registry
   docker-compose stop
   ```

---

### Making Changes to Eureka

```bash
# 1. Pull latest changes
git pull origin main

# 2. Rebuild Docker image
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 3. Verify
open http://localhost:8761
```

---

## 📊 Service Communication Flow

## 🏗️ Architecture Overview

```
                    ┌─────────────────────────────┐
                    │   Eureka Service Registry   │
                    │       localhost:8761        │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │   Service Registration &     │
                    │      Discovery Layer         │
                    └──────────────┬──────────────┘
                                   │
        ┌──────────┬───────────────┼───────────────┬──────────┐
        │          │               │               │          │
        ▼          ▼               ▼               ▼          ▼
   ┌────────┐ ┌─────────┐  ┌────────────┐ ┌──────────┐ ┌──────────┐
   │  User  │ │ Content │  │ Engagement │ │Gamifica- │ │Analytics │
   │Service │ │ Service │  │  Service   │ │  tion    │ │ Service  │
   │ :8081  │ │  :8082  │  │   :8084    │ │ Service  │ │  :8083   │
   └────────┘ └─────────┘  └────────────┘ │  :8085   │ └──────────┘
        │          │              │        └──────────┘      │
        └──────────┴──────────────┴──────────────────────────┘
                    Inter-service Communication
                      (via Feign Clients)
```

**Flow:**
1. All services register with Eureka on startup
2. Services send heartbeat every 30 seconds
3. When Service A needs Service B:
    - A asks Eureka: "Where is service-b?"
    - Eureka returns: "service-b is at IP:PORT"
    - A calls B using that address
4. If Service B crashes or moves, Eureka updates automatically

---

## 📚 Additional Resources

- **Spring Cloud Netflix**: https://spring.io/projects/spring-cloud-netflix
- **Eureka Documentation**: https://cloud.spring.io/spring-cloud-netflix/reference/html/
- **Service Discovery Pattern**: https://microservices.io/patterns/service-registry.html
- **Docker Compose**: https://docs.docker.com/compose/

---

## 🆘 Getting Help

1. **Check the Dashboard**: http://localhost:8761
2. **View Logs**:
   ```bash
   # Docker
   docker-compose logs -f eureka-server
   
   # Maven
   tail -f logs/spring.log
   ```
3. **Check Health**:
   ```bash
   curl http://localhost:8761/actuator/health
   ```
4. **Contact Team**:
    - Slack: #yushan-platform-dev
    - Email: platform-team@yushan.com

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Netflix OSS** for Eureka
- **Spring Cloud Team** for the integration
- **Yushan Platform Team** for building awesome microservices!

---

## Testing

### Unit Tests

The Service Registry includes unit tests to verify the Spring context loads successfully:

```bash
# Run tests
./mvnw test
```

**Test Configuration**:
- Tests exclude `EurekaServerAutoConfiguration` to avoid Eureka server startup during tests
- Uses `@EnableAutoConfiguration(exclude = {EurekaServerAutoConfiguration.class})` to prevent ApplicationInfoManager dependency issues
- All tests passing ✅

## CI/CD Pipeline

The Service Registry includes a comprehensive CI/CD pipeline with:

- ✅ **Unit Tests**: JUnit 5 tests for application context loading
- ✅ **Code Quality**: SpotBugs static analysis, Checkstyle code style checks
- ✅ **Code Coverage**: JaCoCo coverage reports
- ✅ **Security Scanning**: OWASP Dependency Check and Snyk vulnerability scanning
- ✅ **Container Scanning**: Trivy container vulnerability scanning
- ✅ **Quality Gates**: SonarCloud analysis and quality gates
- ✅ **Docker Build**: Automated Docker image building and pushing to GitHub Container Registry

**Made with ❤️ by Yushan Platform Team**

*Last Updated: November 2025*
