/**
 * Created by vncasolns on 2024-02-01.
 */
trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandler.run(Schema.Account.SObjectType);
}
