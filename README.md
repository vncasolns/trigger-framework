# Salesforce Apex Trigger Framework

This repository contains a robust and flexible trigger framework for Salesforce Apex. The framework provides a structured approach to organizing and managing trigger logic, improving code maintainability, and allowing for easier testing and configuration.

## Table of Contents

1. [Features](#features)
2. [Components](#components)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Configuration](#configuration)
6. [Asynchronous Execution](#asynchronous-execution)
7. [Metrics](#metrics)
8. [Best Practices](#best-practices)
9. [Contributing](#contributing)
10. [License](#license)

## Features

- Centralized trigger dispatcher
- Configurable trigger execution via Custom Metadata Types
- Support for all trigger contexts (before/after insert/update/delete/undelete)
- Asynchronous trigger execution capability
- Bypass and required permission settings
- Built-in performance metrics logging

## Components

1. `ITriggerExecutable`: Interface for trigger handlers
2. `TriggerContext`: Class to encapsulate trigger context information
3. `TriggerDispatcher`: Main class for dispatching trigger execution
4. `TriggerMetrics`: Class for logging performance metrics

## Installation

1. Clone this repository or copy the Apex classes into your Salesforce org.
2. Create a Custom Metadata Type named `TriggerFeature__mdt` with the following fields:
   - `DeveloperName` (Text)
   - `Handler__c` (Text)
   - `IsActive__c` (Checkbox)
   - `LoadOrder__c` (Number)
   - `BeforeInsert__c` (Checkbox)
   - `AfterInsert__c` (Checkbox)
   - `BeforeUpdate__c` (Checkbox)
   - `AfterUpdate__c` (Checkbox)
   - `BeforeDelete__c` (Checkbox)
   - `AfterDelete__c` (Checkbox)
   - `AfterUndelete__c` (Checkbox)
   - `Asynchronous__c` (Checkbox)
   - `SObjectName__c` (Text)
   - `BypassPermission__c` (Text)
   - `RequiredPermission__c` (Text)

## Usage

1. Create a trigger handler class that implements the `ITriggerExecutable` interface:

```apex
public class AccountTriggerHandler implements ITriggerExecutable {
    public void execute(TriggerContext context) {
        if (context.isAfter() && context.isInsert()) {
            // Handle after insert logic
        }
        // Add other context checks and logic as needed
    }
}
```

2. Create a trigger for your SObject that calls the `TriggerDispatcher`:

```apex
trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.run(Account.SObjectType);
}
```

3. Configure the trigger feature in the `TriggerFeature__mdt` Custom Metadata Type.

## Configuration

Configure your trigger features using the `TriggerFeature__mdt` Custom Metadata Type. Each record represents a trigger handler configuration:

- `DeveloperName`: Unique name for the feature
- `Handler__c`: Full name of the handler class (e.g., `AccountTriggerHandler`)
- `IsActive__c`: Whether the feature is active
- `LoadOrder__c`: Order of execution when multiple handlers exist for the same SObject
- `BeforeInsert__c`, `AfterInsert__c`, etc.: Enable/disable specific trigger contexts
- `Asynchronous__c`: Set to true for asynchronous execution (only for after triggers)
- `SObjectName__c`: API name of the SObject (e.g., `Account`)
- `BypassPermission__c`: Custom permission API name to bypass this trigger
- `RequiredPermission__c`: Custom permission API name required to run this trigger

## Asynchronous Execution

To run a trigger handler asynchronously:

1. Set `Asynchronous__c` to true in the `TriggerFeature__mdt` record.
2. Ensure the handler is configured for an after trigger context.

Note: Asynchronous execution is not available for before triggers.

## Metrics

The framework includes built-in performance metrics logging. To enable metrics:

```apex
TriggerMetrics.enableMetrics();
```

Metrics are automatically logged as JSON in debug logs when enabled.

## Best Practices

1. Keep trigger logic in handler classes, not in the trigger itself.
2. Use one trigger per SObject to ensure consistent execution order.
3. Leverage the `TriggerContext` class for context-specific operations.
4. Use Custom Permissions for fine-grained control over trigger execution.
5. Monitor and analyze trigger performance using the built-in metrics.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your proposed changes.
