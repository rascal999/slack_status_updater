#!/usr/bin/env bash

# Define the directory to search in
SEARCH_DIRECTORY="/home/user/Data/logseq"

# Define the string you want to search for
SEARCH_STRING="#status"

# Slack status
LAST_STATUS=""

# Update Slack
function update_slack() {
    source .env

    STATUS_EMOJI=":bar_chart:"
    # Define the status information you want to set
    STATUS_LINE=`echo "$1" | choose -f '#' 1 | choose 0 | choose -f '-' 1`
    if [[ "$STATUS_LINE" == "lunch" ]]; then
        STATUS_EMOJI=":poultry_leg:"
    elif [[ "$STATUS_LINE" == "ops" ]]; then
        STATUS_EMOJI=":bar_chart:"
    elif [[ "$STATUS_LINE" == "dev" ]]; then
        STATUS_EMOJI=":rocket:"
    elif [[ "$STATUS_LINE" == "meeting" ]]; then
        STATUS_EMOJI=":headphones:"
    fi

    STATUS_TEXT=`echo $1 | sed 's/\(.*\)#.*/\1/g'`

    # Create a JSON payload for the request body
    PAYLOAD="{\"profile\": {\"status_text\": \"$STATUS_TEXT\", \"status_emoji\": \"$STATUS_EMOJI\"}}"

    # Make the cURL request to update the Slack status
    curl -X POST -H "Content-Type: application/json; charset=utf-8" -H "Authorization: Bearer $SLACK_TOKEN" --data "$PAYLOAD" "https://slack.com/api/users.profile.set"

    # You can also add error handling here to check the response from Slack
}

while :
do
    # Use find to search for files with the SEARCH_STRING recursively
    files_with_string=$(find "$SEARCH_DIRECTORY" -type f -exec grep -l "$SEARCH_STRING" {} +)

    if [ -z "$files_with_string" ]; then
      echo "No files containing '$SEARCH_STRING' found in the specified directory and its subdirectories."
    else
      # Find the most recently modified file among those containing the SEARCH_STRING
      most_recent_file=""
      most_recent_timestamp=0

      for file in $files_with_string; do
        file_timestamp=$(stat -c %Y "$file")
        if [ "$file_timestamp" -gt "$most_recent_timestamp" ]; then
          most_recent_file="$file"
          most_recent_timestamp="$file_timestamp"
        fi
      done

      if [ -n "$most_recent_file" ]; then
        # Has to be head because latest entries are at the top
        STATUS=`rg "#status" "$most_recent_file" | head -1 | choose -f '- ' 1`

        # Don't netio if we don't need to
        if [[ "$STATUS" != "$LAST_STATUS" ]]; then
            NOW=`date +"[%Y%m%d %H:%M:%S]"`
            echo "$NOW Updating status.."
            update_slack "$STATUS"
        fi

        LAST_STATUS="$STATUS"
        sleep 15
      else
        echo "No files containing '$SEARCH_STRING' found in the specified directory and its subdirectories."
      fi
    fi
done
