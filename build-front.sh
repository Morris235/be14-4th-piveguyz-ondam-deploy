#!/bin/bash

set -e  # 에러 발생 시 종료

echo "📁 frontend 디렉토리로 이동"
cd frontend

echo "🧹 이전 빌드 결과(dist) 및 의존성(node_modules) 제거"
rm -rf dist node_modules

echo "📦 의존성 설치"
npm install

echo "🛠️ Vue 앱 프로덕션 빌드"
npm run build

echo "🐳 프론트엔드 Docker 이미지 빌드 (캐시 무시)"
docker build --no-cache -t morris235/ondam-frontend:latest .

echo "📤 Docker Hub에 프론트엔드 이미지 푸시"
docker push morris235/ondam-frontend:latest

cd ..

# echo "프론트엔드 컨테이너 실행"
# docker rm -f ondam-frontend || true
# docker run -d \
#   --name ondam-frontend \
#   -p 3000:80 \
#   morris235/ondam-frontend:latest

# echo "프론트엔드 실행 완료: http://localhost:3000"
