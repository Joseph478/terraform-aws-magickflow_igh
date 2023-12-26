

# bucket magickbucket is not required
resource "aws_s3_bucket" "s3_bucket" {
    bucket = "magickbucket${var.name_main}"
    force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
    bucket = aws_s3_bucket.s3_bucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
    depends_on = [aws_s3_bucket_ownership_controls.ownership_controls]
    bucket = aws_s3_bucket.s3_bucket.id
    acl    = "private"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
    bucket = "codepipeline-bucket-${var.name_main}"
    force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_ownership_controls" {
    bucket = aws_s3_bucket.codepipeline_bucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
    depends_on = [ aws_s3_bucket_ownership_controls.codepipeline_ownership_controls ]
    bucket = aws_s3_bucket.codepipeline_bucket.id
    acl    = "private"
}

resource "aws_codecommit_repository" "codecommit_repository" {
    repository_name = "Repository_${var.name_main}"
    description     = "This is the project private"
    default_branch = "main"
    tags = {
        "ENV" = "PROD"
    }
}


data "aws_iam_policy_document" "iam_policy_document_codebuild" {
    statement {
        effect = "Allow"
        
        actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        ]

        resources = [
                "arn:aws:logs:${var.region}:348484763444:log-group:/aws/codebuild/docker-build-${var.name_main}",
                "arn:aws:logs:${var.region}:348484763444:log-group:/aws/codebuild/docker-build-${var.name_main}:*"
            ]
        
    }

    statement {
        effect = "Allow"

        actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
        ]

        resources = ["*"]
    }

    statement {
        effect    = "Allow"
        actions   = ["ec2:CreateNetworkInterfacePermission"]
        resources = ["arn:aws:ec2:${var.region}:${var.account_id}:network-interface/*"]

        condition {
            test     = "StringEquals"
            variable = "ec2:Subnet"
            values = var.private_subnets
        }

        condition {
            test     = "StringEquals"
            variable = "ec2:AuthorizedService"
            values   = ["codebuild.amazonaws.com"]
        }
    }

    statement {
        effect  = "Allow"
        actions = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        resources = [
            aws_s3_bucket.codepipeline_bucket.arn,
            "${aws_s3_bucket.codepipeline_bucket.arn}/*",
            aws_s3_bucket.s3_bucket.arn,
            "${aws_s3_bucket.s3_bucket.arn}/*"
        ]
    }

    statement {
        effect = "Allow"
        actions = [
                "codecommit:GitPull"
            ]
        resources = [
                # "arn:aws:codecommit:us-east-1:348484763444:hudbay"
                aws_codecommit_repository.codecommit_repository.arn
            ]
    }
    statement {
        effect = "Allow"
        actions = [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ]
        resources = [
            # "arn:aws:codebuild:us-east-1:348484763444:report-group/docker-build-hudbay-dev*"
            "arn:aws:codebuild:${var.region}:${var.account_id}:project/docker-build-${var.name_main}",
            "arn:aws:codebuild:${var.region}:${var.account_id}:project/docker-build-${var.name_main}/*"
        ]
    }
}
resource "aws_iam_policy" "iam_policy" {
    name        = "CodeBuildBasePolicy-docker-build-${var.name_main}"
    description = "IAM Policy for logs, ec2 and s3"
    policy = data.aws_iam_policy_document.iam_policy_document_codebuild.json
}

resource "aws_iam_role" "iam_role" {
    name               = "codebuild-docker-build-service-role-${var.name_main}"
    assume_role_policy = file("${path.module}/iamPolicies/assume_role_policy.json")
    managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess", aws_iam_policy.iam_policy.arn]
}

resource "aws_codebuild_project" "codebuild_project" {
    name           = "docker-build-${var.name_main}"
    description    = "codebuild_project_${var.name_main}"
    # build_timeout  = 5
    # queued_timeout = 5

    service_role = aws_iam_role.iam_role.arn

    source {
        type            = "CODECOMMIT"
        # location        = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/hudbay"
        location        = aws_codecommit_repository.codecommit_repository.clone_url_http
        git_clone_depth = 1
    }

    artifacts {
        # type = "NO_ARTIFACTS"
        name = "build_output"
        location = aws_s3_bucket.codepipeline_bucket.bucket
        type = "S3"
        path = "/"
        packaging = "ZIP"
    }

    # cache {
    #     type  = "LOCAL"
    #     modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
    # }

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        
        image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
        type                        = "LINUX_CONTAINER"
        image_pull_credentials_type = "CODEBUILD"

        environment_variable {
            name  = "ENV"
            value = "PROD"
        }
    }

    tags = {
        Environment = "Test"
    }
}

