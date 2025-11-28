# 📁 4-utilities/ - 유틸리티 스크립트

이 폴더는 개발과 운영을 돕는 유틸리티 스크립트들을 포함합니다.

## 📌 주요 기능
- 환경변수 생성 및 관리
- 개발 도구
- 헬퍼 스크립트

## 📄 포함된 파일

### generate-env.sh
- **목적**: 환경변수 파일 자동 생성
- **기능**:
  - .env.deploy 템플릿에서 실제 파일 생성
  - AWS 리소스 정보 자동 수집
  - frontend/.env 동기화
  - backend/.env 동기화
- **사용 시기**: 환경변수 재생성이 필요할 때

## 🔧 사용 방법

```bash
# 환경변수 파일 생성
bash 4-utilities/generate-env.sh

# 특정 환경으로 생성
ENV=production bash 4-utilities/generate-env.sh
```

## 🛠️ 추가 가능한 유틸리티

향후 이 폴더에 추가할 수 있는 스크립트:
- `cleanup.sh` - AWS 리소스 정리
- `backup.sh` - DynamoDB 데이터 백업
- `logs.sh` - CloudWatch 로그 조회
- `test.sh` - 엔드포인트 테스트
- `monitor.sh` - 서비스 상태 모니터링

## ⚠️ 주의사항
- 환경변수 파일은 민감 정보를 포함하므로 주의
- 생성된 .env 파일들은 Git에 커밋하지 않음