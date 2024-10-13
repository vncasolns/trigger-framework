/**
 * Created by sonal on 2024-09-27.
 */

public with sharing class TriggerDispatcher {
    @TestVisible
    private static Map<String, List<TriggerFeature__mdt>> mockControlsMap = new Map<String, List<TriggerFeature__mdt>>();
    private static Map<String, List<TriggerFeature__mdt>> cachedControlsMap = new Map<String, List<TriggerFeature__mdt>>();

    public static void run(Schema.SObjectType sObjectType) {
        String sObjectName = sObjectType.getDescribe().getName();
        List<TriggerFeature__mdt> controls = getControls(sObjectName);
        TriggerContext syncContext = createTriggerContext(false);

        TriggerContext asyncContext;

        for (TriggerFeature__mdt control : controls) {
            if (isFeatureApplicable(control, syncContext)) {
                try {
                    ITriggerExecutable handler = initializeHandlerFromName(control.Handler__c);
                    if (handler != null) {

                        String operation = syncContext.operation.name();

                        if (TriggerMetrics.isMetricsEnabled()) {
                            TriggerMetrics.startMetrics(control.Handler__c, operation, sObjectName, syncContext.size);
                        }

                        if (control.Asynchronous__c) {
                            if (syncContext.isBefore) {
                                throw new TriggerDispatcherException(
                                    'Asynchronous execution is not allowed in before trigger context. Feature: ' +
                                    control.DeveloperName
                                );
                            }
                            if (asyncContext == null) {
                                asyncContext = createTriggerContext(true);
                            }
                            System.enqueueJob(new AsynchronousFeatureExecution(handler, asyncContext, control.Handler__c, operation, sObjectName));
                        } else {
                            handler.execute(syncContext);
                        }

                        if (TriggerMetrics.isMetricsEnabled()) {
                            TriggerMetrics.endMetrics(control.Handler__c, operation, sObjectName);
                        }

                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error in TriggerDispatcher: ' + e.getMessage());
                    throw e;
                }
            }
        }
    }

    private static ITriggerExecutable initializeHandlerFromName(String handlerName) {
        if (String.isNotBlank(handlerName)) {
            try {
                Type handlerType = Type.forName(handlerName);
                if (handlerType != null) {
                    Object handlerInstance = handlerType.newInstance();
                    if (handlerInstance instanceof ITriggerExecutable) {
                        return (ITriggerExecutable) handlerInstance;
                    } else {
                        throw new TriggerDispatcherException(
                            'Handler class does not implement ITriggerExecutable: ' + handlerName
                        );
                    }
                } else {
                    throw new TriggerDispatcherException('Handler class not found: ' + handlerName);
                }
            } catch (Exception e) {
                throw new TriggerDispatcherException(
                    'Error initializing handler: ' + handlerName + '. ' + e.getMessage()
                );
            }
        }
        return null;
    }

    private static Boolean isFeatureApplicable(TriggerFeature__mdt control, TriggerContext context) {
        return control.IsActive__c &&
            isOperationEnabled(control, context.operation) &&
            !shouldBypassTrigger(control) &&
            hasRequiredPermission(control);
    }

    private static Boolean shouldBypassTrigger(TriggerFeature__mdt control) {
        if (String.isNotBlank(control.BypassPermission__c)) {
            return FeatureManagement.checkPermission(control.BypassPermission__c);
        }
        return false;
    }

    private static Boolean hasRequiredPermission(TriggerFeature__mdt control) {
        if (String.isNotBlank(control.RequiredPermission__c)) {
            return FeatureManagement.checkPermission(control.RequiredPermission__c);
        }
        return true; // If no required permission is specified, return true
    }

    private static TriggerContext createTriggerContext(Boolean isAsyncMode) {
        return new TriggerContext(
            Trigger.operationType,
            Trigger.old,
            Trigger.new,
            Trigger.oldMap,
            Trigger.newMap,
            Trigger.isExecuting,
            Trigger.isInsert,
            Trigger.isUpdate,
            Trigger.isDelete,
            Trigger.isUndelete,
            Trigger.isBefore,
            Trigger.isAfter,
            Trigger.size,
            isAsyncMode
        );
    }

    private static Boolean isOperationEnabled(TriggerFeature__mdt control, TriggerOperation operation) {
        switch on operation {
            when BEFORE_INSERT {
                return control.BeforeInsert__c;
            }
            when AFTER_INSERT {
                return control.AfterInsert__c;
            }
            when BEFORE_UPDATE {
                return control.BeforeUpdate__c;
            }
            when AFTER_UPDATE {
                return control.AfterUpdate__c;
            }
            when BEFORE_DELETE {
                return control.BeforeDelete__c;
            }
            when AFTER_DELETE {
                return control.AfterDelete__c;
            }
            when AFTER_UNDELETE {
                return control.AfterUndelete__c;
            }
            when else {
                return false;
            }
        }
    }

    private static List<TriggerFeature__mdt> getControls(String sObjectName) {
        if (Test.isRunningTest() && mockControlsMap.containsKey(sObjectName)) {
            return mockControlsMap.get(sObjectName);
        }

        if (cachedControlsMap.isEmpty()) {
            List<TriggerFeature__mdt> allFeatures = [
                SELECT
                    DeveloperName,
                    Handler__c,
                    IsActive__c,
                    LoadOrder__c,
                    BeforeInsert__c,
                    AfterInsert__c,
                    BeforeUpdate__c,
                    AfterUpdate__c,
                    BeforeDelete__c,
                    AfterDelete__c,
                    AfterUndelete__c,
                    Asynchronous__c,
                    SObjectName__c,
                    BypassPermission__c,
                    RequiredPermission__c
                FROM TriggerFeature__mdt
                ORDER BY SObjectName__c, LoadOrder__c ASC
            ];

            for (TriggerFeature__mdt feature : allFeatures) {
                if (!cachedControlsMap.containsKey(feature.SObjectName__c)) {
                    cachedControlsMap.put(feature.SObjectName__c, new List<TriggerFeature__mdt>());
                }
                cachedControlsMap.get(feature.SObjectName__c).add(feature);
            }
        }

        return cachedControlsMap.containsKey(sObjectName)
            ? cachedControlsMap.get(sObjectName)
            : new List<TriggerFeature__mdt>();
    }

    @TestVisible
    private static void setMockControls(String sObjectName, List<TriggerFeature__mdt> mockControls) {
        mockControlsMap.put(sObjectName, mockControls);
    }

    private class AsynchronousFeatureExecution implements System.Queueable {
        private ITriggerExecutable handler;
        private TriggerContext context;
        private String handlerName;
        private String operation;
        private String sObjectName;

        private AsynchronousFeatureExecution(ITriggerExecutable handler, TriggerContext context, String handlerName, String operation, String sObjectName) {
            this.handler = handler;
            this.context = context;
            this.handlerName = handlerName;
            this.operation = operation;
            this.sObjectName = sObjectName;
        }


        public void execute(System.QueueableContext qc) {
            if (TriggerMetrics.isMetricsEnabled()) {
                TriggerMetrics.startMetrics(handlerName, operation, sObjectName, context.size);
            }
            this.handler.execute(this.context);
            if (TriggerMetrics.isMetricsEnabled()) {
                TriggerMetrics.endMetrics(handlerName, operation, sObjectName);
            }
        }
    }

    public class TriggerDispatcherException extends Exception {
    }
}
