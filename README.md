# chaostoolkit-starter-pack-aws
A starter pack full of ChaosToolkit experiments for AWS infrastructure

### Failover db cluster RDS

failover is more realistic when done with reboot_db_instance with `force_failover=True`

### Service resiliency ideas

- [ ] Resource Failure: Introduce failures in the underlying infrastructure, such as terminating instances, disabling load balancers, or throttling network bandwidth. Observe how your autoscaling system detects and responds to these failures, and ensure it scales resources accordingly to maintain service availability.

### Service scalability ideas
- [x] Load Testing: Simulate a sudden spike in traffic or a surge in the number of requests to your service. This can help determine if your autoscaling mechanism responds appropriately and scales up the resources to handle the increased load effectively.

- [ ] Scale-In Optimization: Gradually reduce the load on your system while monitoring how your autoscaling system scales down resources. Evaluate if the autoscaling algorithm effectively detects decreased demand and gracefully releases unnecessary resources without prematurely scaling down or causing service degradation.

- [ ] Scaling Delays: Introduce delays or slowdowns in the scaling process. This could involve delaying the provisioning of new instances or deliberately slowing down the termination of idle instances. Observe the impact on the responsiveness of your service and evaluate if the scaling mechanism is resilient enough to handle such delays.

- [ ] Metrics Threshold Breach: Manipulate the metrics thresholds used for triggering autoscaling, such as CPU utilization or request queue length. Increase or decrease these thresholds to see how your autoscaling system adjusts resource allocation based on changing conditions. This helps ensure the autoscaling mechanism is properly tuned and responds accurately to different metrics thresholds.
    Hypothesis could be that under load the CPU and memory utilisation should be between 50 and 80 percent so we're not wasting compute power.

- [ ] Capacity Planning: Gradually increase the load on your system over an extended period to observe how your autoscaling mechanism adapts to changing demand. This can help identify if there are any scaling limitations, such as slow provisioning times, or if there are instances where the autoscaling fails to meet the required capacity.

- [ ] Auto Healing: Introduce failures in individual instances or services within your infrastructure. Monitor if your autoscaling system detects the failures, terminates the faulty instances, and replaces them with new ones automatically. This ensures your autoscaling mechanism has the ability to self-heal and maintain service availability.
    This type of testing could be targeting service healthchecks, if service becomes unresponsive the target group should terminate the instance and replace it.

- [ ] Autoscaling Outliers: Introduce abnormal or extreme spikes in traffic that go beyond the expected patterns. This helps validate if your autoscaling mechanism can handle outlier scenarios and scale resources accordingly without impacting the overall system stability.

- [ ] Network Partition: Simulate network partitions or isolated clusters within your infrastructure. This experiment tests how your autoscaling system behaves when instances or services become temporarily unreachable or when communication between components is disrupted. It helps assess the resilience of your autoscaling mechanism under network-related failures.

- [ ] Cold Start Testing: Trigger autoscaling when there is little to no existing load on the system. This experiment evaluates the effectiveness of your autoscaling mechanism in efficiently provisioning and scaling up resources to handle sudden increases in traffic, even from a completely idle state.

- [ ] Preemptible Instances: If you're using preemptible instances or spot instances in your autoscaling setup, intentionally terminate some of these instances to simulate interruptions. Observe how your autoscaling system reacts to these instance terminations and whether it can quickly replace them with new instances.

- [ ] Failure Injection: Introduce intentional failures in various components of your autoscaling system, such as the scaling manager or monitoring system. This experiment helps assess the resilience and fault tolerance of your autoscaling infrastructure and how it handles failures in critical components.
    This could be an interesting scenario: whenever we have multiple scaling policies, make sure we can rely on each policy to scale the service by testing them individually, disable all alarms except cpu scaling for instance.

- [ ] Autoscaling Speed: Test the responsiveness and speed of your autoscaling system by rapidly increasing the load and monitoring how quickly it scales up resources to handle the increased demand. Measure the time it takes for the system to detect the need for scaling, provision new resources, and make them available for handling requests.
    What's interesting about this would be using probes in the method execution to measure how long it takes to detect the increased traffic. A custom probe could do that and report it back in the journal. Then we need a way to use those information.

- [ ] Seasonal Traffic: Simulate different seasonal patterns in your workload, such as holiday spikes or weekday/weekend variations. This experiment helps ensure your autoscaling system can handle and adapt to fluctuating demand patterns over extended periods.
    Could be interesting to simulate the effects of a promotion or a very hot page that generates a lot of GET traffic

- [ ] Resource Constraints: Introduce limitations on the availability of specific resources, such as limiting the number of available instances or reducing the capacity of a specific service. Observe how your autoscaling system adjusts to these constraints and whether it maintains service levels within the available resources.
    Interesting case of resource optimisation. Could be interesting to test the scaling on containers with smaller cpu/memory combination

- [ ] Service Dependency Failure: Introduce failures in dependent services or components and observe how your autoscaling system responds to the degradation or unavailability of these dependencies. Evaluate if it scales resources accordingly to maintain the overall service stability.
    Interesting case to see if a slower dependency could affect cpu/memory, hance being picked up by the autoscaler

- [ ] Network Latency: Introduce network latency or increased round-trip times between components of your infrastructure. This experiment helps evaluate the impact of network delays on the scaling behavior and response times of your autoscaling system.
    ??? how do we simulate network latency without a service mesh??

- [ ] Configuration Drift: Inject changes in the autoscaling configuration, such as scaling thresholds or policies, and monitor how the system adapts to the new configuration. Validate if the autoscaling mechanism correctly reflects the updated settings and responds accordingly.
    What does `adapt` means? Should it reset the configuration automatically or maybe send a notification that the policy has changed with the new values?

- [ ] Eviction Testing: Simulate eviction scenarios where instances are terminated or resources are reclaimed due to pricing changes or other factors. Observe how your autoscaling system handles these evictions and if it can effectively replace the lost resources to maintain service levels.
    Is this another case for the spot instances termination?

- [ ] Autoscaling Constraints: Test the behavior of your autoscaling system when it reaches certain limits or constraints, such as maximum instance capacity or maximum scaling rate. Evaluate if the system handles these constraints gracefully and maintains stability.
    In this case should we verify the system can notify us that the service has scaled to its maximum capacity? Should we test for the notification in SNS?

- [ ] Instance Hibernation: Experiment with hibernation or suspension of idle instances to conserve resources during low-demand periods. Assess how your autoscaling system identifies and hibernates idle instances and promptly resumes them when demand increases.
    Does this apply to services that run on EC2? Should we maybe have the option to deploy services with Ec2 clusters rather than FARGATE?

## Simulating AZ Failure

Refer to this [aws lab](https://catalog.us-east-1.prod.workshops.aws/workshops/5fc0039f-9f15-47f8-aff0-09dc7b1779ee/en-US/030-basic-content/090-scenarios/010-simulating-az-issues/020-impact-ec2-asg) to implemnet AZ failure for ECS services
