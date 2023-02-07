package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

type tfOutputs struct {
	Manager_stack_id                         string
	Access_control_iam_policies_for_tfstates struct {
		Common     string
		Manager    *string
		Sub_stacks []string
	}
	Dyndb_backend_locks_table struct {
		Arn  string
		Name string
	}
	Replica_bucket struct {
		Name          string
		Region        string
		Sse_kms_alias string
	}
	Tfstate_backends_bucket struct {
		Name          string
		Region        string
		Sse_kms_alias string
	}
}

func TestTerraformBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// website::tag::1::Set the path to the Terraform code that will be tested.
		// The path to where our Terraform code is located
		TerraformDir: "../examples/simple/tfstate-s3-manager",

		// Variables to pass to our Terraform code using -var options
		//Vars: map[string]interface{}{
		//	"example_map":  expectedMap,
		//},

		// Variables to pass to our Terraform code using -var-file options
		//VarFiles: []string{"varfile.tfvars"},

		// Disable colors in Terraform commands so it's easier to parse stdout/stderr
		NoColor: true,
	})

	// website::tag::4::Clean up resources with "terraform destroy". Using "defer" runs the command at the end of the test, whether the test succeeds or fails.
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// website::tag::2::Run "terraform init" and "terraform apply".
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	var outputs tfOutputs
	terraform.OutputStruct(t, terraformOptions, "tfstate_backends_manager", &outputs)

	// website::tag::3::Check the output against expected values.
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "us-east-1", outputs.Tfstate_backends_bucket.Region)
	assert.Equal(t, "us-west-1", outputs.Replica_bucket.Region)
}
