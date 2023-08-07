# Experiment: Service Auto Scale-In

Verify that an ECS service autoscaling policies can scale-in containers effectively to optimize resource
utilisation.
The experiment sets the number of container count to the maximum allowed value and waits for the policy to
deregister resources until the desired task count matches the initial value.

## Business Value

Optimise resource and cost utilisation. Our scaling policies configuration should guarantee that services are not overprovisioned.
Evaluate if the autoscaling algorithm effectively detects decreased demand and gracefully releases unnecessary resources without prematurely scaling down or causing service degradation.

## System Requirements

**Additional Software**

* Grafana K6

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-grafana

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run \
    --hypothesis-strategy after-method-only \
    experiment.yaml
```
