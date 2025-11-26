package com.yushan.registry;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "eureka.client.enabled=false"
})
class ServiceRegistryApplicationTests {

    @Test
    void contextLoads() {
        // Test that Spring context loads successfully
    }
}

