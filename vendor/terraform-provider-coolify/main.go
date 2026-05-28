package main

import (
	"context"
	"log"

	"github.com/arcusis/terraform-provider-coolify/internal/provider"
	"github.com/hashicorp/terraform-plugin-framework/providerserver"
)

// Beskid fork: destination_uuid, service urls (Coolify compose domains API).
var version = "1.1.19-beskid"

func main() {
	err := providerserver.Serve(context.Background(), provider.New(version), providerserver.ServeOpts{
		Address: "registry.terraform.io/arcusis/coolify",
	})
	if err != nil {
		log.Fatal(err)
	}
}
