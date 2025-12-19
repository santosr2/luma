module github.com/santosr2/helm-luma

go 1.21

require (
	github.com/santosr2/luma-go v0.1.0
	github.com/spf13/cobra v1.8.0
	gopkg.in/yaml.v3 v3.0.1
)

require (
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	github.com/yuin/gopher-lua v1.1.1 // indirect
)

replace github.com/santosr2/luma-go => ../../bindings/go
