terraform {
  backend "s3" {
    bucket         = "terraform-states123456"
    key            = "portfolio-blog/terraform.tfstate"
    encrypt        = true
    region         = "us-east-2"
    profile        = "account1"
    use_lockfile   = true
  }
}

provider "aws" {
  region = "us-east-2"
  
  # Use profile only when running locally, not in CI/CD
  profile = terraform.workspace == "default" ? "account2" : null
  
  # This will work if you're using the OIDC method above
  assume_role {
    role_arn     = "arn:aws:iam::264509227929:role/blog_role"
    session_name = "TerraformSession"
  }
}
variable "domain_name" {
  default = "GH-blog.com"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "gh-blog-website-content"
  
  tags = {
    Name = "website-content"
  }
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/../../dist", "**/*")

  bucket       = aws_s3_bucket.website_bucket.id
  key          = each.value
  source       = "${path.module}/../../dist/${each.value}"
  etag         = filemd5("${path.module}/../../dist/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), null)
}

locals {
  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".ico"  = "image/x-icon"
  }
}

resource "aws_s3_bucket_ownership_controls" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.website_bucket.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "error.html"
  }
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-website-oac"
  description                       = "OAC for CloudFront to access S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website_cdn" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-${var.domain_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.domain_name}"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # For SPA routing
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]
    
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_origin_access_control.s3_oac.id]
    }
  }
}

resource "null_resource" "cloudfront_invalidation" {
  triggers = {
    # This will trigger an invalidation whenever any file changes
    file_hashes = sha256(join("", [for file in fileset("${path.module}/../../dist", "**/*") : filesha256("${path.module}/../../dist/${file}")]))
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website_cdn.id} --paths '/*'"
  }

  depends_on = [aws_s3_object.website_files]
}

output "s3_bucket_name" {
  value = aws_s3_bucket.website_bucket.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website_cdn.id
}

output "website_endpoint" {
  value = aws_cloudfront_distribution.website_cdn.domain_name
}