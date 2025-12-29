package provider

import (
	"context"
	"encoding/json"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
	luma "github.com/santosr2/luma-go"
)

// Ensure the implementation satisfies the expected interfaces.
var (
	_ datasource.DataSource              = &templateDataSource{}
	_ datasource.DataSourceWithConfigure = &templateDataSource{}
)

// NewTemplateDataSource is a helper function to simplify the provider implementation.
func NewTemplateDataSource() datasource.DataSource {
	return &templateDataSource{}
}

// templateDataSource is the data source implementation.
type templateDataSource struct{}

// templateDataSourceModel describes the data source data model.
type templateDataSourceModel struct {
	Template types.String `tfsdk:"template"`
	Vars     types.Map    `tfsdk:"vars"`
	Syntax   types.String `tfsdk:"syntax"`
	Result   types.String `tfsdk:"result"`
}

// Metadata returns the data source type name.
func (d *templateDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_template"
}

// Schema defines the schema for the data source.
func (d *templateDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Renders a Luma template with provided variables.",
		Attributes: map[string]schema.Attribute{
			"template": schema.StringAttribute{
				Required:    true,
				Description: "The Luma template string to render.",
			},
			"vars": schema.MapAttribute{
				Optional:    true,
				ElementType: types.StringType,
				Description: "Variables to pass to the template context.",
			},
			"syntax": schema.StringAttribute{
				Optional:    true,
				Description: "Syntax mode: 'auto' (default), 'luma', or 'jinja'.",
			},
			"result": schema.StringAttribute{
				Computed:    true,
				Description: "The rendered template output.",
			},
		},
	}
}

// Configure adds the provider configured client to the data source.
func (d *templateDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
	// Provider configuration is not needed for stateless template rendering
}

// Read refreshes the Terraform state with the latest data.
func (d *templateDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data templateDataSourceModel

	// Read configuration
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Prepare template and vars
	template := data.Template.ValueString()
	
	// Convert vars map to Go map
	vars := make(map[string]interface{})
	if !data.Vars.IsNull() {
		varMap := make(map[string]string)
		resp.Diagnostics.Append(data.Vars.ElementsAs(ctx, &varMap, false)...)
		if resp.Diagnostics.HasError() {
			return
		}
		
		// Convert string map to interface map (support JSON values)
		for k, v := range varMap {
			// Try to parse as JSON first (for complex types)
			var jsonValue interface{}
			if err := json.Unmarshal([]byte(v), &jsonValue); err == nil {
				vars[k] = jsonValue
			} else {
				// Use as string if not valid JSON
				vars[k] = v
			}
		}
	}

	// Render template
	result, err := luma.Render(template, vars)
	if err != nil {
		resp.Diagnostics.AddError(
			"Template Render Error",
			"Could not render template: "+err.Error(),
		)
		return
	}

	// Set result
	data.Result = types.StringValue(result)

	// Set state
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

