variable "log_group_name" {
  type = string
  description = "Name of the CloudWatch log group"
}

variable "log_stream_prefix" {
  type = string
  description = "Log stream prefix"
  default = null
}

variable "category" {
  type = string
  description = "Sumo Logic source category name"
}

variable "exclude_filters" {
  type = set(string)
  description = "Set of regex filters used to exclude messages from being sent to Sumo Logic"
  default = []
}
