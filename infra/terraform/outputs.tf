# outputs.tf
output "control_plane_public_ips" {
  description = "Public IPs of control plane nodes"
  value       = aws_instance.control_plane[*].public_ip
}

output "control_plane_private_ips" {
  description = "Private IPs of control plane nodes"
  value       = aws_instance.control_plane[*].private_ip
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = aws_instance.worker[*].public_ip
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = aws_instance.worker[*].private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.cluster.id
}
