#!/bin/bash

ACTION=$1

echo "Selected action: $ACTION"

# ================= NEXUS PROMOTION =======================

if [ "$ACTION" == "nexus-promote" ]; then

NEXUS_URL="http://3.110.232.118:8081"
RC_REPO="my-app-test-rc-releases"
RELEASE_REPO="my-app-test-releases"
GROUP_ID="com.example"
ARTIFACT_ID="simple-webapp"

# ================= STEP 1: VERSION =================
VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')

if [ -z "$VERSION" ]; then
  echo "No Git tag found"
  exit 1
fi

echo "Release version: $VERSION"

# ================= STEP 2: FETCH RC =================
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

curl -f -u "$NEXUS_USER:$NEXUS_PASS" -O "$ARTIFACT_URL"

if [ $? -ne 0 ]; then
  echo "Download failed"
  exit 1
fi

# ================= STEP 4: PROMOTE =================
echo "Promoting artifact..."

curl -f -u "$NEXUS_USER:$NEXUS_PASS" -X POST \
"$NEXUS_URL/service/rest/v1/components?repository=$RELEASE_REPO" \
-F maven2.groupId="$GROUP_ID" \
-F maven2.artifactId="$ARTIFACT_ID" \
-F maven2.version="$VERSION" \
-F maven2.asset1=@"$FILE_NAME" \
-F maven2.asset1.extension=war

if [ $? -ne 0 ]; then
  echo "Promotion failed"
  exit 1
fi

echo "Promotion successful: $ARTIFACT_ID-$VERSION.war"

echo "$ARTIFACT_ID-$VERSION.war" > last_success.txt

echo "PROMOTION COMPLETED"


# ================= DEPLOYMENT ============================


elif [ "$ACTION" == "deploy" ]; then

echo "Starting Deployment..."

ARTIFACT=$(cat last_success.txt)

if [ -z "$ARTIFACT" ]; then
  echo "No artifact found"
  exit 1
fi

echo "Artifact: $ARTIFACT"

# Extract version
VERSION=$(echo $ARTIFACT | sed 's/.*-\(.*\)\.war/\1/')

echo "Version: $VERSION"

# ================= DOWNLOAD FROM RELEASE =================
curl -f -u "$NEXUS_USER:$NEXUS_PASS" -O \
"$NEXUS_URL/repository/maven-releases/com/company/app/$VERSION/$ARTIFACT"

if [ $? -ne 0 ]; then
  echo "Download failed"
  exit 1
fi

# ================= DEPLOY =================
echo "Deploying to production..."

# Example Tomcat deployment
# systemctl stop tomcat
# cp "$ARTIFACT" /opt/tomcat/webapps/app.war
# systemctl start tomcat

# Health check
curl -f http://prod-environment/health

if [ $? -ne 0 ]; then
  echo "Deployment failed"
  exit 1
fi

echo "Deployment successful"

else

echo "Invalid action: $ACTION"
echo "Usage: nexus-promote | deploy"
exit 1

fi
