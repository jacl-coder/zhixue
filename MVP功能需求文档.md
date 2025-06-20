# 智学奇境 MVP 功能需求文档

## 项目概述
基于AI的2.5D数学游戏化学习平台，面向2026年中国大学生计算机设计大赛人工智能应用类。

## MVP核心功能（3个月开发周期）

### 1. 用户系统 [2周]
**功能描述**: 基础的用户注册、登录、个人信息管理

**技术实现**:
- Go + JWT身份验证
- PostgreSQL用户数据存储
- Redis会话管理

**具体功能**:
- [ ] 用户注册/登录
- [ ] 个人信息管理
- [ ] 学习进度追踪
- [ ] 简单的用户画像

**API接口**:
```
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /api/v1/user/profile
PUT  /api/v1/user/profile
GET  /api/v1/user/progress
```

### 2. 数学题库系统 [3周]
**功能描述**: 分类分难度的数学题目管理系统

**技术实现**:
- PostgreSQL题库存储
- 题目分类标签系统
- 支持选择题、填空题、计算题

**具体功能**:
- [ ] 题目录入和管理
- [ ] 按年级/知识点分类
- [ ] 难度等级标注（1-5级）
- [ ] 题目解析和提示
- [ ] 答题记录统计

**数据模型**:
```sql
-- 题目表
CREATE TABLE questions (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    type VARCHAR(20), -- choice, fill, calculate
    difficulty INTEGER, -- 1-5
    grade_level INTEGER, -- 1-12
    subject VARCHAR(50), -- algebra, geometry, etc
    correct_answer TEXT,
    explanation TEXT,
    created_at TIMESTAMP
);

-- 答题记录表
CREATE TABLE answer_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    question_id INTEGER,
    user_answer TEXT,
    is_correct BOOLEAN,
    time_spent INTEGER, -- 秒
    answered_at TIMESTAMP
);
```

### 3. AI难度调节引擎 [4周]
**功能描述**: 基于学习表现的智能难度自适应系统

**技术实现**:
- Python + scikit-learn
- 简单的机器学习算法
- 实时难度调节API

**算法设计**:
```python
class DifficultyAdjuster:
    def calculate_difficulty(self, user_performance):
        # 基于答题正确率、用时、连续答题情况调节
        accuracy = user_performance['accuracy']
        avg_time = user_performance['avg_time'] 
        streak = user_performance['correct_streak']
        
        if accuracy > 0.8 and avg_time < 30:
            return min(current_difficulty + 1, 5)
        elif accuracy < 0.5 or avg_time > 60:
            return max(current_difficulty - 1, 1)
        else:
            return current_difficulty
```

**具体功能**:
- [ ] 用户表现数据收集
- [ ] 实时难度调节算法
- [ ] 个性化题目推荐
- [ ] 学习路径优化建议

### 4. 基础游戏化界面 [3周]
**功能描述**: 简单的2.5D数学王国探索界面

**技术实现**:
- Unity 2022.3 LTS
- 2.5D Isometric视角
- 简单的角色移动和交互

**场景设计**:
- **数学村庄**: 主要学习区域
- **练习广场**: 题目挑战区
- **成长花园**: 个人进度展示
- **智慧图书馆**: 知识点学习

**具体功能**:
- [ ] 2.5D场景漫游
- [ ] 角色移动和交互
- [ ] 答题界面集成
- [ ] 简单动画效果
- [ ] 进度可视化

### 5. 数据分析看板 [2周]
**功能描述**: 学习数据的可视化展示

**技术实现**:
- Web Dashboard
- Chart.js数据图表
- 实时数据更新

**具体功能**:
- [ ] 学习时长统计
- [ ] 答题正确率趋势
- [ ] 知识点掌握情况
- [ ] 难度适应性分析
- [ ] 学习建议生成

## 技术架构

### 后端服务 (Go)
```
zhixue-backend/
├── main.go
├── api/
│   ├── auth.go      # 用户认证
│   ├── question.go  # 题目管理
│   ├── answer.go    # 答题记录
│   └── progress.go  # 学习进度
├── model/
│   ├── user.go
│   ├── question.go
│   └── answer.go
├── service/
│   ├── auth_service.go
│   ├── question_service.go
│   └── ai_service.go
└── config/
    └── database.go
```

### AI服务 (Python)
```
ai-service/
├── main.py
├── models/
│   ├── difficulty_adjuster.py
│   ├── recommendation.py
│   └── performance_analyzer.py
├── api/
│   ├── difficulty.py
│   └── recommendation.py
└── data/
    └── feature_extractor.py
```

### 前端客户端 (Unity)
```
Unity Project/
├── Scenes/
│   ├── MainScene.unity    # 主场景
│   ├── VillageScene.unity # 村庄场景
│   └── QuestionScene.unity # 答题场景
├── Scripts/
│   ├── PlayerController.cs
│   ├── QuestionManager.cs
│   ├── SceneManager.cs
│   └── NetworkManager.cs
└── Assets/
    ├── Models/           # 3D模型
    ├── Textures/         # 贴图
    └── Audio/           # 音效
```

## 开发时间线

### 第1月：基础框架
- Week 1-2: 环境搭建 + 用户系统
- Week 3-4: 数据库设计 + 题库基础

### 第2月：核心功能  
- Week 1-2: AI难度调节引擎
- Week 3-4: 游戏界面框架

### 第3月：集成优化
- Week 1-2: 功能集成 + 数据分析
- Week 3-4: 测试优化 + 演示准备

## 技术创新点

1. **自适应难度算法**: 基于多维度用户行为的实时难度调节
2. **游戏化学习路径**: 2.5D探索式数学学习体验  
3. **个性化推荐**: AI驱动的题目和学习内容推荐
4. **数据驱动决策**: 学习行为分析和优化建议

## 风险控制

### 技术风险
- **Unity学习成本**: 先实现2D版本，再升级2.5D
- **AI算法复杂度**: 采用简单有效的机器学习方法
- **性能优化**: 关键功能优先，视觉效果适度

### 时间风险  
- **功能裁剪**: 优先MVP核心功能
- **并行开发**: 前后端同步推进
- **迭代优化**: 快速原型，持续改进

## 竞赛优势

1. **实用性强**: 解决真实的数学学习痛点
2. **技术先进**: AI+游戏化的创新结合
3. **用户体验**: 沉浸式2.5D学习环境
4. **数据驱动**: 基于用户行为的智能优化
5. **可扩展性**: 模块化架构，易于功能扩展

## 成功指标

- [ ] 完成所有MVP功能模块
- [ ] AI难度调节准确率 > 75%
- [ ] 用户答题正确率提升 > 20%
- [ ] 平均学习时长增加 > 30%
- [ ] 系统稳定性 > 99%

---

**目标**: 打造一个"好玩、有效、智能"的数学学习平台，争取在2026年大赛中获得优异成绩！
