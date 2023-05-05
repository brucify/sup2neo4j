#!/bin/bash
# 
# Copyright 2023 Bruce Yinhe
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

# Find all lines containing ", worker" and "_sup.erl"
worker_results=$(git grep ", worker" | grep _sup.erl | grep apps | grep CHILD | sed 's/{[^}]*}/ChildId/g')
sup_results=$(git grep ", supervisor" | grep _sup.erl | grep apps | grep CHILD | sed 's/{[^}]*}/ChildId/g')

# Declare arrays to store unique workers and sups
declare -a workers=()
declare -a sups=()

declare -a worker_relationships=()
declare -a sup_relationships=()

# Loop over each worker and supervisor result
while read -r line; do
  # Extract the value after "CHILD" and before the first ","
#  child=$(echo "$line" | sed -n 's/.*CHILD(\([^,]*\),.*/\1/p')
  child=$(echo "$line" | sed -n 's/.*CHILD([^,]*,\ \([^,]*\),[^,]*,.*/\1/p')

  # Extract the value immediately before ".erl"
  sup=$(echo "$line" | sed -n 's/.*\/\(.*_sup\)\.erl:.*/\1/p')

  # Determine the correct label for the node
  label="Supervisor"
  if echo "$line" | grep -q ", worker"; then
    label="Worker"
  fi

  # Add the worker to the arrays if they are not already present
  if [ "$label" = "Worker" ]; then
    if ! printf '%s\n' "${workers[@]}" | grep -q "^$child$"; then
      workers+=("$child")
    fi
  else
    if ! printf '%s\n' "${sups[@]}" | grep -q "^$child$"; then
      sups+=("$child")
    fi
  fi

  # Add the sup to the arrays if they are not already present
  if ! printf '%s\n' "${sups[@]}" | grep -q "^$sup$"; then
    sups+=("$sup")
  fi

  # Output the relationship between the supervisor and the worker/supervisor
  if [ "$label" = "Worker" ]; then
    worker_relationships+=('MATCH (s:Supervisor), (c:Worker) WHERE s.name = "'$sup'" AND c.name = "'$child'" CREATE (s)-[:START_LINK]->(c);')
  else
    sup_relationships+=('MATCH (s:Supervisor), (c:Supervisor) WHERE s.name = "'$sup'" AND c.name = "'$child'" CREATE (s)-[:START_LINK]->(c);')
  fi

done <<< "$(printf '%s\n%s' "$worker_results" "$sup_results")"

# Print the unique workers and sups
echo ""
for worker in "${workers[@]}"; do
  printf 'CREATE (:Worker{name: "%s"});\n' "$worker"
done

echo ""
for sup in "${sups[@]}"; do
  printf 'CREATE (:Supervisor{name: "%s"});\n' "$sup"
done

echo ""
for rel in "${worker_relationships[@]}"; do
  printf '%s\n' "$rel"
done

echo ""
for rel in "${sup_relationships[@]}"; do
  printf '%s\n' "$rel"
done
