package com.okta.example.ra.models;

import lombok.Data;

import java.util.List;

@Data
public class HookError {

    private String errorSummary;
    private List<HookErrorCause> errorCauses;
}