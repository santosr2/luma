module github.com/santosr2/luma/integrations/terraform

go 1.22

require (
	github.com/hashicorp/terraform-plugin-framework v1.7.0
	github.com/hashicorp/terraform-plugin-go v0.22.0
	github.com/hashicorp/terraform-plugin-log v0.9.0
	github.com/santosr2/luma-go v0.1.0
)

replace github.com/santosr2/luma-go => ../../bindings/go

