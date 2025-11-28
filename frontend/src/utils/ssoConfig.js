/**
 * SSO 설정 파일 - 환경변수에서 읽어옴
 */

export const ssoConfig = {
  // Cognito 설정
  cognitoPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
  cognitoRegion: import.meta.env.VITE_AWS_REGION || 'us-east-1',
  
  // 관리자 이메일
  adminEmail: import.meta.env.VITE_ADMIN_EMAIL || 'admin@example.com',
  
  // 회사 도메인
  companyDomain: import.meta.env.VITE_COMPANY_DOMAIN || '@example.com',
  
  // SSO 허용 도메인 목록
  allowedOrigins: (import.meta.env.VITE_SSO_ALLOWED_ORIGINS || '').split(',').filter(Boolean),
  
  // 쿠키 도메인
  cookieDomain: import.meta.env.VITE_COOKIE_DOMAIN || window.location.hostname,
  
  // 스토리지 접두사
  storagePrefix: import.meta.env.VITE_STORAGE_PREFIX || 'nexus_'
};

// Cognito Issuer URL 생성
export const getCognitoIssuer = () => {
  const { cognitoRegion, cognitoPoolId } = ssoConfig;
  return `https://cognito-idp.${cognitoRegion}.amazonaws.com/${cognitoPoolId}`;
};

// 관리자 체크
export const isAdminEmail = (email) => {
  return email === ssoConfig.adminEmail;
};

// 회사 도메인 체크
export const isCompanyEmail = (email) => {
  return email.endsWith(ssoConfig.companyDomain);
};

export default ssoConfig;