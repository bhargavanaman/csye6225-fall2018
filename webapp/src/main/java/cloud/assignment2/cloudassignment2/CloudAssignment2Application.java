package cloud.assignment2.cloudassignment2;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

@SpringBootApplication
public class CloudAssignment2Application extends SpringBootServletInitializer {

    public static void main(String[] args) {
        SpringApplication.run(CloudAssignment2Application.class, args);
    }

    @Override
    protected SpringApplicationBuilder configure (SpringApplicationBuilder application)
    {
        return application.sources(CloudAssignment2Application.class);
    }


}
