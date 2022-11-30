resource "aws_codeartifact_repository" "example" {
  repository = "example"
  domain     = "example"

  external_connections {
    external_connection_name = "public:maven-central"
  }
}