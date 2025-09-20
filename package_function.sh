#!/bin/bash

# สร้าง zip ไฟล์สำหรับ Appwrite Cloud Function

echo "กำลังสร้าง zip ไฟล์สำหรับ Cloud Function..."

# กำหนดไดเรกทอรีหลัก
ROOT_DIR="/Users/itdepartment/Desktop/Bank All Project/mvp_package"
FUNCTION_DIR="$ROOT_DIR/functions/getApplicationsForEmployer"
OUTPUT_FILE="$FUNCTION_DIR.zip"

# สร้างไดเรกทอรีชั่วคราว
TEMP_DIR=$(mktemp -d)
echo "ไดเรกทอรีชั่วคราว: $TEMP_DIR"

# คัดลอกไฟล์ที่จำเป็นไปยังไดเรกทอรีชั่วคราว
mkdir -p "$TEMP_DIR/lib"
cp -r "$FUNCTION_DIR/lib"/* "$TEMP_DIR/lib/"
cp "$FUNCTION_DIR/pubspec.yaml" "$TEMP_DIR/"

# ไปยังไดเรกทอรีชั่วคราว
cd "$TEMP_DIR"

# สร้าง zip ไฟล์
zip -r "$OUTPUT_FILE" .

# กลับไปยังไดเรกทอรีหลัก
cd "$ROOT_DIR"

# ลบไดเรกทอรีชั่วคราว
rm -rf "$TEMP_DIR"

echo "สร้าง zip ไฟล์เสร็จสิ้น: $OUTPUT_FILE"