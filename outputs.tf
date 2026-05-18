output "s3_bucket_id" {
    value = aws_s3_bucket.codepipeline_bucket.id
}

output "s3_bucket_arn" {
    value = aws_s3_bucket.codepipeline_bucket.arn
}

output "codebuild_project_arn" {
    value = aws_codebuild_project.codebuild_project.arn
}

output "codebuild_project_name" {
    value = aws_codebuild_project.codebuild_project.name
}

output "codebuild_project_id" {
    value = aws_codebuild_project.codebuild_project.id
}

output "codepipeline_arn" {
    value = aws_codepipeline.codepipeline.arn
}

output "codepipeline_id" {
    value = aws_codepipeline.codepipeline.id
}

output "iam_role_codebuild_arn" {
    value = aws_iam_role.iam_role.arn
}

output "iam_role_codepipeline_arn" {
    value = aws_iam_role.codepipeline_role.arn
}

output "kms_key_arn" {
    value = aws_kms_key.a.arn
}

output "kms_key_id" {
    value = aws_kms_key.a.key_id
}

output "codecommit_repository_id" {
    value = try(aws_codecommit_repository.codecommit_repository[0].repository_id, null)
}

output "codecommit_clone_url_http" {
    value = try(aws_codecommit_repository.codecommit_repository[0].clone_url_http, null)
}

output "github_connection_arn" {
    value = try(aws_codestarconnections_connection.github[0].arn, null)
}
