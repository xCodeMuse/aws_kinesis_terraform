locals {
  kinesis_http_data_stream_firehose = {
    for key, data_stream in var.var.data_streams : key => data_stream
    if data_stream.firehose_delivery
  }
}   

resource "aws_kinesis_stream" "data_stream" {
  for_each = var.data_streams

  name = each.value.name
  shard_count = each.value.shard_count
  retention_period = each.value.retention_period
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_delivery_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "firehose_delivery_policy"
  description = "Policy for Firehose to access resources"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:DescribeStream", "kinesis:ListStreams"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_kinesis_firehose_delivery_stream" "http_call_kloudfuse" {
  for_each = local.kinesis_http_data_stream_firehose

  name = each.value.firehose_config.name
  destination = each.value.firehose_config.destination
  http_endpoint_configuration {
    url                = each.value.firehose_config.http_endpoint_config.kloudfuse_endpoint # "https://kloudfuse.com/firehose/endpoint"
    name               = each.value.firehose_config.http_endpoint_config.name
    access_key         = each.value.firehose_config.http_endpoint_config.access_key
    buffering_size     = each.value.firehose_config.http_endpoint_config.buffering_size
    buffering_interval = each.value.firehose_config.http_endpoint_config.buffering_interval
    role_arn           = aws_iam_role.firehose_role.arn
    s3_backup_mode     = each.value.firehose_config.http_endpoint_config.s3_backup_mode # "FailedDataOnly"
    retry_duration = each.value.firehose_config.http_endpoint_config.retry_duration
    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = each.value.firehose_config.http_endpoint_config.url.bucket_arn
      buffering_size     = each.value.firehose_config.http_endpoint_config.bucket_buffering_size
      buffering_interval = each.value.firehose_config.http_endpoint_config.bucket_buffering_interval
      compression_format = each.value.firehose_config.http_endpoint_config.compression_format
    }

    request_configuration {
      content_encoding = each.value.firehose_config.http_endpoint_config.content_encoding
    #   Describes the metadata sent to the HTTP endpoint destination
    #   common_attributes {
    #     name  = "testname"
    #     value = "testvalue"
    #   }
    }
  }
}