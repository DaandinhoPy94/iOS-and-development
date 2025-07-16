# 🚀 AI Analytics API

Professional REST API for AI-powered analytics dashboard. Built with FastAPI for high performance and designed specifically for iOS/mobile apps.

## 🎯 Features

- **High Performance**: Async FastAPI with connection pooling
- **iOS Optimized**: CORS configured, lightweight responses
- **Real-time Data**: Live metrics endpoint for instant updates
- **ML Integration**: Ready for your trained models
- **Auto Documentation**: Interactive API docs at `/docs`
- **Type Safety**: Full Pydantic validation
- **Production Ready**: Health checks, error handling, logging

## 🔧 Quick Start

### Local Development

```bash
# Clone repository
git clone <your-repo-url>
cd ai-analytics-api

# Setup virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your Supabase credentials

# Run development server
uvicorn app.main:app --reload

# API available at http://localhost:8000
# Docs at http://localhost:8000/docs
```

### 🚄 Deploy to Railway

1. **Push to GitHub**
```bash
git init
git add .
git commit -m "Initial API setup"
git remote add origin <your-github-repo>
git push -u origin main
```

2. **Deploy on Railway**
- Go to [railway.app](https://railway.app)
- Click "New Project" → "Deploy from GitHub repo"
- Select your repository
- Railway will auto-detect FastAPI and deploy!

3. **Add Environment Variables**
In Railway dashboard:
- Go to Variables tab
- Add: `DATABASE_URL` or `SUPABASE_DATABASE_URL`
- Add: `SECRET_KEY` (generate a secure one)
- Railway provides `PORT` automatically

4. **Your API URL**
Railway will give you a URL like:
```
https://ai-analytics-api-production.up.railway.app
```

## 📱 iOS Integration

### Swift Example
```swift
// API Client
class AnalyticsAPI {
    let baseURL = "https://your-api.up.railway.app/api/v1"
    
    func fetchDashboard() async throws -> DashboardData {
        let url = URL(string: "\(baseURL)/dashboard")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(DashboardData.self, from: data)
    }
    
    func fetchLiveMetrics() async throws -> LiveMetrics {
        let url = URL(string: "\(baseURL)/dashboard/live")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(LiveMetrics.self, from: data)
    }
}

// Usage in SwiftUI
struct DashboardView: View {
    @State private var metrics: DashboardData?
    
    var body: some View {
        // Your UI here
    }
    
    func loadData() async {
        do {
            metrics = try await api.fetchDashboard()
        } catch {
            print("Error: \(error)")
        }
    }
}
```

## 🔌 API Endpoints

### Dashboard
- `GET /api/v1/dashboard` - Complete dashboard data
- `GET /api/v1/dashboard/live` - Real-time metrics
- `GET /api/v1/dashboard/metrics` - Specific metrics
- `GET /api/v1/dashboard/revenue` - Revenue analysis

### Customers
- `GET /api/v1/customers` - List customers
- `GET /api/v1/customers/{id}` - Get customer details
- `GET /api/v1/customers/at-risk` - High churn risk customers

### Analytics
- `GET /api/v1/analytics/churn-predictions` - ML predictions
- `GET /api/v1/analytics/sales-forecast` - Revenue forecast

### Health
- `GET /health` - Health check
- `GET /` - API info

## 📊 Response Format

All responses follow this structure:
```json
{
  "status": "success",
  "timestamp": "2024-07-11T12:00:00Z",
  "data": {
    // Response data here
  }
}
```

Error responses:
```json
{
  "error": "Error type",
  "message": "Human readable message",
  "timestamp": "2024-07-11T12:00:00Z"
}
```

## 🧪 Testing

```bash
# Run tests
pytest

# Test specific endpoint
curl http://localhost:8000/api/v1/dashboard

# Test with httpie (prettier output)
http GET localhost:8000/api/v1/dashboard
```

## 🔐 Security

- JWT authentication ready (uncomment in code)
- Rate limiting configured
- CORS protection
- SQL injection prevention
- Environment variable secrets

## 🚀 Performance

- Connection pooling for database
- Response caching (5 min default)
- Async request handling
- Optimized SQL queries
- Lightweight JSON responses

## 📈 Monitoring

- Health endpoint for uptime monitoring
- Structured logging
- Error tracking ready
- Response time logging

## 🔧 Configuration

Edit `app/config.py` for:
- Cache TTL
- Rate limits
- Pool sizes
- CORS origins
- API versioning

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests
4. Submit pull request

## 📝 License

MIT License - Use freely for your projects!

---

Built with ❤️ for the AI Analytics Platform