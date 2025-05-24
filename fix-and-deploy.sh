#!/bin/bash
set -e

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Netflix Clone deployment process...${NC}"

# Create a temporary directory for our clean repository
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}Created temporary directory: ${TEMP_DIR}${NC}"

# Clone the repository
echo -e "${BLUE}Cloning repository...${NC}"
git clone https://github.com/aritramahatma/Netflix.git "${TEMP_DIR}/netflix-clone"
cd "${TEMP_DIR}/netflix-clone"

# Check if .gitmodules exists and remove it
if [ -f .gitmodules ]; then
    echo -e "${BLUE}Found .gitmodules file, removing it...${NC}"
    rm .gitmodules
fi

# Check for any other submodule references in git config
echo -e "${BLUE}Cleaning up any submodule references...${NC}"
git config --local --get-regexp submodule | cut -d '.' -f 2 | xargs -r -n 1 git config --local --unset-all submodule.

# Remove .git/modules directory if it exists
if [ -d .git/modules ]; then
    echo -e "${BLUE}Removing .git/modules directory...${NC}"
    rm -rf .git/modules
fi

# Clean and reset the git repository
echo -e "${BLUE}Cleaning and resetting Git repository...${NC}"
git reset --hard HEAD
git clean -fd

# Create a new Netlify configuration file
echo -e "${BLUE}Creating Netlify configuration...${NC}"
cat > netlify.toml << 'EOF'
[build]
  command = "npm run build"
  publish = "dist/public"

[build.environment]
  NODE_VERSION = "18"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOF

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
npm install

# Run build
echo -e "${BLUE}Building the application...${NC}"
npm run build

# Check if build was successful and dist/public exists
if [ -d "dist/public" ]; then
    echo -e "${GREEN}Build successful! The application is ready to deploy.${NC}"
else
    # Check if just dist directory exists with the build output
    if [ -d "dist" ]; then
        echo -e "${BLUE}Build created 'dist' directory but not 'dist/public'. Checking output structure...${NC}"
        
        # If index.html exists in dist, we need to modify the Netlify config
        if [ -f "dist/index.html" ]; then
            echo -e "${BLUE}Found build output in 'dist' directory instead. Updating Netlify configuration...${NC}"
            cat > netlify.toml << 'EOF'
[build]
  command = "npm run build"
  publish = "dist"

[build.environment]
  NODE_VERSION = "18"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOF
            echo -e "${GREEN}Updated Netlify configuration to use 'dist' as publish directory.${NC}"
        else
            echo -e "${RED}Build may have failed. Could not find index.html in dist directory.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Build failed. dist directory does not exist.${NC}"
        exit 1
    fi
fi

# Create a README with deployment instructions
cat > README.md << 'EOF'
# Netflix Clone - Deployment Ready

This repository has been cleaned and prepared for Netlify deployment.

## Deployment Instructions

1. Push this repository to your GitHub account
2. Log in to Netlify (https://app.netlify.com/)
3. Click "New site from Git"
4. Choose GitHub and select your repository
5. Use the following build settings:
   - Build command: `npm run build`
   - Publish directory: `dist/public` (or `dist` if that's where your build output is)
6. Click "Deploy site"

The `netlify.toml` file in this repository already contains these settings.

## Local Development

To run this project locally:

```bash
npm install
npm run dev
