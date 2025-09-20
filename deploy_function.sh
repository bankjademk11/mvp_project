#!/bin/bash

# Deploy Appwrite Cloud Function
# ต้องตั้งค่า environment variables ก่อนรัน script นี้:
# export APPWRITE_ENDPOINT="https://cloud.appwrite.io/v1"
# export APPWRITE_PROJECT_ID="your_project_id"
# export APPWRITE_API_KEY="your_api_key"
# export FUNCTION_ID="68c7ad6e002ccdeb7c17"

echo "กำลัง Deploy Appwrite Cloud Function..."

# ตรวจสอบว่ามีการตั้งค่า environment variables แล้วหรือไม่
if [ -z "$APPWRITE_ENDPOINT" ] || [ -z "$APPWRITE_PROJECT_ID" ] || [ -z "$APPWRITE_API_KEY" ] || [ -z "$FUNCTION_ID" ]; then
  echo "กรุณาตั้งค่า environment variables ให้ครบถ้วน:"
  echo "export APPWRITE_ENDPOINT=\"https://cloud.appwrite.io/v1\""
  echo "export APPWRITE_PROJECT_ID=\"your_project_id\""
  echo "export APPWRITE_API_KEY=\"your_api_key\""
  echo "export FUNCTION_ID=\"your_function_id\""
  exit 1
fi

# แสดงข้อมูลการเชื่อมต่อ
echo "Endpoint: $APPWRITE_ENDPOINT"
echo "Project ID: $APPWRITE_PROJECT_ID"
echo "Function ID: $FUNCTION_ID"

# สร้าง deployment ใหม่
echo "กำลังสร้าง deployment ใหม่..."
curl -X POST \
  "$APPWRITE_ENDPOINT/v1/functions/$FUNCTION_ID/deployments" \
  -H "X-Appwrite-Response-Format: 1.5.0" \
  -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
  -H "X-Appwrite-Key: $APPWRITE_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F "entrypoint=lib/main.dart" \
  -F "code=@functions/getApplicationsForEmployer.zip" \
  -F "activate=true" \
  -F "command=dart --disable-service-auth-codes main.dart"

echo ""
echo "Deploy เสร็จสิ้น"