#!/bin/bash

declare -A PIPELINE_FILES_MAP # Declare associative array: pipeline:space-separated list of file patterns
declare -A TRIGGERED_PIPELINES=() # Track triggered pipelines
declare -A PIPELINE_EXCLUDE_FILES_MAP

# pipelines with some files to trigger

PIPELINE_FILES_MAP["vikranth-cicd-pipeline-1"]="newdir/"

PIPELINE_FILES_MAP["vikranth-cicd-pipeline-2"]="somefile.txt"

# excludes list

# PIPELINE_EXCLUDE_FILES_MAP["vikranth-cicd-pipeline-3"]="newdir/abcd"

# trigger always


# Get changed files in the latest commit
CHANGED_FILES=()
while IFS= read -r line; do
  CHANGED_FILES+=("$line")
done < <(git show --pretty="" --name-only HEAD)
echo "files changed: ${CHANGED_FILES[@]}"

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

# Check for pipelines that should trigger on all changes except excluded files
for pipeline in "${!PIPELINE_EXCLUDE_FILES_MAP[@]}"; do
  excludes=${PIPELINE_EXCLUDE_FILES_MAP[$pipeline]}
  trigger=true

  for changed_file in "${CHANGED_FILES[@]}"; do
    matched_exclude=false
    for exclude in $excludes; do
      if [[ "$changed_file" == "$exclude"* ]]; then
        matched_exclude=true
        break
      fi
    done

    if ! $matched_exclude; then
      trigger=true
      break
    else
      trigger=false
    fi
  done

  if $trigger; then
    echo "Changes not fully excluded for $pipeline → triggering"
    TRIGGERED_PIPELINES["$pipeline"]=1
  else
    echo "All changes matched exclude list for $pipeline → not triggering"
  fi
done

# Print and trigger
for pipeline in "${!TRIGGERED_PIPELINES[@]}"; do
  echo "Triggering $pipeline..."
  aws codebuild start-build --project-name "$pipeline"
done

# If nothing matched
if [[ ${#TRIGGERED_PIPELINES[@]} -eq 0 ]]; then
  echo "No matching changes. No pipelines triggered."
fi
