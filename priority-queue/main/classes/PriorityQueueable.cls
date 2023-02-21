/**
 * @description Implement to be able to use PriorityQueue to execute logic
 */
public interface PriorityQueueable {

    /**
     * @description execution logic
     */ 
    void execute();

    /**
     * @description indicates if the implemented priority queueable should be executing in an asynchronous execution context
     *              should be kept to true for most cases to isolate execution logic and limit possible interference
     * @return true to execute asynchronously false to execute synchronously
     */ 
    Boolean getExecuteAsynchronouslyFlag();

    /**
     * @description used by logger to log any debug information
     * @return   return context e.g. className
     */ 
    String getContext();
}
