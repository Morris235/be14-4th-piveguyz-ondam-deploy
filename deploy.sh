#!/bin/bash

set -e  # 에러 발생 시 종료

echo "Docker 이미지 빌드 시작"

##############################
# 백엔드 Docker 빌드 & 실행
##############################

echo "[1/2] 백엔드 Docker 이미지 빌드"
cd backend/ondam-backend
docker build -t morris235/ondam-backend:latest .
cd ..

echo "[2/2] 백엔드 컨테이너 실행"

# 기존 컨테이너 제거 (있다면)
docker rm -f ondam-backend || true

# 백엔드 실행 (포트 8080 → 8080)
docker run -d \
  --name ondam-backend \
  -p 8080:8080 \
  morris235/ondam-backend:latest

echo "백엔드 실행 완료: http://localhost:8080"

##############################
# 백엔드 Docker 빌드 & 실행
##############################

# echo "프론트엔드 Docker 이미지 빌드"
# cd frontend
# docker build -t morris235/ondam-frontend:latest .
# cd ..

# echo "프론트엔드 컨테이너 실행"
# docker rm -f ondam-frontend || true
# docker run -d \
#   --name ondam-frontend \
#   -p 3000:80 \
#   morris235/ondam-frontend:latest

# echo "프론트엔드 실행 완료: http://localhost:3000"