resource "aws_kms_key" "a" {}

resource "aws_kms_alias" "a" {
    name          = "alias/KmsKey${var.name_main}"
    target_key_id = aws_kms_key.a.key_id
}

data "aws_kms_alias" "s3kmskey" {
    name = aws_kms_alias.a.name
}

data "aws_iam_policy_document" "assume_role" {
    statement {
        effect = "Allow"

        principals {
            type        = "Service"
            identifiers = ["codepipeline.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

data "aws_iam_policy_document" "codepipeline_policy" {
    statement {
        actions = [
            "iam:PassRole"
        ]
        resources = ["*"]
        effect = "Allow"
        condition {
            test     = "StringEqualsIfExists"
            variable = "iam:PassedToService"

            values = [
                "cloudformation.amazonaws.com",
                "elasticbeanstalk.amazonaws.com",
                "ec2.amazonaws.com",
                "ecs-tasks.amazonaws.com"
            ]
        }
    }
    statement {
        effect = "Allow"  
        actions = [
            "ecs:*",
        ]  
        resources = ["*"] 
    }
    statement {
        effect = "Allow"

        actions = [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObjectAcl",
            "s3:PutObject",
        ]

        resources = [
            aws_s3_bucket.codepipeline_bucket.arn,
            "${aws_s3_bucket.codepipeline_bucket.arn}/*",
            aws_s3_bucket.s3_bucket.arn,
            "${aws_s3_bucket.s3_bucket.arn}/*"
        ]
    }

    # statement {
    #     effect    = "Allow"
    #     actions   = ["codestar-connections:UseConnection"]
    #     resources = [aws_codestarconnections_connection.example.arn]
    # }
    statement {
        effect = "Allow"  
        actions = [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetUploadArchiveStatus",      
        "codecommit:UploadArchive"
        ]  
        resources = ["*"] 
    }
    statement {
        effect = "Allow"

        actions = [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        ]

        resources = ["*"]
    }
    statement {
        effect = "Allow"
        actions = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ]
        resources = [
            data.aws_kms_alias.s3kmskey.arn
        ]
    }

}

resource "aws_iam_role" "codepipeline_role" {
    name               = "codepipeline-role-${var.name_main}"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
    name   = "codepipeline_policy-${var.name_main}"
    role   = aws_iam_role.codepipeline_role.id
    policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_codepipeline" "codepipeline" {
    name     = "ECS_pipeline_${var.name_main}"
    role_arn = aws_iam_role.codepipeline_role.arn

    artifact_store {
        location = aws_s3_bucket.codepipeline_bucket.bucket
        type     = "S3"

        # encryption_key {
        #     id   = data.aws_kms_alias.s3kmskey.arn
        #     type = "KMS"
        # }
    }

    stage {
        name = "Source"

        action {
            name             = "Source"
            category         = "Source"
            owner            = "AWS"
            provider         = "CodeCommit"
            version          = "1"
            output_artifacts = ["source_output"]

            configuration = {
                RepositoryName = aws_codecommit_repository.codecommit_repository.repository_name
                BranchName       = "main"
                PollForSourceChanges = var.pollForSourceChanges
            }
        }
    }

    stage {
        name = "Build"

        action {
            name             = "Build"
            category         = "Build"
            owner            = "AWS"
            provider         = "CodeBuild"
            input_artifacts  = ["source_output"]
            output_artifacts = ["build_output"]
            namespace        = "BuildVariables"
            version          = "1"

            configuration = {
                ProjectName = aws_codebuild_project.codebuild_project.name
            }
        }
    }

    stage {
        name = "Deploy"

        action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ECS"
        input_artifacts = ["source_output"]
        version         = "1"

        configuration = {
            ClusterName = var.cluster_name
            ServiceName = var.service_name
            FileName    = "imagedefinitions.json"
            # DeploymentTimeout: "15"
        }
        }
    }
}