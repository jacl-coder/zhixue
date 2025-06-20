"""
File: main.py
Author: lxp
Description: 智学奇境 AI 推理服务
基于 FastAPI 的高性能异步 AI 服务
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Any
import uvicorn
import time

# 导入日志配置
from logger_config import logger, log_ai_request, log_difficulty_adjustment, log_error, log_performance

app = FastAPI(
    title="智学奇境 AI 服务",
    description="基于AI的个性化学习难度调节和推荐系统",
    version="1.0.0"
)

# 允许跨域
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class UserPerformance(BaseModel):
    user_id: str
    correct_answers: int
    total_answers: int
    avg_response_time: float
    current_difficulty: float

class DifficultyResponse(BaseModel):
    user_id: str
    recommended_difficulty: float
    confidence: float
    reasoning: str

@app.middleware("http")
async def log_requests(request, call_next):
    """请求日志中间件"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    log_performance(
        endpoint=str(request.url.path),
        duration=process_time,
        status_code=response.status_code,
        user_id=request.headers.get("user-id")
    )
    
    return response

@app.get("/health")
async def health_check():
    """健康检查接口"""
    logger.info("AI服务健康检查")
    return {
        "status": "healthy",
        "service": "zhixue-ai-service",
        "version": "1.0.0",
        "framework": "FastAPI + PyTorch"
    }

@app.post("/ai/adjust-difficulty", response_model=DifficultyResponse)
async def adjust_difficulty(performance: UserPerformance):
    """AI难度调节接口"""
    start_time = time.time()
    
    try:
        # 简单的难度调节算法 (后续会用机器学习模型替换)
        accuracy = performance.correct_answers / max(performance.total_answers, 1)
        
        # 基于准确率调节难度
        if accuracy > 0.8:
            new_difficulty = min(performance.current_difficulty + 0.2, 5.0)
            reasoning = "准确率高，增加难度"
        elif accuracy < 0.5:
            new_difficulty = max(performance.current_difficulty - 0.3, 1.0)
            reasoning = "准确率低，降低难度"
        else:
            new_difficulty = performance.current_difficulty
            reasoning = "难度适中，保持当前水平"
        
        # 考虑响应时间
        if performance.avg_response_time > 30:  # 超过30秒
            new_difficulty = max(new_difficulty - 0.1, 1.0)
            reasoning += "，响应时间长"
        
        confidence = min(abs(accuracy - 0.65) * 2, 1.0)
        
        processing_time = time.time() - start_time
        
        # 记录日志
        log_ai_request(
            user_id=performance.user_id,
            model_type="difficulty_adjustment",
            input_data=performance.dict(),
            processing_time=processing_time
        )
        
        log_difficulty_adjustment(
            user_id=performance.user_id,
            current_difficulty=performance.current_difficulty,
            new_difficulty=new_difficulty,
            reason=reasoning
        )
        
        logger.info(f"用户 {performance.user_id} 难度调节完成: {performance.current_difficulty} -> {new_difficulty}")
        
        return DifficultyResponse(
            user_id=performance.user_id,
            recommended_difficulty=new_difficulty,
            confidence=confidence,
            reasoning=reasoning
        )
        
    except Exception as e:
        log_error("difficulty_adjustment", "adjust_difficulty", e, {
            "user_id": performance.user_id,
            "input": performance.dict()
        })
        raise HTTPException(status_code=500, detail=f"AI难度调节失败: {str(e)}")

@app.get("/ai/test")
async def test_ai():
    """AI服务测试接口"""
    logger.info("AI服务测试请求")
    return {
        "message": "智学奇境 AI 服务运行正常",
        "capabilities": [
            "难度自适应调节",
            "个性化推荐",
            "学习行为分析",
            "知识图谱构建"
        ]
    }

@app.get("/")
def root():
    return {"message": "智学奇境 AI 服务", "status": "运行中"}

if __name__ == "__main__":
    logger.info("🧠 智学奇境 AI 服务启动")
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8003,
        reload=True,
        log_config=None  # 禁用uvicorn默认日志，使用自定义日志
    )
