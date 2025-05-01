#!/bin/bash
set -e

echo "🚀 [1/3] 백엔드 배포 시작"
./deploy-back.sh
echo "✅ [1/3] 백엔드 배포 완료"

echo "🚀 [2/3] 프론트엔드 배포 시작"
./deploy-front.sh
echo "✅ [2/3] 프론트엔드 배포 완료"

echo "🚀 [3/3] Ingress 배포 시작"
./deploy-ingress.sh
echo "✅ [3/3] Ingress 배포 완료"

echo ""
echo "🌐 접속 확인:"
echo "→ 프론트엔드: http://ondam.localhost/"
echo "→ 백엔드 API: http://ondam.localhost/api/v1/counselees?memberId=1"
