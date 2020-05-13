data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10"
}

module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "11.0.0"

  cluster_name       = var.cluster_name
  subnets            = var.subnet_ids
  write_kubeconfig   = true
  config_output_path = pathexpand("~/.kube/${var.tenant_name}-${var.cluster_name}")
  kubeconfig_name    = "${var.tenant_name}-${var.cluster_name}"
  worker_additional_security_group_ids = [
    module.eks_worker_sg.id,
  ]

  vpc_id = var.vpc_id

  # worker_additional_security_group_ids = []
  # workers_additional_policies = []

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  workers_additional_policies = [
    "${aws_iam_policy.eks_assume_role.arn}",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]

  workers_group_defaults = {
    key_name               = var.key_name
    public_ip              = var.worker_public_ip
    root_volume_size       = 50
    instance_type          = "t2.medium"
    asg_recreate_on_change = true
    additional_userdata    = <<EOF
#!/bin/bash
cd /tmp
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
EOF
  }

  worker_groups_launch_template = [
    {
      name                    = "medium"
      override_instance_types = ["t3.medium", "t2.medium", "t3a.medium"]
      asg_max_size            = var.medium_asg_max_size
      asg_min_size            = var.medium_asg_min_size
      asg_desired_capacity    = var.medium_asg_desired_capacity
      on_demand_base_capacity = var.medium_asg_on_demand_base_capacity
      bootstrap_extra_args    = "--use-max-pods false"
      #kubelet_extra_args      = "--node-labels=kubernetes.io/size=medium"

      tags = [
        {
          "key"                 = "Name"
          "propagate_at_launch" = "true"
          "value"               = "${var.cluster_name}-medium"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${var.tenant_name}-${var.cluster_name}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/node-template/label/type"
          "propagate_at_launch" = "false"
          "value"               = "medium"
        },
      ]
    },
  ]

  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}

resource "aws_iam_policy" "eks_assume_role" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "kube2iam",
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${var.aws_account_id}:role/k8s-*"
    }
  ]
}
EOF
}

# this security group is used to provide identity for workers and is used as source group for other groups (like mysql in hosting account)
module "eks_worker_sg" {
  source = "../sg"

  name   = "eks-worker-${var.cluster_name}"
  vpc_id = var.vpc_id
}

output "eks_worker_sg_id" {
  value = module.eks_worker_sg.id
}