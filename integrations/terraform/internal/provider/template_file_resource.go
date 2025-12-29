package provider

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
	luma "github.com/santosr2/luma-go"
)

// Ensure the implementation satisfies the expected interfaces.
var (
	_ resource.Resource              = &templateFileResource{}
	_ resource.ResourceWithConfigure = &templateFileResource{}
)

// NewTemplateFileResource is a helper function to simplify the provider implementation.
func NewTemplateFileResource() resource.Resource {
	return &templateFileResource{}
}

// templateFileResource is the resource implementation.
type templateFileResource struct{}

// templateFileResourceModel describes the resource data model.
type templateFileResourceModel struct {
	ID           types.String `tfsdk:"id"`
	Template     types.String `tfsdk:"template"`
	TemplateFile types.String `tfsdk:"template_file"`
	Vars         types.Map    `tfsdk:"vars"`
	Destination  types.String `tfsdk:"destination"`
	FileMode     types.String `tfsdk:"file_mode"`
	Content      types.String `tfsdk:"content"`
}

// Metadata returns the resource type name.
func (r *templateFileResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_template_file"
}

// Schema defines the schema for the resource.
func (r *templateFileResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Renders a Luma template and writes it to a file.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:    true,
				Description: "Resource identifier (destination path).",
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"template": schema.StringAttribute{
				Optional:    true,
				Description: "The Luma template string to render. One of template or template_file must be specified.",
			},
			"template_file": schema.StringAttribute{
				Optional:    true,
				Description: "Path to a Luma template file. One of template or template_file must be specified.",
			},
			"vars": schema.MapAttribute{
				Optional:    true,
				ElementType: types.StringType,
				Description: "Variables to pass to the template context.",
			},
			"destination": schema.StringAttribute{
				Required:    true,
				Description: "Destination file path for the rendered template.",
			},
			"file_mode": schema.StringAttribute{
				Optional:    true,
				Description: "File permissions mode (e.g., '0644'). Defaults to '0644'.",
			},
			"content": schema.StringAttribute{
				Computed:    true,
				Description: "The rendered template content.",
			},
		},
	}
}

// Configure adds the provider configured client to the resource.
func (r *templateFileResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	// Provider configuration is not needed for stateless template rendering
}

// Create creates the resource and sets the initial Terraform state.
func (r *templateFileResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data templateFileResourceModel

	// Read plan
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Render and write template
	content, err := r.renderTemplate(ctx, &data, &resp.Diagnostics)
	if err != nil {
		return
	}

	// Write to file
	if err := r.writeFile(data.Destination.ValueString(), content, data.FileMode.ValueString()); err != nil {
		resp.Diagnostics.AddError(
			"File Write Error",
			fmt.Sprintf("Could not write file: %s", err.Error()),
		)
		return
	}

	// Set state
	data.ID = data.Destination
	data.Content = types.StringValue(content)
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

// Read refreshes the Terraform state with the latest data.
func (r *templateFileResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data templateFileResourceModel

	// Read state
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Check if file exists
	destination := data.Destination.ValueString()
	if _, err := os.Stat(destination); os.IsNotExist(err) {
		// File was deleted, remove from state
		resp.State.RemoveResource(ctx)
		return
	}

	// Read current file content
	content, err := os.ReadFile(destination)
	if err != nil {
		resp.Diagnostics.AddError(
			"File Read Error",
			fmt.Sprintf("Could not read file: %s", err.Error()),
		)
		return
	}

	// Update content in state
	data.Content = types.StringValue(string(content))
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

// Update updates the resource and sets the updated Terraform state on success.
func (r *templateFileResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var data templateFileResourceModel

	// Read plan
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Render and write template
	content, err := r.renderTemplate(ctx, &data, &resp.Diagnostics)
	if err != nil {
		return
	}

	// Write to file
	if err := r.writeFile(data.Destination.ValueString(), content, data.FileMode.ValueString()); err != nil {
		resp.Diagnostics.AddError(
			"File Write Error",
			fmt.Sprintf("Could not write file: %s", err.Error()),
		)
		return
	}

	// Set state
	data.Content = types.StringValue(content)
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

// Delete deletes the resource and removes the Terraform state on success.
func (r *templateFileResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data templateFileResourceModel

	// Read state
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Delete file
	destination := data.Destination.ValueString()
	if err := os.Remove(destination); err != nil && !os.IsNotExist(err) {
		resp.Diagnostics.AddError(
			"File Delete Error",
			fmt.Sprintf("Could not delete file: %s", err.Error()),
		)
		return
	}
}

// renderTemplate renders the template with vars
func (r *templateFileResource) renderTemplate(ctx context.Context, data *templateFileResourceModel, diags *resource.CreateResponseDiagnostics) (string, error) {
	// Get template source
	var template string
	if !data.Template.IsNull() {
		template = data.Template.ValueString()
	} else if !data.TemplateFile.IsNull() {
		content, err := os.ReadFile(data.TemplateFile.ValueString())
		if err != nil {
			diags.AddError(
				"Template File Read Error",
				fmt.Sprintf("Could not read template file: %s", err.Error()),
			)
			return "", err
		}
		template = string(content)
	} else {
		diags.AddError(
			"Missing Template",
			"Either template or template_file must be specified",
		)
		return "", fmt.Errorf("missing template")
	}

	// Convert vars map to Go map
	vars := make(map[string]interface{})
	if !data.Vars.IsNull() {
		varMap := make(map[string]string)
		diags.Append(data.Vars.ElementsAs(ctx, &varMap, false)...)
		if diags.HasError() {
			return "", fmt.Errorf("invalid vars")
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
		diags.AddError(
			"Template Render Error",
			fmt.Sprintf("Could not render template: %s", err.Error()),
		)
		return "", err
	}

	return result, nil
}

// writeFile writes content to a file with the specified permissions
func (r *templateFileResource) writeFile(path, content, modeStr string) error {
	// Parse file mode
	mode := os.FileMode(0644)
	if modeStr != "" {
		var m uint32
		if _, err := fmt.Sscanf(modeStr, "%o", &m); err != nil {
			return fmt.Errorf("invalid file mode: %s", modeStr)
		}
		mode = os.FileMode(m)
	}

	// Create directory if needed
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	// Write file
	return os.WriteFile(path, []byte(content), mode)
}

