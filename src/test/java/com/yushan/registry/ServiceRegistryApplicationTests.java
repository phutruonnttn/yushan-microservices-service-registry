package com.yushan.registry;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.netflix.eureka.server.EurekaServerAutoConfiguration;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest(classes = ServiceRegistryApplication.class)
@EnableAutoConfiguration(exclude = {EurekaServerAutoConfiguration.class})
@TestPropertySource(properties = {
    "eureka.client.enabled=false",
    "eureka.client.register-with-eureka=false",
    "eureka.client.fetch-registry=false",
    "spring.main.web-application-type=none"
})
class ServiceRegistryApplicationTests {

    @Test
    void contextLoads() {
        // Test that Spring context loads successfully
        // Excluded EurekaServerAutoConfiguration to avoid server startup during tests
    }
}

