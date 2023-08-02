# Create application infrastructure

```shell
terragrunt run-all apply
```


## Inspecting the infrastructure using bastion connection

```shell
ssh-add ~/.ssh/<path-to-ssh-key>.pem
ssh -A ec2-user@<bastion-ip-address>
```

The `-A` flag will enable ssh-agent forwarding so you can use the ssh key to authenticate
into services in the infrastructure.
