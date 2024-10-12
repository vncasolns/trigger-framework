/**
 * Created by sonal on 2024-10-11.
 */

trigger ContactTrigger on Contact(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    TriggerDispatcher.run(Schema.Contact.SObjectType);
}
