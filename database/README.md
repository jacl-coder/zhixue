# 智学奇境数据库结构设计文档

## 📊 数据库概览

**数据库名称**: `zhixue_db`  
**设计日期**: 2025-06-20  
**总表数量**: 12个核心表 + 2个视图 + 1个存储过程  
**设计理念**: 支持AI驱动的个性化学习，游戏化体验，完整的学习行为追踪

---

## 🏗️ 表结构设计

### 1. 👥 用户系统 (2张表)

#### `users` - 用户基础信息表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| id | BIGSERIAL | 主键 | PK |
| username | VARCHAR(50) | 用户名 | UK, IDX |
| email | VARCHAR(100) | 邮箱 | UK, IDX |
| password_hash | VARCHAR(255) | 密码哈希 | - |
| nickname | VARCHAR(50) | 昵称 | - |
| grade_level | INTEGER | 年级(1-12) | IDX |
| status | ENUM | 账户状态 | IDX |

#### `user_profiles` - 用户学习档案表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| user_id | BIGINT | 用户ID | FK, UK |
| current_difficulty | DECIMAL(3,2) | 当前难度(1.0-5.0) | IDX |
| total_study_time | INTEGER | 总学习时长(分钟) | - |
| total_questions | INTEGER | 总答题数量 | - |
| correct_answers | INTEGER | 正确答题数量 | - |
| streak_days | INTEGER | 连续学习天数 | - |
| user_level | INTEGER | 用户等级 | IDX |

### 2. 📚 题库系统 (2张表)

#### `knowledge_points` - 知识点分类表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| id | BIGSERIAL | 主键 | PK |
| name | VARCHAR(100) | 知识点名称 | - |
| code | VARCHAR(20) | 知识点编码 | UK, IDX |
| parent_id | BIGINT | 父级知识点 | FK, IDX |
| grade_level | INTEGER | 适用年级 | IDX |

#### `questions` - 数学题目表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| id | BIGSERIAL | 主键 | PK |
| title | VARCHAR(200) | 题目标题 | FULLTEXT |
| content | TEXT | 题目内容(LaTeX) | FULLTEXT |
| question_type | ENUM | 题目类型 | IDX |
| difficulty | DECIMAL(3,2) | 难度系数(1.0-5.0) | IDX |
| knowledge_point_id | BIGINT | 关联知识点 | FK, IDX |
| correct_answer | TEXT | 正确答案 | - |
| choices | JSON | 选择题选项 | - |
| hints | JSON | 提示信息 | - |

### 3. 📊 学习行为 (2张表)

#### `answer_records` - 答题记录表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| id | BIGSERIAL | 主键 | PK |
| user_id | BIGINT | 用户ID | FK, IDX |
| question_id | BIGINT | 题目ID | FK, IDX |
| session_id | VARCHAR(64) | 学习会话ID | IDX |
| user_answer | TEXT | 用户答案 | - |
| is_correct | BOOLEAN | 是否正确 | IDX |
| response_time | INTEGER | 答题时间(秒) | - |
| difficulty_at_time | DECIMAL(3,2) | 答题时难度 | - |

#### `learning_sessions` - 学习会话表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| session_id | VARCHAR(64) | 会话ID | UK, IDX |
| user_id | BIGINT | 用户ID | FK, IDX |
| start_time | TIMESTAMP | 开始时间 | IDX |
| duration_minutes | INTEGER | 学习时长 | - |
| questions_count | INTEGER | 答题数量 | - |
| correct_count | INTEGER | 正确数量 | - |

### 4. 🤖 AI系统 (2张表)

#### `ai_model_records` - AI模型记录表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| user_id | BIGINT | 用户ID | FK, IDX |
| model_type | ENUM | 模型类型 | IDX |
| input_features | JSON | 输入特征 | - |
| model_output | JSON | 模型输出 | - |
| confidence_score | DECIMAL(5,4) | 置信度 | IDX |
| processing_time_ms | INTEGER | 处理时间 | - |

