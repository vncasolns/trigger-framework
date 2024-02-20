/**
 * Created by vncasolns on 2024-02-01.
 */
public class TriggerHandler {
    private static Map<Schema.SObjectType, List<FeatureToken>> featureTokensCache = new Map<Schema.SObjectType, List<FeatureToken>>();

    private static Map<String, List<TriggerFeature__mdt>> featuresCache;

    @TestVisible
    private static void setMocks(String sobjectName, List<TriggerFeature__mdt> mockControls) {
        featuresCache = new Map<String, List<TriggerFeature__mdt>>();
        featuresCache.put(sobjectName, mockControls);
    }

    /**
     * Executes the trigger handler for the given SObjectType.
     * It creates a new TriggerContext and populates it with the current trigger state.
     * Then it executes the features that are applicable for the current operation.
     *
     * @param sObjectType The SObjectType for which the trigger handler is being run.
     */
    public static void run(Schema.SObjectType sObjectType) {
        TriggerContext context = new TriggerContext();
        context.sObjectType = sObjectType;
        context.newList = Trigger.new;
        context.oldList = Trigger.old;
        context.newMap = Trigger.newMap;
        context.oldMap = Trigger.oldMap;
        context.operation = Trigger.operationType;
        context.isInsert = Trigger.isInsert;
        context.isUpdate = Trigger.isUpdate;
        context.isDelete = Trigger.isDelete;
        context.isUndelete = Trigger.isUndelete;
        context.isBefore = Trigger.isBefore;
        context.isAfter = Trigger.isAfter;
        context.size = Trigger.size;
        executeFeatures(context);
    }

    private static void executeFeatures(TriggerContext context) {
        for (FeatureToken token : getFeatureTokens(context.sObjectType)) {
            if (!token.isApplicable(context.operation)) {
                continue;
            }
            if (token.isActive()) {
                if (token.isAsynchronous()) {
                    System.enqueueJob(new AsynchronousFeatureExecution(token.getHandler(), context));
                } else {
                    token.getHandler().execute(context);
                }
            }
        }
    }

    private static List<FeatureToken> getFeatureTokens(Schema.SObjectType sObjectType) {
        if (!featureTokensCache.containsKey(sObjectType)) {
            featureTokensCache.put(sObjectType, new List<FeatureToken>());
            for (TriggerFeature__mdt config : getFeaturesBySObjectName(String.valueOf(sObjectType))) {
                if (!getExcludedUsernamesInLowercase(config).contains(UserInfo.getUserName())) {
                    featureTokensCache.get(sObjectType).add(new FeatureToken(config));
                }
            }
        }
        return featureTokensCache.get(sObjectType);
    }

    private static List<TriggerFeature__mdt> getFeaturesBySObjectName(String sObjectName) {
        if (featuresCache == null) {
            featuresCache = new Map<String, List<TriggerFeature__mdt>>();
            for (TriggerFeature__mdt config : [
                SELECT
                    Id,
                    DeveloperName,
                    AfterDelete__c,
                    AfterInsert__c,
                    AfterUndelete__c,
                    AfterUpdate__c,
                    Asynchronous__c,
                    BeforeDelete__c,
                    BeforeInsert__c,
                    BeforeUpdate__c,
                    Handler__c,
                    IsActive__c,
                    LoadOrder__c,
                    SObjectName__c,
                    UsernamesToExclude__c
                FROM TriggerFeature__mdt
                ORDER BY SObjectName__c, LoadOrder__c
            ]) {
                if (!featuresCache.containsKey(config.SObjectName__c)) {
                    featuresCache.put(config.SObjectName__c, new List<TriggerFeature__mdt>());
                }
                featuresCache.get(config.SObjectName__c).add(config);
            }
        }
        return featuresCache.containsKey(sObjectName)
            ? featuresCache.get(sObjectName)
            : new List<TriggerFeature__mdt>();
    }

    private class FeatureToken {
        TriggerFeature__mdt config;
        ITriggerExecutable handler;

        private FeatureToken(TriggerFeature__mdt config) {
            this.config = config;
        }

        private TriggerFeature__mdt getConfig() {
            return this.config;
        }

        private ITriggerExecutable getHandler() {
            if (this.handler == null) {
                this.handler = (ITriggerExecutable) initializeHandlerInstance(
                    this.getConfig().Handler__c,
                    ITriggerExecutable.class
                );
            }
            return this.handler;
        }

        private Boolean isActive() {
            return this.getConfig().IsActive__c;
        }

        private Boolean isAsynchronous() {
            return this.getConfig().Asynchronous__c;
        }

        private Boolean isApplicable(System.TriggerOperation operation) {
            if (operation == System.TriggerOperation.BEFORE_INSERT && this.getConfig().BeforeInsert__c) {
                return true;
            }
            if (operation == System.TriggerOperation.AFTER_INSERT && this.getConfig().AfterInsert__c) {
                return true;
            }
            if (operation == System.TriggerOperation.BEFORE_UPDATE && this.getConfig().BeforeUpdate__c) {
                return true;
            }
            if (operation == System.TriggerOperation.AFTER_UPDATE && this.getConfig().AfterUpdate__c) {
                return true;
            }
            if (operation == System.TriggerOperation.BEFORE_DELETE && this.getConfig().BeforeDelete__c) {
                return true;
            }
            if (operation == System.TriggerOperation.AFTER_DELETE && this.getConfig().AfterDelete__c) {
                return true;
            }
            if (operation == System.TriggerOperation.AFTER_UNDELETE && this.getConfig().AfterUndelete__c) {
                return true;
            }
            return false;
        }
    }

    private class AsynchronousFeatureExecution implements System.Queueable {
        private ITriggerExecutable handler;
        private TriggerContext context;

        private AsynchronousFeatureExecution(ITriggerExecutable handler, TriggerContext context) {
            this.handler = handler;
            this.context = context;
        }

        public void execute(System.QueueableContext qc) {
            this.handler.execute(this.context);
        }
    }

    private static Object initializeHandlerInstance(String apexClassName, System.Type targetType) {
        if (String.isNotBlank(apexClassName)) {
            System.Type classType = Type.forName(apexClassName);
            if (classType == null) {
                throw new IllegalArgumentException(
                    String.format(
                        'ERROR: The apex class {0} was not found.',
                        new List<Object>{ apexClassName }
                    )
                );
            }
            if (!targetType.isAssignableFrom(classType)) {
                throw new IllegalArgumentException(
                    String.format(
                        'ERROR: The apex class {0} does not implement {1} interface.',
                        new List<Object>{ apexClassName, String.valueOf(targetType) }
                    )
                );
            }
            return classType.newInstance();
        }
        return null;
    }

    private static Set<String> getExcludedUsernamesInLowercase(TriggerFeature__mdt config) {
        Set<String> excludedUserNamesLowercase = new Set<String>();
        if (config.UsernamesToExclude__c != null) {
            for (String username : config.UsernamesToExclude__c.split('\\s*;\\s*')) {
                excludedUserNamesLowercase.add(username.toLowerCase());
            }
        }
        return excludedUserNamesLowercase;
    }
}
