#!/bin/bash
set -e

echo "Building Netflix Clone for Netlify deployment..."
npx vite build

if [ -d "dist" ]; then
  echo "Build successful! Output directory: dist"
  echo "Ready for Netlify deployment"
else
  echo "Build failed. Please check for errors."
  exit 1
fi