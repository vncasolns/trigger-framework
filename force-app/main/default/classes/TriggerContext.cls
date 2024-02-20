/**
 * Created by vncasolns on 2024-02-01.
 */
public class TriggerContext {
    public System.TriggerOperation operation;
    public Boolean isInsert;
    public Boolean isUpdate;
    public Boolean isDelete;
    public Boolean isUndelete;
    public Boolean isBefore;
    public Boolean isAfter;
    public Integer size;
    public Schema.SObjectType sObjectType;
    public Map<Id, SObject> newMap;
    public Map<Id, SObject> oldMap;
    public List<SObject> newList;
    public List<SObject> oldList;

    /**
     * Returns the list of new or old SObjects based on the operation type.
     * For insert, update, or undelete operations, it returns the list of new SObjects.
     * For other operations, it returns the list of old SObjects.
     */
    public List<SObject> getPrimaryList() {
        if (this.isInsert || this.isUpdate || this.isUndelete) {
            return this.newList;
        } else {
            return this.oldList;
        }
    }

    /**
     * Returns the set of record IDs based on the operation type.
     * For insert, update, or undelete operations, it returns the set of new record IDs.
     * For other operations, it returns the set of old record IDs.
     */
    public Set<Id> getRecordIds() {
        if (this.isInsert || this.isUpdate || this.isUndelete) {
            return this.newMap.keySet();
        } else {
            return this.oldMap.keySet();
        }
    }

    /**
     * Checks if a specific field of an SObject has changed.
     * Returns true if the operation is an insert or if the field's current value is different from its old value.
     */
    public Boolean isChanged(SObject aObj, Schema.SObjectField aField) {
        return this.isInsert ||
            aObj.get(String.valueOf(aField)) != this.oldMap.get(aObj.Id).get(String.valueOf(aField));
    }

    /**
     * Checks if the current operation is a before insert.
     * Returns true if the operation is before and is an insert.
     */
    public Boolean beforeInsert() {
        return this.isBefore && this.isInsert;
    }

    /**
     * Checks if the current operation is an after insert.
     * Returns true if the operation is after and is an insert.
     */
    public Boolean afterInsert() {
        return this.isAfter && this.isInsert;
    }

    /**
     * Checks if the current operation is a before update.
     * Returns true if the operation is before and is an update.
     */
    public Boolean beforeUpdate() {
        return this.isBefore && this.isUpdate;
    }

    /**
     * Checks if the current operation is an after update.
     * Returns true if the operation is after and is an update.
     */
    public Boolean afterUpdate() {
        return this.isAfter && this.isUpdate;
    }

    /**
     * Checks if the current operation is a before delete.
     * Returns true if the operation is before and is a delete.
     */
    public Boolean beforeDelete() {
        return this.isBefore && this.isDelete;
    }

    /**
     * Checks if the current operation is an after delete.
     * Returns true if the operation is after and is a delete.
     */
    public Boolean afterDelete() {
        return this.isAfter && this.isDelete;
    }

    /**
     * Checks if the current operation is an after undelete.
     * Returns true if the operation is after and is an undelete.
     */
    public Boolean afterUndelete() {
        return this.isAfter && this.isUndelete;
    }

}
