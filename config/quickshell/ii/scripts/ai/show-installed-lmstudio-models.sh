#!/usr/bin/env bash

# Fetch models from LMStudio server (default: localhost:1234)
LMS_HOST="${LMS_HOST:-localhost}"
LMS_PORT="${LMS_PORT:-1234}"
LMS_URL="http://${LMS_HOST}:${LMS_PORT}/v1/models"

# Try to fetch models from LMStudio
response=$(curl -s "$LMS_URL" 2>/dev/null)

# Check if response is valid JSON
if ! echo "$response" | jq -e . >/dev/null 2>&1; then
    echo "[]"
    exit 0
fi

# Extract model names from the response
model_names=$(echo "$response" | jq -r '.data[].id' 2>/dev/null)

# Build a JSON array
json_array="["
first=true
for name in $model_names; do
    if [ "$first" = true ]; then
        first=false
    else
        json_array+=","
    fi
    json_array+="\"$name\""
done

# Close the array
json_array+="]"

# Output the JSON array
echo "$json_array"
