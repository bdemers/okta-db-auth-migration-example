package com.okta.example.ra.models;

import lombok.Data;

@Data
public class Command {

    private final String type;
    private final Object value;
}