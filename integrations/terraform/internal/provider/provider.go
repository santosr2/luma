package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
)

// Ensure the implementation satisfies the expected interfaces.
var (
	_ provider.Provider = &lumaProvider{}
)

// New is a helper function to simplify provider server and testing implementation.
func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &lumaProvider{
			version: version,
		}
	}
}

// lumaProvider is the provider implementation.
type lumaProvider struct {
	// version is set to the provider version on release, "dev" when the
	// provider is built and ran locally, and "test" when running acceptance
	// testing.
	version string
}

// Metadata returns the provider type name.
func (p *lumaProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "luma"
	resp.Version = p.version
}

// Schema defines the provider-level schema for configuration data.
func (p *lumaProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Luma provider for rendering templates in Terraform configurations.",
		Attributes: map[string]schema.Attribute{
			"syntax": schema.StringAttribute{
				Optional:    true,
				Description: "Default syntax mode: 'auto', 'luma', or 'jinja'. Defaults to 'auto'.",
			},
		},
	}
}

// Configure prepares a Luma API client for data sources and resources.
func (p *lumaProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	// Provider configuration is minimal - just syntax preference
	// The actual Luma engine is stateless and doesn't need configuration
}

// DataSources defines the data sources implemented in the provider.
func (p *lumaProvider) DataSources(_ context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewTemplateDataSource,
	}
}

// Resources defines the resources implemented in the provider.
func (p *lumaProvider) Resources(_ context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewTemplateFileResource,
	}
}

