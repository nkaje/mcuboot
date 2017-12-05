#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# this retrieves the merge commit created by GH
parents=(`git log -n 1 --format=%p HEAD`)
branch=(`git rev-parse --abbrev-ref HEAD`)

# Should only run in PR branches
[[ ${branch} == "master" ]] && exit 0

if [[ "${#parents[@]}" -ne 2 ]]; then
  echo "This PR's merge commit is missing a parent!"
  exit 1
fi

from="${parents[0]}"
into="${parents[1]}"
commits=$(git show -s --format=%h ${from}..${into})

has_commits=false
for sha in $commits; do
  author="Signed-off-by: $(git show -s --format="%an <%ae>" ${sha})"
  committer="Signed-off-by: $(git show -s --format="%cn <%ce>" ${sha})"

  lines="$(git show -s --format=%B ${sha})"

  found_author=false
  found_committer=false
  IFS=$'\n'
  for line in ${lines}; do
    stripped=$(echo $line | sed -e 's/^\s*//' | sed -e 's/\s*$//')
    if [[ ${stripped} == ${author} ]]; then
      found_author=true
    fi
    if [[ ${stripped} == ${committer} ]]; then
      found_committer=true
    fi

    [[ ${found_author} == true && ${found_committer} == true ]] && break
  done

  if [[ ${found_author} == false || ${found_committer} == false ]]; then
    echo -e "One or more \"Signed-off-by\" lines missing in commit ${sha}"
    exit 1
  fi

  has_commits=true
done

if [[ ${has_commits} = false ]]; then
  echo "No commits found in this PR!"
  exit 1
fi
