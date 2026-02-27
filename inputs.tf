variable "account_id" {
    description = "Account id"
    type = string
}
variable "name_main" {
    description = "Name main"
    type        = string
}
variable "private_subnets" {
    description = "Private Subnets of VPC"
    type = list(string)
}
variable "cluster_name" {
    description = "Cluster name"
    type        = string
}
variable "service_name" {
    description = "Service name"
    type        = string
}
variable "region" {
    default = "us-east-1"
    description = "Name of region"
    type        = string
}
variable "pollForSourceChanges" {
    default = false
    description = "Option Codepipeline"
    type = bool
}
variable "source_type" {
    default     = "codecommit"
    description = "Source provider for the pipeline. Allowed values: 'codecommit', 'github'"
    type        = string

    validation {
        condition     = contains(["codecommit", "github"], var.source_type)
        error_message = "source_type must be 'codecommit' or 'github'."
    }
}

variable "github_owner" {
    default     = ""
    description = "GitHub organization or user name. Required when source_type = 'github'"
    type        = string
}

variable "github_repo" {
    default     = ""
    description = "GitHub repository name. Required when source_type = 'github'"
    type        = string
}

variable "github_branch" {
    default     = "main"
    description = "GitHub branch to track. Used when source_type = 'github'"
    type        = string
}

variable "github_oauth_token" {
    default     = ""
    description = "GitHub personal access token. Required when source_type = 'github'"
    type        = string
    sensitive   = true
}
