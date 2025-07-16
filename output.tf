output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.example.public_ip
}

output "website_access_message" {
  value = "Now you can access the website: http://${aws_instance.example.public_ip}:8080"
}

output "installation_notes" {
  value = <<EOT
✅ Tomcat was successfully installed on your Amazon Linux EC2 instance.
✅ Your custom index.html was deployed to the ROOT directory of Tomcat.
👉 Visit http://${aws_instance.example.public_ip}:8080 in your browser to verify.
EOT
}
output "website_ready_message" {
  depends_on = [null_resource.wait_for_tomcat]
  value      = "🌐 Your site is ready! Visit: http://${aws_instance.example.public_ip}:8080"
}
