# Custom Trigger Framework

This repository contains a custom trigger framework developed in Salesforce Apex. The framework is designed to provide a structured and scalable way to write and manage triggers in Salesforce. It uses custom metadata to control the execution of features, making it highly configurable and easy to manage.

## Structure

The framework is composed of several classes and interfaces:

- `TriggerContext.cls`: This class encapsulates the context of the current trigger execution, including the operation type, the old and new records, and other trigger state information.

- `TriggerHandler.cls`: This class is the main entry point for the trigger execution. It creates a `TriggerContext` instance and executes the features that are applicable for the current operation.

- `ITriggerExecutable.cls`: This is an interface that should be implemented by all trigger handlers. It defines a single method, `execute`, that takes a `TriggerContext` instance as a parameter.

- `TriggerHandlerTest.cls`: This class contains unit tests for the trigger handler.

- `AccountTrigger.trigger`: This is an example of how to use the trigger handler in a trigger.

## Features

The framework provides several features:

- **Asynchronous Execution**: The framework supports asynchronous execution of triggers. This is useful for operations that are time-consuming and do not need to be completed immediately.

- **Trigger Context**: The framework provides a context for each trigger execution, which includes information about the current operation, the old and new records, and other state information.

- **Modular Design**: The framework follows a modular design, where each trigger handler is a separate class that implements the `ITriggerExecutable` interface. This makes the code easier to manage and test.

- **Custom Metadata Controlled**: The execution of features is controlled by custom metadata. This allows for a high level of configurability and easy management of features.

- **Unit Testing**: The framework includes a test class, `TriggerHandlerTest.cls`, which provides examples of how to write unit tests for your trigger handlers.

## Usage

To use this framework, follow these steps:

1. Create a new class that implements the `ITriggerExecutable` interface. The `execute` method of this class will contain the logic of your trigger.

```apex
public class MyTriggerHandler implements ITriggerExecutable {
    public void execute(TriggerContext context) {
        // Your trigger logic here
    }
}
```

2. In your trigger, call the `run` method of the `TriggerHandler` class, passing the `SObjectType` of the object that the trigger is defined on.

```apex
trigger MyTrigger on MyObject (before insert, before update) {
    TriggerHandler.run(Schema.MyObject.SObjectType);
}
```

3. The framework will automatically execute your trigger handler when the trigger is fired, passing the current trigger context to the `execute` method.

## Testing

The `TriggerHandlerTest.cls` class provides examples of how to write unit tests for your trigger handlers. You can use these examples as a starting point for your own tests.

## Contributing

Contributions are welcome. Please open an issue to discuss your ideas before making a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
