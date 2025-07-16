"""
Pydantic models for API request/response validation
Ensures type safety and automatic documentation
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

# Base response model
class BaseResponse(BaseModel):
    """Base response with common fields"""
    status: str = Field(..., description="Response status: success or error")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    message: Optional[str] = None

# Dashboard models
class Metrics(BaseModel):
    """Key business metrics"""
    totalCustomers: int = Field(..., description="Total number of customers")
    activeCustomers: int = Field(..., description="Customers with recent orders")
    totalRevenue: float = Field(..., description="Total revenue all-time")
    avgOrderValue: float = Field(..., description="Average order value")
    totalOrders: int = Field(..., description="Total number of orders")
    conversionRate: float = Field(0.0, description="Conversion rate percentage")
    revenueGrowth: float = Field(0.0, description="Revenue growth percentage")

class MLInsights(BaseModel):
    """Machine learning insights"""
    modelAccuracy: float = Field(..., description="ML model accuracy")
    highRiskCustomers: int = Field(..., description="Number of high-risk customers")
    predictionsToday: int = Field(..., description="Predictions made today")
    avgChurnRisk: float = Field(..., description="Average churn risk score")

class Alert(BaseModel):
    """Business alert"""
    type: str = Field(..., description="Alert type: warning, success, info")
    title: str = Field(..., description="Alert title")
    message: str = Field(..., description="Alert message")
    severity: str = Field("medium", description="Alert severity: low, medium, high")

class CustomerSummary(BaseModel):
    """Customer summary for dashboard"""
    customer_id: int
    name: str
    tier: str
    total_spent: float
    total_orders: int
    risk_level: Optional[str] = None

class RevenueTrend(BaseModel):
    """Revenue trend data point"""
    date: str
    revenue: float
    orders: int
    is_forecast: bool = False

class DashboardData(BaseModel):
    """Complete dashboard data"""
    metrics: Metrics
    ml_insights: MLInsights
    revenue_trend: List[RevenueTrend]
    top_customers: List[CustomerSummary]
    alerts: List[Alert]

class DashboardResponse(BaseResponse):
    """Dashboard API response"""
    data: DashboardData

# Metrics models
class MetricsData(BaseModel):
    """Generic metrics data"""
    metric_type: str
    period: str
    values: Dict[str, Any]

class MetricsResponse(BaseResponse):
    """Metrics API response"""
    metric_type: str
    period: str
    data: Dict[str, Any]

# Revenue models
class RevenueDataPoint(BaseModel):
    """Single revenue data point"""
    date: str
    revenue: float
    orders: int
    customers: int

class RevenueSummary(BaseModel):
    """Revenue summary statistics"""
    total_revenue: float
    avg_daily_revenue: float
    peak_day: Optional[str]
    trend: str

class RevenueData(BaseResponse):
    """Revenue API response"""
    period_days: int
    grouping: str
    data: Dict[str, Any]

# Customer models
class Customer(BaseModel):
    """Customer model"""
    customer_id: int
    email: str
    first_name: str
    last_name: str
    customer_tier: str
    registration_date: datetime
    total_orders: int = 0
    total_spent: float = 0.0
    churn_risk: Optional[float] = None
    
class CustomerListResponse(BaseResponse):
    """Customer list API response"""
    customers: List[Customer]
    total: int
    page: int
    page_size: int

# Product models
class Product(BaseModel):
    """Product model"""
    product_id: int
    product_name: str
    brand: str
    category: str
    price: float
    total_sold: int = 0
    revenue: float = 0.0
    
class ProductListResponse(BaseResponse):
    """Product list API response"""
    products: List[Product]
    total: int

# Analytics models
class ChurnPrediction(BaseModel):
    """Churn prediction result"""
    customer_id: int
    customer_name: str
    churn_probability: float
    risk_level: str
    recommended_action: str

class SalesForecast(BaseModel):
    """Sales forecast data"""
    date: str
    predicted_revenue: float
    confidence_lower: float
    confidence_upper: float

class AnalyticsResponse(BaseResponse):
    """Analytics API response"""
    analysis_type: str
    data: Dict[str, Any]

# Error model
class ErrorResponse(BaseModel):
    """Error response model"""
    error: str
    message: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    details: Optional[Dict[str, Any]] = None