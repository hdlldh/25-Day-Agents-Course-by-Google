#!/bin/bash
# Day 04: Source-Based Deployment Script
# Deploy ADK agent to Vertex AI Agent Engine

set -e

# Configuration - Update these values
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-your-project-id}"
export GOOGLE_CLOUD_LOCATION="${GOOGLE_CLOUD_LOCATION:-us-central1}"
export STAGING_BUCKET="${STAGING_BUCKET:-gs://your-staging-bucket}"
export AGENT_NAME="deployed_assistant"

echo "=========================================="
echo "Day 04: Source-Based Deployment"
echo "=========================================="
echo "Project: $GOOGLE_CLOUD_PROJECT"
echo "Region:  $GOOGLE_CLOUD_LOCATION"
echo "Bucket:  $STAGING_BUCKET"
echo "Agent:   $AGENT_NAME"
echo "=========================================="

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        echo "Error: gcloud CLI not found. Install from https://cloud.google.com/sdk/docs/install"
        exit 1
    fi

    # Check uv
    if ! command -v uv &> /dev/null; then
        echo "Error: uv not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi

    # Check adk
    if ! command -v adk &> /dev/null; then
        echo "Installing google-adk..."
        pip install google-adk
    fi

    echo "All prerequisites met!"
}

# Authenticate with Google Cloud
authenticate() {
    echo "Authenticating with Google Cloud..."
    gcloud auth login
    gcloud config set project $GOOGLE_CLOUD_PROJECT
    gcloud auth application-default login
}

# Create staging bucket if needed
create_bucket() {
    BUCKET_NAME=$(echo $STAGING_BUCKET | sed 's|gs://||')
    if ! gsutil ls $STAGING_BUCKET &> /dev/null; then
        echo "Creating staging bucket: $STAGING_BUCKET"
        gsutil mb -l $GOOGLE_CLOUD_LOCATION $STAGING_BUCKET
    else
        echo "Staging bucket exists: $STAGING_BUCKET"
    fi
}

# Option 1: Deploy with ADK CLI
deploy_with_adk() {
    echo "Deploying with ADK CLI..."
    adk deploy agent_engine \
        --project $GOOGLE_CLOUD_PROJECT \
        --region $GOOGLE_CLOUD_LOCATION \
        --staging_bucket $STAGING_BUCKET \
        --trace_to_cloud \
        --display_name "$AGENT_NAME" \
        --description "Day 04 deployed assistant" \
        agent
}

# Option 2: Enhance existing project with Agent Starter Pack
enhance_project() {
    echo "Enhancing project with Agent Starter Pack..."
    cd ..
    uvx agent-starter-pack enhance --adk -d agent_engine
    cd day-04
}

# Option 3: Create new project with Agent Starter Pack
create_new_project() {
    echo "Creating new project with Agent Starter Pack..."
    uvx agent-starter-pack create $AGENT_NAME -a adk_base -d agent_engine
}

# Test locally before deployment
test_locally() {
    echo "Testing agent locally..."
    cd agent
    adk web
}

# Main menu
main() {
    echo ""
    echo "Choose an action:"
    echo "1) Check prerequisites"
    echo "2) Authenticate with Google Cloud"
    echo "3) Test agent locally"
    echo "4) Deploy with ADK CLI"
    echo "5) Enhance project with Agent Starter Pack"
    echo "6) Create new project with Agent Starter Pack"
    echo "q) Quit"
    echo ""
    read -p "Enter choice: " choice

    case $choice in
        1) check_prerequisites ;;
        2) authenticate ;;
        3) test_locally ;;
        4)
            check_prerequisites
            create_bucket
            deploy_with_adk
            ;;
        5) enhance_project ;;
        6) create_new_project ;;
        q) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
}

# Run main menu
main
