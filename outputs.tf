output "mk8s" {
  value = <<EOF
      ##############################
      #         EC2 - MK8S         #
      ##############################
        AMI: ${module.ec2.ami}
        IP: ${module.ec2.public_ip}
    EOF
}