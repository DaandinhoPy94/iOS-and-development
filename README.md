# 🚀 iOS & AI Analytics - Full Stack Project

Een complete full-stack oplossing voor AI-gedreven business analytics, bestaande uit een professionele FastAPI backend en een native iOS SwiftUI app.

## 📱 Project Overzicht

Dit project combineert twee krachtige componenten:
- **AI Analytics API** - Python FastAPI backend met ML-integratie
- **iOS Business Dashboard** - Native SwiftUI app voor real-time insights

### 🏗️ Architectuur

```
iOS-and-development/
├── 📱 AIBusinessDashboard/          # iOS SwiftUI App
│   ├── AIBusinessDashboard/         # iOS source code
│   ├── APIService.swift            # API client
│   ├── ContentView.swift           # Dashboard UI
│   └── DashboardData.swift         # Data models
├── 🐍 Backend API/                  # FastAPI Backend
│   ├── app/                        # Python source
│   ├── requirements.txt            # Dependencies
│   ├── Dockerfile                  # Container config
│   └── railway.json               # Deployment config
└── 📚 Documentation/
    ├── README.md                   # Deze file
    └── Package.swift              # Swift package
```

## ✨ Features

### 📊 AI Analytics API
- **High Performance**: Async FastAPI met connection pooling
- **ML Integration**: Churn prediction en sales forecasting
- **Real-time Data**: Live metrics voor iOS app
- **Auto Documentation**: Interactive API docs op `/docs`
- **Production Ready**: Health checks, error handling, logging
- **Railway Deployment**: One-click deployment ready

### 📱 iOS Business Dashboard
- **Native SwiftUI**: Moderne iOS interface
- **Real-time Updates**: Live data refresh elke 30 seconden
- **Beautiful UI**: Gradient cards met animaties
- **Pull to Refresh**: Native iOS interacties
- **Responsive Design**: Werkt op iPhone en iPad
- **Dark Mode Support**: Automatische theme switching

### 🤖 ML Capabilities
- **Churn Prediction**: Identificeer klanten met hoge churn risk
- **Sales Forecasting**: Voorspel toekomstige revenue
- **Customer Segmentation**: RFM analyse voor targeting
- **Anomaly Detection**: Automatische detectie van afwijkingen

## 🚀 Quick Start

### 1. Backend API Starten

```bash
# Navigate naar project directory
cd iOS-and-development

# Python virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start development server
python run.py

# API beschikbaar op http://localhost:8000
# Docs op http://localhost:8000/docs
```

### 2. iOS App Starten

```bash
# Open Xcode project
open AIBusinessDashboard/AIBusinessDashboard.xcodeproj

# Of via command line
xed AIBusinessDashboard/
```

**In Xcode:**
1. Select een simulator of device
2. Druk op ▶️ Run
3. App start automatisch

### 3. Live Connection Testen

De iOS app connecteert automatisch met:
- **Local**: `http://localhost:8000` (development)
- **Production**: `https://your-api.up.railway.app` (deployed)

## 🌐 Production Deployment

### Railway Deployment (Aanbevolen)

1. **Push naar GitHub**
```bash
git add .
git commit -m "Full-stack iOS & API project"
git push
```

