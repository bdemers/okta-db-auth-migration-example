package com.okta.example.ra.models;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class HookErrorCause {
    private String errorSummary;
    private String reason;
    private String locationType;
    private String location;
    private String domain;
}