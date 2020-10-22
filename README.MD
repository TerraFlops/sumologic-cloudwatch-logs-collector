# Sumo Logic CloudWatch Logger

```
module "sumologic_cloudwatch_flow_logs" {
  source = "git::https://github.com/TerraFlops/sumologic-cloudwatch-logs-collector?ref=v1.0"
  log_group_name = "ExampleDevFlowLogs"
  category="Example/Dev/VpcFlowLogs"
}
```