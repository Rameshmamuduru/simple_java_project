#!/bin/bash

ACTION=$1

echo "Selected action: $ACTION"

NEXUS_URL="http://3.110.232.118:8081"
RC_REPO="my-app-test-rc-releases"
RELEASE_REPO="my-app-test-releases"
GROUP_ID="com.company"
ARTIFACT_ID="simple-webapp"

# =========================================================
# ================= NEXUS PROMOTION =======================
# =========================================================

if [ "$ACTION" == "nexus-promote" ]; then

VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')

if [ -z "$VERSION" ]; then
  echo "No Git tag found"
  exit 1
fi

echo "Release version: $VERSION"

echo "Fetching latest RC artifact..."

ARTIFACT_URL=$(curl -s -u "$NEXUS_USER:$NEXUS_PASS" \
"$NEXUS_URL/service/rest/v1/search/assets?repository=$RC_REPO&group=$GROUP_ID&name=$ARTIFACT_ID" \
| jq -r '.items[] | select(.path | endswith(".war")) | .downloadUrl' \
| grep "$VERSION" \
| sort -V \
| tail -1)

if [ -z "$ARTIFACT_URL" ]; then
    echo "No RC artifact found"
    exit 1
fi

FILE_NAME=$(basename "$ARTIFACT_URL")

curl -f -u "$NEXUS_USER:$NEXUS_PASS" -O "$ARTIFACT_URL"

curl -f -u "$NEXUS_USER:$NEXUS_PASS" -X POST \
"$NEXUS_URL/service/rest/v1/components?repository=$RELEASE_REPO" \
-F maven2.groupId="$GROUP_ID" \
-F maven2.artifactId="$ARTIFACT_ID" \
-F maven2.version="$VERSION" \
-F maven2.asset1=@"$FILE_NAME" \
-F maven2.asset1.extension=war

echo "PROMOTION SUCCESSFUL: $ARTIFACT_ID-$VERSION.war"


# =========================================================
# ================= DEPLOY ================================
# =========================================================

elif [ "$ACTION" == "deploy" ]; then

echo "Deploying latest artifact from Nexus..."

ARTIFACT_URL=$(curl -s -u "$NEXUS_USER:$NEXUS_PASS" \
"$NEXUS_URL/service/rest/v1/search/assets?repository=$RELEASE_REPO&group=$GROUP_ID&name=$ARTIFACT_ID" \
| jq -r '.items[] | select(.path | endswith(".war")) | .downloadUrl' \
| sort -V | tail -1)

if [ -z "$ARTIFACT_URL" ]; then
  echo "No release artifact found"
  exit 1
fi

ARTIFACT=$(basename "$ARTIFACT_URL")

echo "Deploying: $ARTIFACT"

curl -f -u "$NEXUS_USER:$NEXUS_PASS" -O "$ARTIFACT_URL"

# ===== DEPLOY (Tomcat example) =====
# systemctl stop tomcat
# cp "$ARTIFACT" /opt/tomcat/webapps/app.war
# systemctl start tomcat

echo "Running health check..."
curl -f http://prod-environment/health

if [ $? -ne 0 ]; then
  echo "Deployment FAILED"
  exit 1
fi

echo "Deployment SUCCESSFUL"


# =========================================================
# ================= ROLLBACK ==============================
# =========================================================

elif [ "$ACTION" == "rollback" ]; then

echo "Fetching previous stable version from Nexus..."

ARTIFACTS=$(curl -s -u "$NEXUS_USER:$NEXUS_PASS" \
"$NEXUS_URL/service/rest/v1/search/assets?repository=$RELEASE_REPO&group=$GROUP_ID&name=$ARTIFACT_ID" \
| jq -r '.items[] | select(.path | endswith(".war")) | .downloadUrl' \
| sort -V)

PREVIOUS=$(echo "$ARTIFACTS" | tail -2 | head -1)

if [ -z "$PREVIOUS" ]; then
  echo "No previous version found"
  exit 1
fi

ARTIFACT=$(basename "$PREVIOUS")

echo "Rolling back to: $ARTIFACT"

curl -f -u "$NEXUS_USER:$NEXUS_PASS" -O "$PREVIOUS"

# ===== ROLLBACK DEPLOY =====
# systemctl stop tomcat
# cp "$ARTIFACT" /opt/tomcat/webapps/app.war
# systemctl start tomcat

echo "Running rollback health check..."
curl -f http://prod-environment/health

if [ $? -ne 0 ]; then
  echo "ROLLBACK FAILED"
  exit 1
fi

echo "ROLLBACK SUCCESSFUL"

else

echo "Invalid action: $ACTION"
echo "Usage: nexus-promote | deploy | rollback"
exit 1

fi
