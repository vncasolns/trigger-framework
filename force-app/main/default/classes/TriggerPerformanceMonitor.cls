/**
 * Created by sonal on 2024-10-12.
 *
 *
 *
     public static void run(Schema.SObjectType sObjectType) {
        // ... existing code

        for (TriggerFeature__mdt control : controls) {
            if (isFeatureApplicable(control, syncContext)) {
                TriggerPerformanceMonitor.start(control.DeveloperName);
                try {
                    // ... existing code
                } finally {
                    TriggerPerformanceMonitor.stop(control.DeveloperName);
                }
            }
        }

        TriggerPerformanceMonitor.logPerformance();
    }
 *
 *
 *
 */

public with sharing class TriggerPerformanceMonitor {
    private static Map<String, Long> startTimes = new Map<String, Long>();
    private static Map<String, Long> executionTimes = new Map<String, Long>();

    public static void start(String featureName) {
        startTimes.put(featureName, System.currentTimeMillis());
    }

    public static void stop(String featureName) {
        Long startTime = startTimes.get(featureName);
        if (startTime != null) {
            Long executionTime = System.currentTimeMillis() - startTime;
            executionTimes.put(featureName, executionTime);
        }
    }

    public static void logPerformance() {
        for (String featureName : executionTimes.keySet()) {
            System.debug('Feature: ' + featureName + ', Execution Time: ' + executionTimes.get(featureName) + 'ms');
        }
    }
}