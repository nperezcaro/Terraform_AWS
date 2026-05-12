output "vpc_id"   { value = aws_vpc.this.id }
output "vpc_cidr" { value = aws_vpc.this.cidr_block }

output "public_subnet_ids"  { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }

output "public_route_table_id"   { value = aws_route_table.public.id }
output "private_route_table_ids" { value = aws_route_table.private[*].id }

output "nat_gateway_ids" { value = aws_nat_gateway.this[*].id }

output "igw_id" {
  description = "Internet Gateway ID — used by the EC2 module's EIP depends_on."
  value       = aws_internet_gateway.this.id
}
