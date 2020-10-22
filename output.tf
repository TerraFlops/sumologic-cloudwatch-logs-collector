output "sumologic_collector_id" {
  description = "The ID of the Sumo Logic collector"
  value = sumologic_collector.collector.id
}

output "sumologic_source_id" {
  description = "The ID of the Sumo Logic HTTP source"
  value = sumologic_http_source.source.url
}

output "sumologic_source_url" {
  description = "The URL of the Sumo Logic HTTP source"
  value = sumologic_http_source.source.url
}
