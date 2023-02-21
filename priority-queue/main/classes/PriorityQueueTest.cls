/**
 * @description test functionality of priority queue processor
 * @author Andi Xie
 */ 
@SuppressWarnings('PMD')
@isTest
public class PriorityQueueTest {
    /**
     * @description test the execution priority when executing synchronously 
     * GIVEN: 3 queues with priority Low, Medium, High (ordinal value 1, 2, 3)
     * WHEN: Priority Queue Executes
     * THEN: It should be executed in the order of High, Medium, Low
     */ 
    @IsTest
    static void testPrioritySynchronousExecutionWithPriority() {
        TestContext testContext = new TestContext();
        testContext.expected = new List<String>{ '3', '3', '3', '2', '1' };
        PriorityQueue queue = PriorityQueue.getQueue();

        Mock mock = new Mock(testContext);
        Test.setMock(HttpCalloutMock.class, mock);

        queue.addItem(new PriorityTestItem('1'), PriorityQueue.Priority.values()[1]);
        queue.addItem(new PriorityTestItem('2'), PriorityQueue.Priority.values()[2]);
        queue.addItem(new PriorityTestItem('3'), PriorityQueue.Priority.values()[3]);
        queue.addItem(new PriorityTestItem('3'), PriorityQueue.Priority.values()[3]);
        queue.addItem(new PriorityTestItem('3'), PriorityQueue.Priority.values()[3]);
        
        
        queue.next();

        System.assertEquals(testContext.expected.size(), mock.testContext.actual.size());

        for (Integer i = 0; i < testContext.expected.size(); i++) {
            System.assertEquals(testContext.expected[i], mock.testContext.actual[i]);
        }
    }

    /**
     * @description test singleton
     */ 
    @IsTest
    static void testSingleton(){
        PriorityQueue queue1 = PriorityQueue.getQueue();
        Priorityqueue queue2 = PriorityQueue.getQueue();
        System.assertEquals(queue1, queue2);
    }

    /**
     * @description test the execution with priority is not explicitly given synchronously
     * GIVEN: 3 queues with priority Low, Medium, High (ordinal value 1, 2, 3)
     * WHEN: Priority Queue Executes
     * THEN: All the jobs should have been executed
     */ 
    @IsTest
    static void testPrioritySynchronousExecutionWithDefaultPriorities() {
        PriorityQueue queue = PriorityQueue.getQueue();
        TestContext testContext = new TestContext();
        testContext.expected = new List<String>{ '6', '5', '4', '3', '2', '1' };

        Mock mock = new Mock(testContext);
        Test.setMock(HttpCalloutMock.class, mock);

        for (String context : testContext.expected) {
            queue.addItem(new PriorityTestItem(context));
        }
        queue.next();

        System.assertEquals(testContext.expected.size(), mock.testContext.actual.size());
    }

    /**
     * @description test the execution priority when executing asynchronously 
     * GIVEN: 3 queues with priority Low, Medium, High (ordinal value 1, 2, 3)
     * WHEN: Priority Queue Executes
     * THEN: It should be executed in the order of High, Medium, Low
     */   
    @IsTest
    static void testPriorityAsynchronousExecution() {
        PriorityQueue queue = PriorityQueue.getQueue();
        TestContext testContext = new TestContext();
        testContext.expected = new List<String>{ '3', '2', '1' };

        Mock mock = new Mock(testContext);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        for (String context : testContext.expected) {
            PriorityQueue.Priority priority = PriorityQueue.Priority.values()[Integer.valueOf(context)];

            PriorityTestItem item = new PriorityTestItem(context);
            // can only have depth 1 Queue chaining under test context
            if (context == '1') {
                item.executeAsynchronously = true;
            }
            queue.addItem(item, priority);
        }
        queue.next();
        Test.stopTest();

        System.assertEquals(testContext.expected.size(), mock.testContext.actual.size());

        for (Integer i = 0; i < testContext.expected.size(); i++) {
            System.assertEquals(testContext.expected[i], mock.testContext.actual[i]);
        }
    }

    /**
     * @description test the execution with priority is not explicitly given asynchronously
     * GIVEN: 3 queues with priority Low, Medium, High (ordinal value 1, 2, 3)
     * WHEN: Priority Queue Executes
     * THEN: All the jobs should have been executed
     */ 
    @IsTest
    static void testPriorityAsynchronousExecutionWithDefaultPriority() {
        PriorityQueue queue = PriorityQueue.getQueue();
        TestContext testContext = new TestContext();
        testContext.expected = new List<String>{ '5', '3', '2', '1', '0' };

        Mock mock = new Mock(testContext);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        for (String context : testContext.expected) {
            PriorityTestItem item = new PriorityTestItem(context);
            // can only have depth 1 Queue chaining under test context
            if (context == '1') {
                item.executeAsynchronously = true;
            }
            queue.addItem(item);
        }
        queue.next();
        Test.stopTest();

        System.assertEquals(testContext.expected.size(), mock.testContext.actual.size());
    }

    /**
     * @description test the unhandled exception logging
     * GIVEN: few PriorityQueueables are queued up to be executed
     * WHEN: one of them throws exception in the middle of execution
     * THEN: all items should still be executed
     */ 
    @IsTest
    static void testPriorityExecutionExceptionLogs() {
        PriorityQueue.insertLogQueueAsynchronously = true;
        PriorityQueue queue = PriorityQueue.getQueue();
        TestContext testContext = new TestContext();
        testContext.expected = new List<String>{ '5', '4', '3', '2', '1', '1' };

        Mock mock = new Mock(testContext);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        for (String context : testContext.expected) {
            PriorityTestItem item = new PriorityTestItem(context);
            // throw exception for one of the item 
            if (context == testContext.expected[3]) {
                item.throwException = true;
            }
            queue.addItem(item);
        }
        queue.next();
        Test.stopTest();

        System.assertEquals(testContext.expected.size() - 1, mock.testContext.actual.size());
    }

    // callout mock seems to be the simplest way to keep a global context for asynchronous apex without writing to db
    class PriorityTestItem implements PriorityQueueable {
        public Boolean throwException = false;
        public Boolean executeAsynchronously = false;
        public String context;
        public Boolean getExecuteAsynchronouslyFlag() {
            return executeAsynchronously;
        }

        public PriorityTestItem(String context) {
            this.context = context;
        }

        public void execute() {
            if (throwException) {
                throw new CalloutException();
            }
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://test.com');
            request.setMethod('POST');
            request.setBody(context);
            http.send(request);
        }

        public String getContext() {
            return context;
        }
    }

    class TestContext {
        public List<String> expected = new List<String>();
        public List<String> actual = new List<String>();
    }

    class Mock implements HttpCalloutMock {
        public TestContext testContext;
        public Mock(TestContext context) {
            this.testContext = context;
        }
        public HttpResponse respond(HttpRequest request) {
            testContext.actual.add(request.getBody());
            return new HttpResponse();
        }
    }
}
