# 📁 3-deploy/ - 배포 스크립트

이 폴더는 프론트엔드와 백엔드 코드를 AWS에 배포하는 스크립트들을 포함합니다.

## 📌 주요 기능
- React 앱 빌드 및 S3 배포
- Lambda 함수 코드 업데이트
- 스마트 배포 (변경사항만 배포)

## 📄 포함된 파일

### deploy.sh
- **목적**: 스마트 통합 배포
- **기능**:
  - 변경사항 자동 감지
  - 필요한 부분만 선택적 배포
  - 배포 전 검증
  - 배포 상태 추적
- **사용 시기**: 일반적인 배포 시 (권장)

### deploy-frontend.sh
- **목적**: React 프론트엔드 배포
- **기능**:
  - npm 빌드 실행
  - 빌드 결과물 S3 업로드
  - CloudFront 캐시 무효화
  - 환경변수 자동 주입
- **배포 대상**: frontend/ → S3 버킷

### deploy-backend.sh
- **목적**: Python Lambda 백엔드 배포
- **기능**:
  - Python 패키지 설치 (requirements.txt)
  - ZIP 패키지 생성
  - 6개 Lambda 함수 동시 업데이트
  - 환경변수 업데이트
- **배포 대상**: backend/ → Lambda Functions

## 🔧 사용 방법

```bash
# 스마트 배포 (변경사항만 배포) - 권장
bash 3-deploy/deploy.sh

# 프론트엔드만 배포
bash 3-deploy/deploy-frontend.sh

# 백엔드만 배포
bash 3-deploy/deploy-backend.sh

# 강제 전체 배포
bash 3-deploy/deploy.sh --force
```

## 🚀 배포 프로세스

### 프론트엔드 배포 흐름
1. 환경변수 검증 (.env 파일)
2. npm install (의존성 설치)
3. npm run build (프로덕션 빌드)
4. S3 sync (파일 업로드)
5. CloudFront 캐시 무효화

### 백엔드 배포 흐름
1. 환경변수 검증 (.env.deploy)
2. 임시 디렉토리 생성
3. 소스코드 복사 및 정리
4. pip install (Python 패키지 설치)
5. ZIP 패키지 생성
6. Lambda 함수 업데이트 (병렬 처리)

## 📊 배포 시간 예상
- 프론트엔드: 2-5분 (빌드 + 업로드)
- 백엔드: 1-3분 (패키징 + 업데이트)
- 전체: 3-8분

## ⚠️ 주의사항
- 배포 전 로컬에서 테스트 필수
- 프론트엔드 빌드 에러 시 배포 중단됨
- Lambda 업데이트는 즉시 반영됨 (롤백 주의)
- CloudFront 캐시 반영까지 5-10분 소요 가능