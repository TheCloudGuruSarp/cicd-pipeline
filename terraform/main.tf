provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "prod"

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = "${var.environment}-vpc"
    }
  )
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "18.20.5"

  cluster_name    = "${var.environment}-eks-cluster"
  cluster_version = "1.23"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    default = {
      min_size     = var.eks_min_size
      max_size     = var.eks_max_size
      desired_size = var.eks_desired_size

      instance_types = var.eks_instance_types
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = var.environment
      }

      tags = merge(
        var.tags,
        {
          Environment = var.environment
        }
      )
    }
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"
  version = "1.4.0"

  repository_name = "${var.environment}-microservice-app"
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "any",
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}