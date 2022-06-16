package com.okta.example.ra;

import com.fasterxml.jackson.databind.JsonNode;
import com.okta.example.ra.models.Command;
import com.okta.example.ra.models.HookResponse;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.provisioning.JdbcUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.util.Collections;
import java.util.Map;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, Environment environment) throws Exception {
        return http
            .authorizeRequests()
                .anyRequest().authenticated().and()// all requests require auth
            .csrf().disable() // expected only requests from NON-browser clients, disable CSRF
            .httpBasic().and() // see application.properties for username/password
            .build();
    }

    @RestController
    static class OktaHooksController {

        private final PasswordValidator passwordValidator;

        public OktaHooksController(PasswordValidator passwordValidator) {
            this.passwordValidator = passwordValidator;
        }

        @PostMapping("/pwhook")
        Object passwordImportHook(@RequestBody JsonNode node) {

            JsonNode credentials =  node.get("data").get("context").get("credential");
            String username = credentials.get("username").asText();
            String password = credentials.get("password").asText();

            boolean result = passwordValidator.isPasswordValid(username, password);
            String status = result ? "VERIFIED" : "UNVERIFIED";

            return new HookResponse()
                    .setCommands(Collections.singletonList(
                            new Command("com.okta.action.update",
                                    Map.of("credential", status))));
        }
    }

    /**
     * This class duplicates what validates a username/password based on the inputs provided.
     */
    @Service
    static class PasswordValidator {
        private final DaoAuthenticationProvider authenticationProvider;

        public PasswordValidator(DataSource dataSource) {
            // Creates an AuthenticationProvider internal to this classes use
            this.authenticationProvider = new DaoAuthenticationProvider();
            JdbcUserDetailsManager userManager = new JdbcUserDetailsManager(dataSource);
            userManager.setEnableGroups(true);
            userManager.setEnableAuthorities(false);
            authenticationProvider.setUserDetailsService(userManager);
        }

        boolean isPasswordValid(String username, String password) {
            try {
                // check if the password is valid, any invalid passwords or inactive users will throw an exception
                Authentication authentication = authenticationProvider.authenticate(new UsernamePasswordAuthenticationToken(username, password));
                return authentication.isAuthenticated();
            } catch (AuthenticationException e) {
                return false;
            }
        }
    }
}
