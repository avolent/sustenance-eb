variable "project_name" {
  type        = string
  description = "Your project name, it will be used for naming resources"
  default     = "sustenance"
}

variable "commit_id" {
  type        = string
  description = "Commit id used for version label."
}

variable "commit_description" {
  type = string
  description = "Commit description used for version description"
}

variable "root_domain" {
  type        = string
  description = "The root domain name that you will be using"
  default     = "avolent.cloud"
}

variable "sub_domain" {
  type        = string
  description = "The subdomain under you hosted domain to use"
  default     = "sustenance"
}

variable "aws_region" {
  type        = string
  description = "The default aws region"
}