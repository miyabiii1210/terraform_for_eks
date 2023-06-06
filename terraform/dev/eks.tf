# EKS Cluster
resource "aws_eks_cluster" "dev" {
  name                      = local.sig
  version                   = "1.26"
  role_arn                  = aws_iam_role.dev-eks-cluster.arn
  enabled_cluster_log_types = []
  vpc_config {
    subnet_ids = [
      aws_subnet.dev-private-a.id,
      aws_subnet.dev-private-c.id,
    ]
    security_group_ids = [
      aws_security_group.dev-eks-tf.id
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.dev-eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.dev-eks-AmazonEKSVPCResourceController
  ]
  tags = (merge(local.default_tags,
    {
      "alpha.eksctl.io/cluster-oidc-enabled" = "true"
    }
  ))
}

# IAM Role Policy for EKS Cluster
resource "aws_iam_role" "dev-eks-cluster" {
  name = "${local.sig}-eks-cluster-iam"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
        }
      ]
      Version = "2012-10-17"
    }
  )
  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "dev-eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.dev-eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "dev-eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.dev-eks-cluster.name
}


# EKS Node Group
resource "aws_eks_node_group" "dev-primary" {
  cluster_name    = aws_eks_cluster.dev.name
  node_group_name = "${local.sig}-primary-node-group"
  node_role_arn   = aws_iam_role.dev-node.arn
  capacity_type   = "ON_DEMAND"
  subnet_ids = [
    aws_subnet.dev-private-a.id,
    aws_subnet.dev-private-c.id,
  ]
  instance_types = ["t3.medium"]

  launch_template {
    version = "$Latest"
    id      = aws_launch_template.dev-eks-tf.id
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.dev-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.dev-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.dev-node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.dev-eks-AWSLoadBalancerControllerIAMPolicy,
  ]
}

# IAM Role Policy for EKS Node
resource "aws_iam_role" "dev-node" {
  name = "${local.sig}-node-group-iam"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "dev-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.dev-node.name
}

resource "aws_iam_role_policy_attachment" "dev-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.dev-node.name
}

resource "aws_iam_role_policy_attachment" "dev-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.dev-node.name
}

resource "aws_iam_role_policy_attachment" "dev-eks-AWSLoadBalancerControllerIAMPolicy" {
  policy_arn = "arn:aws:iam::XXXXXXXXXXX:policy/AWSLoadBalancerControllerIAMPolicy"
  role       = aws_iam_role.dev-node.name
}

# Security Group For EKS
resource "aws_launch_template" "dev-eks-tf" {
  vpc_security_group_ids = [aws_security_group.dev-eks-tf.id]
}

resource "aws_security_group" "dev-eks-tf" {
  vpc_id      = aws_vpc.dev.id
  name        = "${local.sig}-eks-tf-sg"
  description = "for EKS Security Group"
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.default_tags
}
