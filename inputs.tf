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