resource "aws_ecr_repository" "foo" {
    name                 = "bar"

    image_scanning_configuration {
        scan_on_push = true
    }
}