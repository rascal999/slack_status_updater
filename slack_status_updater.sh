#!/usr/bin/env bash

# Define the directory to search in
SEARCH_DIRECTORY="/monitor/journals"

# Define the string you want to search for
SEARCH_STRING="#status"

# Slack status
LAST_STATUS=""

# trap ctrl-c and call ctrl_c()
trap - INT

# Debug echo
function decho() {
    DEBUG=0

    if [[ "$DEBUG" == "1" ]]; then
        echo $1
    fi
}

# Update Slack
function update_slack() {
    source .env

    STATUS_EMOJI=":bar_chart:"
    # Define the status information you want to set
    STATUS_LINE=$2
    decho \$STATUS_LINE $STATUS_LINE
    if [[ "$STATUS_LINE" == "lunch" ]]; then
        STATUS_EMOJI=":poultry_leg:"
    elif [[ "$STATUS_LINE" == "ops" ]]; then
        STATUS_EMOJI=":male-technologist:"
    elif [[ "$STATUS_LINE" == "dev" ]]; then
        STATUS_EMOJI=":male-technologist:"
    elif [[ "$STATUS_LINE" == "meeting" ]]; then
        STATUS_EMOJI=":headphones:"
    fi

    STATUS_TEXT=`echo $1 | sed -e 's/\*\*..\:..\*\* //;s/#.*//'`

    # Create a JSON payload for the request body
    PAYLOAD="{\"profile\": {\"status_text\": \"$STATUS_TEXT\", \"status_emoji\": \"$STATUS_EMOJI\"}}"

    # Make the cURL request to update the Slack status
    curl -X POST -H "Content-Type: application/json; charset=utf-8" -H "Authorization: Bearer $SLACK_TOKEN" --data "$PAYLOAD" "https://slack.com/api/users.profile.set"

    # You can also add error handling here to check the response from Slack
    return $?
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
        decho \$most_recent_file $most_recent_file
        # Has to be head because latest entries are at the top
        STATUS=`grep "#status" "$most_recent_file" | head -1 | sed -e 's/- \*\*..\:..\*\* //;s/#.*//'`
        STATUS_TYPE=`grep "#status" "$most_recent_file" | head -1 | choose -f "#status-" 1 | choose 0`

        decho \$STATUS $STATUS
        decho \$LAST_STATUS $LAST_STATUS

        # Don't netio if we don't need to
        if [[ "$STATUS" != "$LAST_STATUS" ]]; then
            update_slack "$STATUS" "$STATUS_TYPE"
            UPDATE_FAIL=$?

            if [[ "$UPDATE_FAIL" == "0" ]]; then
                NOW=`date +"[%Y%m%d %H:%M:%S]"`
                echo "$NOW Updated status.."
                LAST_STATUS="$STATUS"
            fi
        fi
      else
        echo "No files containing '$SEARCH_STRING' found in the specified directory and its subdirectories."
      fi
    fi
    sleep 15
done
