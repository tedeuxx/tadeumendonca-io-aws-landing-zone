#!/bin/bash

# Script to configure Terraform Cloud credentials locally
# Usage: ./setup-local-terraform-cloud.sh YOUR_TERRAFORM_CLOUD_TOKEN

if [ -z "$1" ]; then
    echo "Usage: $0 <terraform-cloud-token>"
    echo ""
    echo "To get your token:"
    echo "1. Go to https://app.terraform.io/app/settings/tokens"
    echo "2. Create a new API token"
    echo "3. Copy the token and run: $0 <your-token>"
    exit 1
fi

TOKEN="$1"

# Create terraform.d directory if it doesn't exist
mkdir -p ~/.terraform.d

# Create credentials file
cat > ~/.terraform.d/credentials.tfrc.json << EOF
{
  "credentials": {
    "app.terraform.io": {
      "token": "$TOKEN"
    }
  }
}
EOF

echo "✅ Terraform Cloud credentials configured successfully!"
echo "📁 Credentials file: ~/.terraform.d/credentials.tfrc.json"
echo ""
echo "You can now run terraform commands locally that will use Terraform Cloud backend."
echo "Try: cd terraform && terraform init"