# Amazon API Gateway REST APIs with direct ALB integration
# Uses the new VPC Link v2 feature for direct ALB connectivity

############################
# API GATEWAY REST APIS
############################

# REST API per environment
resource "aws_api_gateway_rest_api" "main" {
  for_each = toset(var.workload_environments)

  name        = "${replace(local.customer_workload_name, ".", "-")}-${each.value}-api"
  description = "REST API for ${local.customer_workload_name} ${each.value} environment"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # Enable request validation
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-api"
    Environment = each.value
    Purpose     = "rest-api-gateway"
  })
}

############################
# API GATEWAY RESOURCES
############################

# Proxy resource for catch-all routing
resource "aws_api_gateway_resource" "proxy" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id
  parent_id   = aws_api_gateway_rest_api.main[each.value].root_resource_id
  path_part   = "{proxy+}"
}

# Health check resource
resource "aws_api_gateway_resource" "health" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id
  parent_id   = aws_api_gateway_rest_api.main[each.value].root_resource_id
  path_part   = "health"
}

############################
# API GATEWAY METHODS
############################

# ANY method for proxy resource
resource "aws_api_gateway_method" "proxy" {
  for_each = toset(var.workload_environments)

  rest_api_id   = aws_api_gateway_rest_api.main[each.value].id
  resource_id   = aws_api_gateway_resource.proxy[each.value].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# GET method for health check
resource "aws_api_gateway_method" "health" {
  for_each = toset(var.workload_environments)

  rest_api_id   = aws_api_gateway_rest_api.main[each.value].id
  resource_id   = aws_api_gateway_resource.health[each.value].id
  http_method   = "GET"
  authorization = "NONE"
}

# OPTIONS method for CORS
resource "aws_api_gateway_method" "proxy_options" {
  for_each = toset(var.workload_environments)

  rest_api_id   = aws_api_gateway_rest_api.main[each.value].id
  resource_id   = aws_api_gateway_resource.proxy[each.value].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

############################
# API GATEWAY INTEGRATIONS
############################

# Integration with ALB via VPC Link
resource "aws_api_gateway_integration" "proxy" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id
  resource_id = aws_api_gateway_resource.proxy[each.value].id
  http_method = aws_api_gateway_method.proxy[each.value].http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.aws_lb.eks_alb[each.value].dns_name}/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main[each.value].id

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [aws_api_gateway_vpc_link.main]
}

# Health check integration
resource "aws_api_gateway_integration" "health" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id
  resource_id = aws_api_gateway_resource.health[each.value].id
  http_method = aws_api_gateway_method.health[each.value].http_method

  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.aws_lb.eks_alb[each.value].dns_name}/health"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.main[each.value].id

  depends_on = [aws_api_gateway_vpc_link.main]
}

# CORS integration
resource "aws_api_gateway_integration" "proxy_options" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id
  resource_id = aws_api_gateway_resource.proxy[each.value].id
  http_method = aws_api_gateway_method.proxy_options[each.value].http_method

  type = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }

  depends_on = [aws_api_gateway_method.proxy_options]
}

############################
# API GATEWAY RESPONSES
############################

# CORS response for OPTIONS method
resource "aws_api_gateway_method_response" "proxy_options" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id
  resource_id = aws_api_gateway_resource.proxy[each.value].id
  http_method = aws_api_gateway_method.proxy_options[each.value].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_method.proxy_options]
}

# CORS integration response
resource "aws_api_gateway_integration_response" "proxy_options" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id
  resource_id = aws_api_gateway_resource.proxy[each.value].id
  http_method = aws_api_gateway_method.proxy_options[each.value].http_method
  status_code = aws_api_gateway_method_response.proxy_options[each.value].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.proxy_options]
}

############################
# API GATEWAY DEPLOYMENT
############################

# Deployment per environment
resource "aws_api_gateway_deployment" "main" {
  for_each = toset(var.workload_environments)

  rest_api_id = aws_api_gateway_rest_api.main[each.value].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy[each.value].id,
      aws_api_gateway_resource.health[each.value].id,
      aws_api_gateway_method.proxy[each.value].id,
      aws_api_gateway_method.health[each.value].id,
      aws_api_gateway_integration.proxy[each.value].id,
      aws_api_gateway_integration.health[each.value].id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_method.health,
    aws_api_gateway_integration.proxy,
    aws_api_gateway_integration.health,
  ]
}

# Stage per environment
resource "aws_api_gateway_stage" "main" {
  for_each = toset(var.workload_environments)

  deployment_id = aws_api_gateway_deployment.main[each.value].id
  rest_api_id   = aws_api_gateway_rest_api.main[each.value].id
  stage_name    = each.value

  # Enable logging
  access_log_destination_arn = aws_cloudwatch_log_group.api_gateway[each.value].arn
  access_log_format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    caller         = "$context.identity.caller"
    user           = "$context.identity.user"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    resourcePath   = "$context.resourcePath"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
    error          = "$context.error.message"
    errorType      = "$context.error.messageString"
  })

  # Enable X-Ray tracing
  xray_tracing_enabled = true

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-api-stage"
    Environment = each.value
    Purpose     = "api-gateway-stage"
  })

  depends_on = [aws_api_gateway_deployment.main]
}

############################
# CUSTOM DOMAIN NAMES
############################

# Custom domain name per environment
resource "aws_api_gateway_domain_name" "main" {
  for_each = toset(var.workload_environments)

  domain_name              = local.api_domain_names[each.value]
  regional_certificate_arn = data.aws_acm_certificate.main.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-api-domain"
    Environment = each.value
    Purpose     = "api-gateway-custom-domain"
  })
}

# Base path mapping
resource "aws_api_gateway_base_path_mapping" "main" {
  for_each = toset(var.workload_environments)

  api_id      = aws_api_gateway_rest_api.main[each.value].id
  stage_name  = aws_api_gateway_stage.main[each.value].stage_name
  domain_name = aws_api_gateway_domain_name.main[each.value].domain_name

  depends_on = [aws_api_gateway_stage.main]
}

############################
# CLOUDWATCH LOG GROUPS
############################

# CloudWatch log group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  for_each = toset(var.workload_environments)

  name              = "/aws/apigateway/${aws_api_gateway_rest_api.main[each.value].name}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-api-gateway-logs"
    Environment = each.value
    Purpose     = "api-gateway-access-logs"
  })
}