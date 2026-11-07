# vpc cni is installed on the eks cluster. It does the pod networking plus IP assigning to PODS
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}

# kube-proxy is responsible for implementing Kubernetes Service networking on the nodes to forward traffic to the pods. 
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

#CoreDNS provides DNS resolution inside the Kubernetes cluster for service stable cluster IP with DNS Name configured in the ngix.conf
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}
