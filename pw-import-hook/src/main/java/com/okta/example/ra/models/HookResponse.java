package com.okta.example.ra.models;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
public class HookResponse {

    private HookError error;
    private List<Command> commands;
    private Map<String, Object> debugContext;
}