/**
 * @description singleton that used to execute a list of PriorityQueuables jobs based the on the priority given
 *              purpose is to allow adding additional jobs during runtime in the same queueable contgext
 *              Example: 
 *              callout -> write logs -> handle error which includes callout and or insert logs. 
 *              This also provides a corse levels of control in the order of execution and execution context (execute synchronously after last job)
 * @author Andi Xie
 */

public with sharing class PriorityQueue {
    public static Boolean insertLogQueueAsynchronously = !Test.isRunningTest(); 
    static PriorityQueue priorityQueue;
    List<Wrapper> allItems;
    Wrapper currentItem;

    /**
     * @description isPriorityQueue currently executing
     * @return   return isExecuting
     */
    public static Boolean isExecuting { get; private set; }

    private PriorityQueue() {
        this.allItems = new List<Wrapper>{null};
    }

    /**
     * @description getQueue description
     * @return   return description
     */
    public static PriorityQueue getQueue() {
        if(priorityQueue == null) {
            isExecuting = false;
            priorityQueue = new PriorityQueue();
        } else {
            isExecuting = true;
        }
        return priorityQueue;
    }

    // heap impl -------------
    // https://en.wikipedia.org/wiki/Heap_(data_structure)

    private Integer getParentIndex(Integer index) {
        if (index == 1) {
            return null;
        }
        // same as Math.floor(index / 2);
        return index >> 1;
    }

    private Integer getLeftChildIndex(Integer parentIndex) {
        Integer res = parentIndex * 2;
        if (res < allItems.size()) {
            return res;
        }
        return null;
    }

    private Integer getRightChildIndex(Integer parentIndex) {
        Integer res = (parentIndex * 2) + 1;
        if (res < allItems.size()) {
            return res;
        }
        return null;
    }

    private Wrapper pop() {
        if (allItems.size() == 2) {
            return allItems.remove(allItems.size() - 1);
        }

        Wrapper res = allItems[1];
        allItems[1] = allItems.remove(allItems.size() - 1);

        Integer parentIndex = 1;

        while (getLeftChildIndex(parentIndex) != null) {
            Wrapper parent = allItems[parentIndex];
            Wrapper left = allItems[getLeftChildIndex(parentIndex)];
            Wrapper right = getRightChildIndex(parentIndex) == null? null : allItems[getRightChildIndex(parentIndex)];

            if ((right == null || left.compareTo(right) < 0) && left.compareTo(parent) < 0) {
                swapItem(parentIndex, getLeftChildIndex(parentIndex));
                parentIndex = getLeftChildIndex(parentIndex);
            } else if (right != null && right.compareTo(parent) < 0) {
                swapItem(parentIndex, getRightChildIndex(parentIndex));
                parentIndex = getRightChildIndex(parentIndex);
            } else {
                break;
            }
        }

        return res;
    }

    private void push(Wrapper item) {
        Wrapper curr = item;
        Integer currIndex = this.allItems.size();
        allItems.add(curr);
        Integer parentIndex = getParentIndex(currIndex);

        while (parentIndex != null) {
            Wrapper parent = allItems[parentIndex];
            
            if (curr.compareTo(parent) >= 0) {
                break;
            }

            swapItem(currIndex, parentIndex);
            parentIndex = getParentIndex(currIndex);
            currIndex = parentIndex;
        }

    }

    private void swapItem(Integer index1, Integer index2) {
        Wrapper temp = allItems[index1];
        allItems[index1] = allItems[index2];
        allItems[index2] = temp;
    }

    // end heap impl -------------



    /**
     * @description addItem to the queue
     * @param  priorityQueueable item
     * @param  priority          priority description
     */ 
    public void addItem(PriorityQueueable priorityQueueable, Priority priority) {
        push(wrap(priorityQueueable, priority));
    }


    /**
     * @description add items to the priority queue with specific priority
     * @param  priorityQueueables list of PriorityQueueable jobs
     * @param  priority           priority
     */ 
    public void addItems(List<PriorityQueueable> priorityQueueables, Priority priority) {
        for (PriorityQueueable priorityQueueable : priorityQueueables) {
            addItem(priorityQueueable, priority);
        }
    }

    /**
     * @description add items to priority queue without specifying priority
     * @param  priorityQueueables list of PriorityQueuable jobs
     */ 
    public void addItems(List<PriorityQueueable> priorityQueueables) {
        addItems(priorityQueueables, null);
    }

    /**
     * @description add a single item to priority queue without specifying priority
     * @param  priorityQueueable PriorityQueuable job
     */ 
    public void addItem(PriorityQueueable priorityQueueable) {
        addItem(priorityQueueable, null);
    }

    void execute() {
        if(priorityQueue == null) {
            priorityQueue = this;
        }
        try {
            System.debug(LoggingLevel.DEBUG, 'Executing Priority Queueable class: ' + currentItem.priorityQueueable.getContext());
            currentItem.execute();
            System.debug(LoggingLevel.DEBUG, 'Finished Executing Priority Queueable class: ' + currentItem.priorityQueueable.getContext());
        } catch (Exception ex) {
            // log and move on
            system.debug(LoggingLevel.WARN, 'PriorityQueue item execution has failed. context: ' + currentItem.priorityQueueable.getContext());
            system.debug(LoggingLevel.ERROR, 'Exception Message ' + ex.getMessage() + '\n Stack trace: ' + ex.getStackTraceString());
        }
        next();
    }

    /**
     * @description dequeue next item and execute
     */ 
    public void next() {
        if (allItems == null || allItems.size() == 1) {
            return;
        }
        
        system.debug(LoggingLevel.DEBUG, 'Current PriorityQueue items remaining: ' + (allItems.size() - 1));

        currentItem = pop();

        if (currentItem.useQueue) {
            System.enqueueJob(new QueueableWrapper(this));
            return;
        }

        execute();
    }

    Wrapper wrap(PriorityQueueable priorityQueueable, Priority xPriority) {
        if (xPriority == null) {
            xPriority = Priority.LOW;
        }

        return new Wrapper(priorityQueueable, xPriority);
    }

    @SuppressWarnings('PMD')
    public class QueueableWrapper implements Queueable, Database.AllowsCallouts {
        PriorityQueue priorityQueue;

        public QueueableWrapper(PriorityQueue priorityQueue) {
            this.priorityQueue = priorityQueue;
        }

        public void execute(QueueableContext ctx) {
            priorityQueue.execute();
        }
    }

    @SuppressWarnings('PMD')
    public class Wrapper implements Comparable {
        PriorityQueueable priorityQueueable;
        Priority priority;
        Boolean useQueue {
            get {
                return priorityQueueable.getExecuteAsynchronouslyFlag();
            }
        }

        private Wrapper(PriorityQueueable priorityQueueable, Priority priority) {
            this.priorityQueueable = priorityQueueable;
            this.priority = priority;
        }

        public Integer compareTo(Object compareToObject) {
            Wrapper comparedTo = (Wrapper) compareToObject;
            return comparedTo.priority.ordinal() - priority.ordinal();
        }

        public void execute() {
            priorityQueueable.execute();
        }
    }

    // please keep enum in the order of ascending priorities as we are sorting by ordinal value of the enum
    public enum Priority {
        LOWEST,
        LOW,
        MEDIUM,
        HIGH
    }
    
}
