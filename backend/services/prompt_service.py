"""
프롬프트(Prompt) 비즈니스 로직
"""
from typing import List, Optional, Dict, Any
import logging

# 프롬프트 관련 모델들 (로컬 정의)
from dataclasses import dataclass, field
from datetime import datetime
import uuid
import boto3

@dataclass
class PromptConfig:
    """프롬프트 설정"""
    description: str
    instruction: str

@dataclass
class PromptFile:
    """프롬프트 파일"""
    file_name: str
    file_content: str
    file_type: str = 'text'

@dataclass
class Prompt:
    """프롬프트 모델"""
    prompt_id: str
    user_id: str
    engine_type: str
    prompt_name: str
    config: PromptConfig
    files: List['PromptFile'] = field(default_factory=list)
    is_public: bool = False
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

class PromptRepository:
    """프롬프트 저장소"""
    
    def __init__(self):
        from config.database import get_table_name
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(get_table_name('prompts'))
    
    def save(self, prompt: Prompt) -> Prompt:
        """프롬프트 저장"""
        if not prompt.prompt_id:
            prompt.prompt_id = str(uuid.uuid4())
        if not prompt.created_at:
            prompt.created_at = datetime.utcnow().isoformat() + 'Z'
        prompt.updated_at = datetime.utcnow().isoformat() + 'Z'
        
        item = {
            'engineType': prompt.engine_type,
            'promptId': prompt.prompt_id,
            'userId': prompt.user_id,
            'promptName': prompt.prompt_name,
            'description': prompt.config.description,
            'instruction': prompt.config.instruction,
            'files': [{
                'fileName': f.file_name,
                'fileContent': f.file_content,
                'fileType': f.file_type
            } for f in prompt.files],
            'isPublic': prompt.is_public,
            'createdAt': prompt.created_at,
            'updatedAt': prompt.updated_at
        }
        self.table.put_item(Item=item)
        return prompt
    
    def get(self, engine_type: str, prompt_id: str) -> Optional[Prompt]:
        """프롬프트 조회"""
        try:
            response = self.table.get_item(
                Key={'engineType': engine_type, 'promptId': prompt_id}
            )
            if 'Item' not in response:
                return None
            
            item = response['Item']
            config = PromptConfig(
                description=item.get('description', ''),
                instruction=item.get('instruction', '')
            )
            
            files = []
            for f in item.get('files', []):
                files.append(PromptFile(
                    file_name=f.get('fileName', ''),
                    file_content=f.get('fileContent', ''),
                    file_type=f.get('fileType', 'text')
                ))
            
            return Prompt(
                prompt_id=item['promptId'],
                user_id=item.get('userId', ''),
                engine_type=item['engineType'],
                prompt_name=item.get('promptName', ''),
                config=config,
                files=files,
                is_public=item.get('isPublic', False),
                created_at=item.get('createdAt'),
                updated_at=item.get('updatedAt')
            )
        except Exception as e:
            logger.error(f"Error getting prompt: {e}")
            return None

logger = logging.getLogger(__name__)


