# Lookup: Availability Zone → index of the public subnet in that AZ.
# Used when need_single_ngw is false (one NAT per AZ). Each private subnet must
# send egress through the NAT in its own zone. The private subnet list order
# might not match the public subnet list order, so we cannot use count.index.
# Example: public[0]=us-east-1a, public[1]=us-east-1b → { "us-east-1a" = 0, "us-east-1b" = 1 }

locals {
  public_subnet_index_by_az = {
    for index, subnet in var.public_subnets : subnet.availability_zone => index
  }
}