#### `difficulty_adjustments` - 难度调节记录表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| user_id | BIGINT | 用户ID | FK, IDX |
| old_difficulty | DECIMAL(3,2) | 调节前难度 | - |
| new_difficulty | DECIMAL(3,2) | 调节后难度 | - |
| adjustment_reason | TEXT | 调节原因 | - |
| confidence | DECIMAL(3,2) | 调节置信度 | - |
| trigger_event | ENUM | 触发事件 | IDX |

### 5. 🎮 游戏化系统 (3张表)

#### `achievements` - 成就系统表
| 字段 | 类型 | 说明 | 索引 |
|-----|------|------|------|
| code | VARCHAR(50) | 成就编码 | UK, IDX |
| name | VARCHAR(100) | 成就名称 | - |
| category | ENUM | 成就分类 | IDX |
| points | INTEGER | 奖励积分 | - |
| rarity | ENUM | 稀有度 | IDX |
| unlock_condition | JSON | 解锁条件 | - |

#### `user_achievements` - 用户成就记录表
#### `leaderboards` - 排行榜表

### 6. ⚙️ 系统配置 (1张表)

#### `system_configs` - 系统配置表

---

## 🔍 数据库视图

### `user_statistics` - 用户统计视图
```sql
-- 提供用户完整的学习统计信息
-- 包括正确率、学习时长、等级等
```

### `question_statistics` - 题目统计视图
```sql
-- 提供题目的使用统计和难度分析
-- 包括使用次数、正确率、平均答题时间等
```

---

## 🚀 核心功能支持

### 1. AI个性化推荐
- ✅ **用户行为追踪**: 完整记录答题历史和学习模式
- ✅ **难度自适应**: 实时调节和记录难度变化
- ✅ **模型训练数据**: AI模型所需的特征和标签数据

### 2. 游戏化体验
- ✅ **成就系统**: 灵活的成就定义和解锁机制
- ✅ **排行榜**: 多维度的排名统计
- ✅ **用户等级**: 基于积分的等级系统

### 3. 学习分析
- ✅ **学习会话**: 完整的学习轨迹记录
- ✅ **知识点掌握**: 基于知识点的学习进度
- ✅ **性能指标**: 多维度的学习效果评估

### 4. 数据洞察
- ✅ **实时统计**: 通过视图提供实时数据查询
- ✅ **历史分析**: 支持时间序列分析
- ✅ **用户画像**: 基于行为数据的用户特征

---

## 📈 性能优化

### 索引策略
- **主键索引**: 所有表的主键自动创建聚簇索引
- **外键索引**: 所有外键字段创建索引，提升JOIN性能
- **查询索引**: 基于业务查询模式创建组合索引
- **全文索引**: 题目内容支持全文搜索

### 分区策略
- **按时间分区**: 答题记录表可按月分区，提升查询性能
- **按用户分区**: 大量用户时可考虑用户ID分区

### 缓存策略
- **Redis缓存**: 热点数据(用户档案、题目信息)缓存
- **查询结果缓存**: 统计查询结果缓存
- **会话数据**: 学习会话数据实时缓存

---

## 🔧 数据库配置建议

### 连接配置
```
最大连接数: 200
连接池大小: 20-50
连接超时: 30秒
查询超时: 60秒
```

### 存储配置
```
字符集: UTF8MB4 (支持emoji和特殊字符)
时区: Asia/Shanghai (+08:00)
事务隔离级别: READ-COMMITTED
```

### 备份策略
```
全量备份: 每日凌晨2点
增量备份: 每6小时一次
备份保留: 30天
```

---

## 🎯 下一步开发建议

1. **API接口开发**: 基于表结构设计RESTful API
2. **GORM模型**: 创建Go语言的ORM模型定义
3. **数据迁移**: 使用migration管理数据库版本
4. **测试数据**: 生成测试数据用于开发调试
5. **监控告警**: 配置数据库性能监控

这个数据库设计为"智学奇境"项目提供了完整的数据支撑，支持AI驱动的个性化学习和游戏化体验！ 🚀
