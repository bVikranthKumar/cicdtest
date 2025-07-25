#!/usr/local/bin/bash

declare -A PIPELINE_FILES_MAP # Declare associative array: pipeline → space-separated list of file patterns
declare -A TRIGGERED_PIPELINES=() # Track triggered pipelines

PIPELINE_FILES_MAP["vikranth-cicd-pipeline-1"]="newdir/"
PIPELINE_FILES_MAP["vikranth-cicd-pipeline-2"]="somefile.txt"


# Get changed files in the latest commit
CHANGED_FILES=$(git show --pretty="" --name-only HEAD)
echo "${CHANGED_FILES[@]}"

# Loop over pipelines and check their file patterns
for pipeline in "${!PIPELINE_FILES_MAP[@]}"; do
   patterns=${PIPELINE_FILES_MAP[$pipeline]}

  for pattern in $patterns; do
    for changed_file in ${CHANGED_FILES[@]}; do
      if [[ "$changed_file" == "$pattern"* ]]; then
        echo "File '$changed_file' matched pattern '$pattern' → $pipeline"
        TRIGGERED_PIPELINES["$pipeline"]=1
      fi
    done
  done
done

echo "pipelines to be triggered are: ${!TRIGGERED_PIPELINES[@]}"

# Trigger each pipeline
for pipeline in "${!TRIGGERED_PIPELINES[@]}"; do
  echo "Triggering $pipeline..."
#   aws codebuild start-build --project-name "$pipeline"
done

# # If nothing matched
# if [[ ${#TRIGGERED_PIPELINES[@]} -eq 0 ]]; then
#   echo "No matching changes. No pipelines triggered."
# fi
