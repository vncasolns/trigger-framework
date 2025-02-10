public class TriggerMetrics {
    private static final String METRIC_PREFIX = 'TRIGGER_METRIC';
    @TestVisible
    private static Map<String, MetricSnapshot> metricSnapshots = new Map<String, MetricSnapshot>();
    private static Boolean isEnabled = false;

    private class MetricSnapshot {
        public String triggerHandler;
        public String operation;
        public String sObjectType;
        public Integer recordCount;
        public Long startTime;
        public Long endTime;
        public Long executionTime;
        public Long cpuTime;
        public Integer dmlRows;
        public Integer queryRows;
    }

    public static void enableMetrics() {
        isEnabled = true;
    }

    public static void disableMetrics() {
        isEnabled = false;
    }

    public static Boolean isMetricsEnabled() {
        return isEnabled;
    }

    public static void startMetrics(String triggerHandler, String operation, String sObjectType, Integer recordCount) {
        if (!isEnabled) return;

        String key = generateKey(triggerHandler, operation, sObjectType);
        MetricSnapshot snapshot = new MetricSnapshot();
        snapshot.triggerHandler = triggerHandler;
        snapshot.operation = operation;
        snapshot.sObjectType = sObjectType;
        snapshot.recordCount = recordCount;
        snapshot.startTime = System.now().getTime();
        snapshot.cpuTime = Limits.getCpuTime();
        snapshot.dmlRows = Limits.getDmlRows();
        snapshot.queryRows = Limits.getQueryRows();

        metricSnapshots.put(key, snapshot);

        logMetric('START', snapshot);
    }

    public static void endMetrics(String triggerHandler, String operation, String sObjectType) {
        if (!isEnabled) return;

        String key = generateKey(triggerHandler, operation, sObjectType);
        MetricSnapshot snapshot = metricSnapshots.get(key);

        if (snapshot != null) {
            snapshot.endTime = System.now().getTime();
            snapshot.executionTime = snapshot.endTime - snapshot.startTime;
            snapshot.cpuTime = Limits.getCpuTime() - snapshot.cpuTime;
            snapshot.dmlRows = Limits.getDmlRows() - snapshot.dmlRows;
            snapshot.queryRows = Limits.getQueryRows() - snapshot.queryRows;

            logMetric('END', snapshot);
            metricSnapshots.remove(key);
        }
    }

    private static void logMetric(String stage, MetricSnapshot snapshot) {
        Map<String, Object> logMap = new Map<String, Object>{
                'metric_type' => METRIC_PREFIX,
                'stage' => stage,
                'timestamp' => formatDateTime(stage == 'START' ? snapshot.startTime : snapshot.endTime),
                'handler' => snapshot.triggerHandler,
                'operation' => snapshot.operation,
                'sobject' => snapshot.sObjectType,
                'record_count' => snapshot.recordCount
        };

        if (stage == 'END') {
            logMap.put('execution_time_ms', snapshot.executionTime);
            logMap.put('cpu_time_ms', snapshot.cpuTime);
            logMap.put('dml_rows', snapshot.dmlRows);
            logMap.put('query_rows', snapshot.queryRows);
        }

        String logJson = JSON.serialize(logMap);
        System.debug(LoggingLevel.INFO, logJson);
    }

    private static String generateKey(String triggerHandler, String operation, String sObjectType) {
        return String.format('{0}_{1}_{2}', new String[]{triggerHandler, operation, sObjectType});
    }

    private static String formatDateTime(Long epochTime) {
        return Datetime.newInstance(epochTime).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
    }
}