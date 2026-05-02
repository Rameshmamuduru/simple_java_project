#!/bin/bash

NEXUS_URL="http://3.110.232.118:8081"
RC_REPO="my-app-test-rc-releases"
RELEASE_REPO="my-app-test-releases"
GROUP_ID="com.example"
ARTIFACT_ID="simple-webapp"


# ================= STEP 1: GET VERSION FROM TAG =================
VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')

if [ -z "$VERSION" ]; then
  echo "No Git tag found"
  exit 1
fi

echo "Release version: $VERSION"

# ================= STEP 2: GET LATEST RC =================
echo "Fetching latest RC artifact..."

ARTIFACT_URL=$(curl -s -u "$NEXUS_USER:$NEXUS_PASS" \
"$NEXUS_URL/service/rest/v1/search/assets?repository=$RC_REPO&group=$GROUP_ID&name=$ARTIFACT_ID" \
| jq -r '.items[] | select(.path | endswith(".war")) | .downloadUrl' \
| grep "$VERSION" \
| sort -V \
| tail -1)

if [ -z "$ARTIFACT_URL" ]; then
    echo "No RC artifact found for version $VERSION"
    exit 1
fi

echo "Latest RC URL: $ARTIFACT_URL"

# ================= STEP 3: DOWNLOAD =================
FILE_NAME=$(basename "$ARTIFACT_URL")

echo "Downloading $FILE_NAME ..."
curl -f -u "$NEXUS_USER:$NEXUS_PASS" -O "$ARTIFACT_URL"

if [ $? -ne 0 ]; then
  echo "Download failed"
  exit 1
fi

# ================= STEP 4: PROMOTE =================
echo "Promoting artifact to release repo..."

curl -f -u "$NEXUS_USER:$NEXUS_PASS" -X POST \
"$NEXUS_URL/service/rest/v1/components?repository=$RELEASE_REPO" \
-F maven2.groupId="$GROUP_ID" \
-F maven2.artifactId="$ARTIFACT_ID" \
-F maven2.version="$VERSION" \
-F maven2.asset1=@"$FILE_NAME" \
-F maven2.asset1.extension=war

if [ $? -ne 0 ]; then
  echo "Upload failed"
  exit 1
fi

echo "Promotion successful: $ARTIFACT_ID-$VERSION.war"
echo "$ARTIFACT_ID-$VERSION.war" > last_success.txt
