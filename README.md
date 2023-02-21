# Install
<a style="background-color: #E7E7E7;
  border: none; 
  border-radius: 12px;
  color: black;
  padding: 10px 20px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  font-size: 12px;"
  href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t8a000001e65yAAA">Install to Sandbox</a>
  <br>
<a style="background-color: #4CAF50;
  border: none; 
  border-radius: 12px;
  color: white;
  padding: 10px 20px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  font-size: 12px;"
  href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t8a000001e65yAAA">Install to Prod</a>

# Overview
Priority Queue is a singleton utility that allows executing and chaining asynchronous jobs with corse control of order of execution. 

## Motivation
Salesforce's `Queuable` framework allows chaining natively, however there is a limitation on only 1 `Queueable` can be enqueued when executing asynchronously. We need something else if there is a need to enqueue multiple asynchronously jobs during runtime (e.g. logging dml and additional clean up logic).

# Process Flow

## Add item

```mermaid
 graph LR;
 A(add item) --> B(has priority?)
 B --> |no| C(set to low priority)
 B --> |yes| D(set priority)
 C --> E(add to list)
 D --> E
 E --> F(sort)
 ```

## Execution

```mermaid
 graph LR;
 A(Check if singleton is set) --> |yes| B(execute current item);
 A --> |no| C[Set singleton]
 C --> B
 B --> D(Is there next item in queue?)
 D --> |no| E(end)
 D --> |yes| F(next)
 F --> A 
```

# To use PriorityQueue

## Define a NTFH_PriorityQueueable
- Create a class implementing `PriorityQueueable` interface

## Adding item to priority queue
- Get the singleton object by calling the static method `PriorityQueue.getQueue();`
- Use the `addItem` or `addItems` method on the priority queue object to add an item to the queue

## Executing 
- If starting the priority queue, call the `next()` method on the singleton object will kick off the jobs.
- If adding a job when the priority queue is already running, no need to do anything. The job will be executed when it is its turn.