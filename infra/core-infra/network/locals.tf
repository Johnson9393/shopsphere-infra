# It splits the one flat list of private subnets into 3 lists, one for each environment.
# The VPC module returns every private subnet together, in the same order as private_subnets in nonprod.tfvars.
# The dev EKS cluster needs only the dev IDs, and the same for qa and uat.


# The outer loop runs once for dev, once for qa, and once for uat
# For each name, the inner loop walks the six private subnets. index is the position in that list, and module.vpc.private_subnet_ids[index] is the AWS subnet ID at that same position. startswith(subnet.prefix, "${env}-") keeps the ID only when the prefix starts with that environment.

# output example:
# subnets IDs would be output from these subnets
# {
#  dev = [subnet-id of 10.0.10.0/24, subnet-id of 10.0.11.0/24]
#  qa  = [subnet-id of 10.0.20.0/24, subnet-id of 10.0.21.0/24]
#  uat = [subnet-id of 10.0.30.0/24, subnet-id of 10.0.31.0/24]
#  } 

locals {
  private_subnet_ids_by_environment = {
    for env in var.environments :
    env => [
      for index, subnet in var.private_subnets :
      module.vpc.private_subnet_ids[index]
      if startswith(subnet.prefix, "${env}-")
    ]
  }
}