2. **Deploy op Railway**
- Ga naar [railway.app](https://railway.app)
- Connect GitHub repository
- Railway detecteert automatisch FastAPI
- Deployment URL: `https://ios-and-development-production.up.railway.app`

3. **iOS App Configureren**
```swift
// In APIService.swift
private let baseURL = "https://your-railway-url.up.railway.app"
```

## 📱 iOS App Usage

### Dashboard Features
- **Revenue Forecast**: €125,000+ met 12.5% groei
- **Model Accuracy**: 98.2% ML model prestatie
- **Active Customers**: 1,247 actieve klanten
- **Daily Predictions**: 342 voorspellingen vandaag

### Real-time Updates
- Auto-refresh elke 30 seconden
- Pull-to-refresh gesture
- Live status indicator
- Offline graceful degradation

### Navigation
```swift
// Dashboard cards tonen:
MetricCard(
    title: "Revenue Forecast",
    value: "€125,000",
    change: "+12.5%",
    icon: "chart.line.uptrend.xyaxis"
)
```

## 🔌 API Integration

### Swift API Client
```swift
class APIService: ObservableObject {
    func fetchDashboardData() async throws -> DashboardData {
        let url = URL(string: "\(baseURL)/api/v1/dashboard")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(DashboardData.self, from: data)
    }
}
```

### Key Endpoints
- `GET /api/v1/dashboard` - Complete dashboard
- `GET /api/v1/dashboard/live` - Real-time metrics
- `GET /api/v1/analytics/churn-predictions` - ML predictions
- `GET /api/v1/customers/at-risk` - High-risk customers

## 🛠️ Development

### Backend Development
```bash
# Hot reload development
uvicorn app.main:app --reload

# Run tests
pytest

# Check API health
curl http://localhost:8000/health
```

### iOS Development
```bash
# Open in Xcode
xed AIBusinessDashboard/

# Build for simulator
xcodebuild -scheme AIBusinessDashboard -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Environment Variables
```bash
# .env file voor backend
DATABASE_URL=your_supabase_url
SECRET_KEY=your_secret_key
ENVIRONMENT=development
```

## 📊 Data Models

### Dashboard Response
```json
{
  "status": "success",
  "data": {
    "metrics": {
      "totalRevenue": 125000.0,
      "activeCustomers": 1247,
      "modelAccuracy": 0.982
    },
    "revenue_trend": [...],
    "top_customers": [...]
  }
}
```

### Swift Models
```swift
struct DashboardData: Codable {
    let revenueForecast: Double?
    let modelAccuracy: Double?
    let activeCustomers: Int?
    let lastUpdated: Date?
}
```

## 🧪 Testing

### API Testing
```bash
# Test alle endpoints
python test_api_endpoints.py

# Individual endpoint
curl -X GET "http://localhost:8000/api/v1/dashboard" \
     -H "accept: application/json"
```

### iOS Testing
- Unit tests in `AIBusinessDashboardTests/`
- UI tests in `AIBusinessDashboardUITests/`
- Manual testing op simulator/device

## 🚀 Production Considerations

### Security
- JWT authentication (commentaar weggehaald in production)
- Rate limiting geconfigureerd
- CORS protection
- Environment variables voor secrets

### Performance
- Connection pooling voor database
- Response caching (5 min default)
- Async request handling
- Efficient SQL queries

### Monitoring
- Health endpoint voor uptime
- Structured logging
- Error tracking ready
- Performance metrics

## 📈 Analytics Features

### Machine Learning
- **Churn Prediction**: Random Forest met 98.2% accuracy
- **Sales Forecasting**: Gradient Boosting voor revenue
- **Customer Segmentation**: RFM analysis
- **Anomaly Detection**: Statistical outlier detection

### Business Intelligence
- Revenue growth tracking
- Customer lifetime value
- Product performance metrics
- Real-time alerting system

## 🤝 Contributing

1. Fork het project
2. Create feature branch (`git checkout -b feature/nieuwe-feature`)
3. Commit changes (`git commit -m 'Add nieuwe feature'`)
4. Push naar branch (`git push origin feature/nieuwe-feature`)
5. Open Pull Request

## 📝 Roadmap

### Aankomende Features
- [ ] Push notifications voor iOS
- [ ] Advanced ML model training
- [ ] Multi-tenant support
- [ ] Real-time WebSocket updates
- [ ] Apple Watch companion app
- [ ] Offline data synchronization

### Huidige Status
- ✅ FastAPI backend volledig functioneel
- ✅ iOS SwiftUI app met real-time data
- ✅ Railway deployment geconfigureerd
- ✅ ML prediction endpoints
- ✅ Complete dashboard analytics

## 🎯 Use Cases

### Voor Business Owners
- Real-time revenue monitoring
- Customer churn prevention
- Sales forecasting en planning
- Mobile toegang tot business metrics

### Voor Developers
- Full-stack Swift + Python template
- API-first architectuur
- Modern iOS development patterns
- ML integration voorbeelden

## 📞 Support

Voor vragen of problemen:
- Open een GitHub Issue
- Check de `/docs` endpoint voor API documentatie
- Review de code comments voor implementatie details

## 📄 License

MIT License - Gebruik vrij voor je eigen projecten!

---

**Gemaakt met ❤️ voor moderne iOS en API development**

*Dit project demonstreert best practices voor full-stack development met Swift, Python, FastAPI, en machine learning integratie.*