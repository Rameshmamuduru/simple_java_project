
NEXUS_URL="http://3.110.232.118:8081"
RELEASE_REPO="my-app-test-releases"
GROUP_ID="com.example"
ARTIFACT_ID="simple-webapp"

PREV_VERSION=$(curl -s -u "$NEXUS_USER:$NEXUS_PASS" \
"$NEXUS_URL/service/rest/v1/search/assets?repository=$RELEASE_REPO&group=$GROUP_ID&name=$ARTIFACT_ID" \
| jq -r '.items[].version' \
| sort -V | uniq \
| sort -V -r | sed -n '2p')

echo "Previous version: $PREV_VERSION"
