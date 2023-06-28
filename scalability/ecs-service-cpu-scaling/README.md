# Experiment: Service Autoscaling CPU Scale-Out

Verify that the configured scaling policies for the targeted service can scale-out resources on CPU only.
The experiment installs a CPU stressor on the service task definition and waits for autoscaling to automatically increase the number of desired tasks to the max.

## Business Value

Make sure the targeted service can cope with an unforeseen CPU spike and automatically spawn up more containers to handle user load.
A sudden CPU spike can have many causes that are unrelated to users' traffic: the release of new code, slow downstream dependencies, resource constraints. Scaling policies must ensure we can fulfill requests anyway by distributing incoming traffic to more replicas.

## System Requirements

**Python Packages**

* chaostoolkit-aws
* chaostoolkit-aws-attacks

## Running the experiment

```bash
PYTHONPATH=../../modules/ \
chaos run \
    --hypothesis-strategy after-method-only \
    experiment.yaml
```
