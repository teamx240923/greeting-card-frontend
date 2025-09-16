# 🏗️ GreetingCard App Architecture

## Overview

The GreetingCard app is a full-stack application built with a modern microservices architecture that can be easily split into separate repositories when needed.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GreetingCard App                        │
├─────────────────────────────────────────────────────────────┤
│  Frontend (Flutter)          │  Backend (FastAPI)          │
│  ┌─────────────────────────┐  │  ┌─────────────────────────┐ │
│  │  Web (Chrome)           │  │  │  API Gateway            │ │
│  │  Mobile (Android/iOS)   │  │  │  Authentication         │ │
│  │  Desktop (Windows/Mac)  │  │  │  Content Generation     │ │
│  └─────────────────────────┘  │  │  Recommendation Engine  │ │
│                               │  └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │  PostgreSQL     │  │  Redis Cache    │  │  File       │  │
│  │  (Primary DB)   │  │  (Sessions)     │  │  Storage    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Frontend Architecture (Flutter)

### **Technology Stack**
- **Framework**: Flutter 3.16+
- **Language**: Dart
- **State Management**: Riverpod
- **Navigation**: Go Router
- **HTTP Client**: Dio
- **Image Caching**: Cached Network Image

### **Project Structure**
```
frontend/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── material_app.dart         # Material app configuration
│   ├── config/                   # Configuration files
│   ├── models/                   # Data models
│   ├── providers/                # State management
│   ├── screens/                  # UI screens
│   ├── services/                 # API services
│   ├── utils/                    # Utility functions
│   └── widgets/                  # Reusable widgets
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── web/                          # Web platform code
├── test/                         # Unit and widget tests
└── pubspec.yaml                  # Dependencies
```

### **Key Components**

#### **1. State Management (Riverpod)**
```dart
// User provider
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

// Feed provider
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});
```

#### **2. API Services**
```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  Future<List<Card>> getFeed(String userId) async {
    // API call implementation
  }
}
```

#### **3. Navigation (Go Router)**
```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
```

## Backend Architecture (FastAPI)

### **Technology Stack**
- **Framework**: FastAPI
- **Language**: Python 3.11+
- **Database**: PostgreSQL 14+
- **Cache**: Redis 7+
- **ORM**: SQLAlchemy
- **Migrations**: Alembic
- **Authentication**: JWT

### **Project Structure**
```
backend/
├── app/
│   ├── main.py                   # FastAPI application
│   ├── config.py                 # Configuration
│   ├── db.py                     # Database connection
│   ├── deps.py                   # Dependencies
│   ├── models/                   # SQLAlchemy models
│   ├── schemas/                  # Pydantic schemas
│   ├── routes/                   # API routes
│   ├── services/                 # Business logic
│   ├── utils/                    # Utility functions
│   └── worker.py                 # Background tasks
├── migrations/                   # Database migrations
├── storage/                      # File storage
├── tests/                        # Test suite
└── requirements.txt              # Dependencies
```

### **Key Components**

#### **1. API Routes**
```python
# Content generation routes
@router.post("/v1/content/generate")
async def generate_content(request: ContentRequest):
    # Content generation logic
    pass

# Feed routes
@router.get("/v1/feed/for-you/{user_id}")
async def get_feed(user_id: str):
    # Feed generation logic
    pass
```

#### **2. Database Models**
```python
class Card(Base):
    __tablename__ = "cards"
    
    id = Column(String, primary_key=True)
    title = Column(String, nullable=False)
    content_type = Column(String, nullable=False)
    # ... other fields
```

#### **3. Services**
```python
class ContentGenerationService:
    async def generate_content(self, request: ContentRequest):
        # AI content generation logic
        pass

class RecommendationService:
    async def get_recommendations(self, user_id: str):
        # Recommendation algorithm
        pass
```

## Data Flow

### **1. User Interaction Flow**
```
User Action → Frontend → API Call → Backend → Database → Response → Frontend → UI Update
```

### **2. Content Generation Flow**
```
User Request → API → Content Service → AI Generation → Storage → Database → Response
```

### **3. Recommendation Flow**
```
User Interaction → Event Tracking → Database → Recommendation Engine → Personalized Feed
```

## Database Schema

### **Core Tables**
- **`users`**: User profiles and preferences
- **`cards`**: Generated content metadata
- **`events`**: User interactions and analytics
- **`generations`**: Content generation jobs
- **`locations`**: Location data and festivals

### **Relationships**
- Users have many Events
- Cards have many Events
- Generations create Cards
- Locations influence Content

## API Design

### **RESTful Endpoints**
- **Authentication**: `/v1/auth/*`
- **Content**: `/v1/content/*`
- **Feed**: `/v1/feed/*`
- **Events**: `/v1/event/*`
- **Location**: `/v1/loc/*`

### **Response Format**
```json
{
  "success": true,
  "data": { ... },
  "message": "Success",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## Security

### **Authentication**
- JWT tokens for API access
- Guest mode for anonymous users
- Optional user registration

### **Data Protection**
- Input validation with Pydantic
- SQL injection prevention with SQLAlchemy
- CORS configuration
- Rate limiting

## Performance

### **Frontend Optimization**
- Image caching and lazy loading
- State management optimization
- Build optimization for production

### **Backend Optimization**
- Database query optimization
- Redis caching
- Async/await for I/O operations
- Connection pooling

## Scalability

### **Horizontal Scaling**
- Stateless backend design
- Database read replicas
- CDN for static assets
- Load balancing

### **Vertical Scaling**
- Database indexing
- Memory optimization
- CPU optimization
- Storage optimization

## Monitoring

### **Application Metrics**
- API response times
- Error rates
- User engagement metrics
- Content generation metrics

### **Infrastructure Metrics**
- CPU and memory usage
- Database performance
- Network latency
- Storage usage

## Deployment

### **Development**
- Local development with Docker
- Hot reload for frontend
- Database migrations
- Environment configuration

### **Production**
- Docker containers
- Kubernetes orchestration
- CI/CD pipelines
- Monitoring and logging

## Future Enhancements

### **Microservices Migration**
- Split into separate services
- API Gateway
- Service discovery
- Inter-service communication

### **Advanced Features**
- Real-time notifications
- Advanced analytics
- Machine learning models
- Multi-tenant support

## Repository Splitting Strategy

### **Current Structure (Monorepo)**
```
greeting-card-app/
├── backend/          # FastAPI backend
├── frontend/         # Flutter frontend
├── scripts/          # Shared scripts
├── docs/             # Documentation
└── .github/          # CI/CD workflows
```

### **Future Structure (Multi-repo)**
```
greeting-card-backend/     # Backend repository
greeting-card-frontend/    # Frontend repository
greeting-card-docs/        # Documentation repository
greeting-card-infra/       # Infrastructure repository
```

### **Splitting Process**
1. **Copy directories** to new repositories
2. **Update dependencies** and configurations
3. **Set up CI/CD** for each repository
4. **Update documentation** and deployment scripts
5. **Configure inter-service communication**

This architecture provides a solid foundation for both current development and future scaling needs.
