"""
File: logger_config.py
Author: lxp
Description: 智学奇境 AI服务日志配置
使用 Loguru 提供现代化的日志功能
"""

import sys
import os
from pathlib import Path
from loguru import logger
import json
from datetime import datetime

def setup_logger():
    """配置日志系统"""
    
    # 移除默认处理器
    logger.remove()
    
    # 创建日志目录
    log_dir = Path("./logs")
    log_dir.mkdir(exist_ok=True)
    
    # 控制台输出（开发环境）
    if os.getenv("DEBUG", "false").lower() == "true":
        logger.add(
            sys.stdout,
            format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{file.name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>",
            level="DEBUG",
            colorize=True
        )
    else:
        # 生产环境不输出到控制台，避免日志文件中出现颜色代码
        pass
    
    # 文件输出 - 普通格式，避免编码问题
    logger.add(
        "../logs/ai.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {file.name}:{function}:{line} | {message}",
        level="INFO",
        rotation="100 MB",    # 100MB轮转
        retention="7 days",   # 保留7天
        compression="gz",     # 压缩
        encoding="utf-8",
        serialize=False,      # 使用普通文本格式
    )
    
    # 错误日志单独文件
    logger.add(
        log_dir / "ai_error.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {file.name}:{function}:{line} | {message}",
        level="ERROR",
        rotation="50 MB",
        retention="30 days",
        compression="gz",
        encoding="utf-8",
        serialize=True,
    )

def log_ai_request(user_id: str, model_type: str, input_data: dict, processing_time: float):
    """记录AI请求"""
    logger.info(
        "AI请求处理",
        extra={
            "event_type": "ai_request",
            "user_id": user_id,
            "model_type": model_type,
            "input_size": len(str(input_data)),
            "processing_time": processing_time,
            "timestamp": datetime.now().isoformat()
        }
    )

def log_difficulty_adjustment(user_id: str, current_difficulty: float, new_difficulty: float, reason: str):
    """记录难度调节"""
    logger.info(
        "难度调节",
        extra={
            "event_type": "difficulty_adjustment",
            "user_id": user_id,
            "current_difficulty": current_difficulty,
            "new_difficulty": new_difficulty,
            "adjustment": new_difficulty - current_difficulty,
            "reason": reason,
            "timestamp": datetime.now().isoformat()
        }
    )

def log_recommendation(user_id: str, question_ids: list, algorithm: str, confidence: float):
    """记录推荐结果"""
    logger.info(
        "题目推荐",
        extra={
            "event_type": "recommendation",
            "user_id": user_id,
            "question_ids": question_ids,
            "question_count": len(question_ids),
            "algorithm": algorithm,
            "confidence": confidence,
            "timestamp": datetime.now().isoformat()
        }
    )

def log_model_prediction(user_id: str, model_name: str, input_features: dict, prediction: dict, confidence: float):
    """记录模型预测"""
    logger.info(
        "模型预测",
        extra={
            "event_type": "model_prediction",
            "user_id": user_id,
            "model_name": model_name,
            "features": input_features,
            "prediction": prediction,
            "confidence": confidence,
            "timestamp": datetime.now().isoformat()
        }
    )

def log_error(component: str, operation: str, error: Exception, context: dict = None):
    """记录错误"""
    logger.error(
        f"AI服务错误: {str(error)}",
        extra={
            "event_type": "error",
            "component": component,
            "operation": operation,
            "error_type": type(error).__name__,
            "error_message": str(error),
            "context": context or {},
            "timestamp": datetime.now().isoformat()
        }
    )

def log_performance(endpoint: str, duration: float, status_code: int, user_id: str = None):
    """记录性能指标"""
    logger.info(
        "API性能",
        extra={
            "event_type": "performance",
            "endpoint": endpoint,
            "duration": duration,
            "status_code": status_code,
            "user_id": user_id,
            "timestamp": datetime.now().isoformat()
        }
    )

# 初始化日志系统
setup_logger()

# 导出logger实例
__all__ = ["logger", "log_ai_request", "log_difficulty_adjustment", "log_recommendation", 
           "log_model_prediction", "log_error", "log_performance"]
