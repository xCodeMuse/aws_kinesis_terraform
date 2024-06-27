variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "region" {
   description = "aws region"
   type = string
   default = null
}

variable "data_streams" {
  description = "A map of kinesis data streams"
  type = map(object({
    name = string
    shard_count = number
    retention_period = number
    firehose_delivery = bool
    firehose_config = map(object({
      name = string
      destination = string
      cloudwatch_stream_arn = string #cloudwatch_metrics_stream.arn
      http_endpoint_config = map(object({
        name = string
        kloudfuse_endpoint = string
        retry_duration = optional(number)
        bucket_arn = string
        s3_backup_mode = string
        access_key = string
        buffering_size = optional(number)
        buffering_interval = optional(number)
        bucket_buffering_size = optional(number)
        bucket_buffering_interval = optional(number)
        compression_format = optional(string)
        content_encoding = optional(string)
      }))
    }))
  }))
} 