class PromptService:
    """프롬프트 관련 비즈니스 로직"""
    
    def __init__(self, repository: Optional[PromptRepository] = None):
        self.repository = repository or PromptRepository()
    
    def create_prompt(
        self,
        user_id: str,
        engine_type: str,
        prompt_name: str,
        description: str,
        instruction: str,
        files: Optional[List[Dict[str, Any]]] = None,
        is_public: bool = False
    ) -> Prompt:
        """새 프롬프트 생성"""
        try:
            # 프롬프트 설정 생성
            prompt_config = PromptConfig(
                description=description,
                instruction=instruction
            )
            
            # 파일 목록 생성
            prompt_files = []
            if files:
                for file_data in files:
                    prompt_file = PromptFile(
                        file_name=file_data.get('fileName', ''),
                        file_content=file_data.get('fileContent', ''),
                        file_type=file_data.get('fileType', 'text')
                    )
                    prompt_files.append(prompt_file)
            
            # 프롬프트 모델 생성
            prompt = Prompt(
                prompt_id='',  # 자동 생성
                user_id=user_id,
                engine_type=engine_type,
                prompt_name=prompt_name,
                prompt=prompt_config,
                files=prompt_files,
                is_public=is_public
            )
            
            # 저장
            saved = self.repository.save(prompt)
            logger.info(f"Prompt created: {saved.prompt_id}")
            
            return saved
            
        except Exception as e:
            logger.error(f"Error creating prompt: {str(e)}")
            raise
    
    def get_prompt(self, prompt_id: str) -> Optional[Prompt]:
        """프롬프트 조회"""
        try:
            return self.repository.find_by_id(prompt_id)
        except Exception as e:
            logger.error(f"Error getting prompt: {str(e)}")
            raise
    
    def get_user_prompts(
        self,
        user_id: str,
        engine_type: Optional[str] = None
    ) -> List[Prompt]:
        """사용자의 프롬프트 목록 조회"""
        try:
            return self.repository.find_by_user(user_id, engine_type)
        except Exception as e:
            logger.error(f"Error getting user prompts: {str(e)}")
            raise
    
    def get_public_prompts(
        self,
        engine_type: Optional[str] = None,
        limit: int = 50
    ) -> List[Prompt]:
        """공개 프롬프트 목록 조회"""
        try:
            return self.repository.find_public(engine_type, limit)
        except Exception as e:
            logger.error(f"Error getting public prompts: {str(e)}")
            raise
    
    def update_prompt(
        self,
        prompt_id: str,
        user_id: str,
        updates: Dict[str, Any]
    ) -> Prompt:
        """프롬프트 업데이트"""
        try:
            # 기존 프롬프트 조회
            prompt = self.repository.find_by_id(prompt_id)
            if not prompt:
                raise ValueError(f"Prompt not found: {prompt_id}")
            
            # 소유자 확인
            if prompt.user_id != user_id:
                raise PermissionError(f"User {user_id} is not the owner of prompt {prompt_id}")
            
            # 업데이트 적용
            if 'promptName' in updates:
                prompt.prompt_name = updates['promptName']
            
            if 'description' in updates:
                prompt.prompt.description = updates['description']
            
            if 'instruction' in updates:
                prompt.prompt.instruction = updates['instruction']
            
            if 'files' in updates:
                prompt_files = []
                for file_data in updates['files']:
                    prompt_file = PromptFile(
                        file_name=file_data.get('fileName', ''),
                        file_content=file_data.get('fileContent', ''),
                        file_type=file_data.get('fileType', 'text')
                    )
                    prompt_files.append(prompt_file)
                prompt.files = prompt_files
            
            if 'isPublic' in updates:
                prompt.is_public = updates['isPublic']
            
            # 저장
            saved = self.repository.update(prompt)
            logger.info(f"Prompt updated: {prompt_id}")
            
            return saved
            
        except Exception as e:
            logger.error(f"Error updating prompt: {str(e)}")
            raise
    
    def delete_prompt(self, prompt_id: str, user_id: str) -> bool:
        """프롬프트 삭제"""
        try:
            # 프롬프트 조회 및 소유자 확인
            prompt = self.repository.find_by_id(prompt_id)
            if not prompt:
                raise ValueError(f"Prompt not found: {prompt_id}")
            
            if prompt.user_id != user_id:
                raise PermissionError(f"User {user_id} is not the owner of prompt {prompt_id}")
            
            # 삭제
            result = self.repository.delete(prompt_id)
            logger.info(f"Prompt deleted: {prompt_id}")
            
            return result
            
        except Exception as e:
            logger.error(f"Error deleting prompt: {str(e)}")
            raise
    
    def search_prompts(
        self,
        user_id: str,
        prompt_name: str
    ) -> List[Prompt]:
        """프롬프트 검색"""
        try:
            return self.repository.search_by_name(user_id, prompt_name)
        except Exception as e:
            logger.error(f"Error searching prompts: {str(e)}")
            raise
    
    def clone_prompt(
        self,
        prompt_id: str,
        user_id: str,
        new_name: Optional[str] = None
    ) -> Prompt:
        """프롬프트 복제"""
        try:
            # 원본 프롬프트 조회
            original = self.repository.find_by_id(prompt_id)
            if not original:
                raise ValueError(f"Prompt not found: {prompt_id}")
            
            # 공개 프롬프트이거나 소유자인 경우만 복제 가능
            if not original.is_public and original.user_id != user_id:
                raise PermissionError(f"Cannot clone private prompt {prompt_id}")
            
            # 새 이름 생성
            if not new_name:
                new_name = f"{original.prompt_name} (복사본)"
            
            # 복제
            cloned = self.repository.clone(prompt_id, user_id, new_name)
            logger.info(f"Prompt cloned: {prompt_id} -> {cloned.prompt_id}")
            
            return cloned
            
        except Exception as e:
            logger.error(f"Error cloning prompt: {str(e)}")
            raise
    
    def validate_prompt_access(
        self,
        prompt_id: str,
        user_id: str,
        require_owner: bool = False
    ) -> bool:
        """프롬프트 접근 권한 검증"""
        try:
            prompt = self.repository.find_by_id(prompt_id)
            if not prompt:
                return False
            
            # 소유자 확인
            if prompt.user_id == user_id:
                return True
            
            # 소유자 권한이 필요한 경우
            if require_owner:
                return False
            
            # 공개 프롬프트인 경우
            return prompt.is_public
            
        except Exception as e:
            logger.error(f"Error validating access: {str(e)}")
            return False
    
    def get_prompt_statistics(self, user_id: str) -> Dict[str, Any]:
        """사용자의 프롬프트 통계"""
        try:
            prompts = self.repository.find_by_user(user_id)
            
            stats = {
                'total_prompts': len(prompts),
                'public_prompts': 0,
                'private_prompts': 0,
                'by_engine': {},
                'total_files': 0
            }
            
            for prompt in prompts:
                # 공개/비공개 집계
                if prompt.is_public:
                    stats['public_prompts'] += 1
                else:
                    stats['private_prompts'] += 1
                
                # 엔진별 집계
                engine = prompt.engine_type
                if engine not in stats['by_engine']:
                    stats['by_engine'][engine] = 0
                stats['by_engine'][engine] += 1
                
                # 파일 수 집계
                stats['total_files'] += len(prompt.files)
            
            return stats
            
        except Exception as e:
            logger.error(f"Error getting statistics: {str(e)}")
            raise