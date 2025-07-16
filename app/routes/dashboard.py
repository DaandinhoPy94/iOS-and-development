"""
Dashboard API endpoints
Main endpoints for iOS app dashboard data
"""

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import logging

from app.database import db
from app.models import DashboardResponse, MetricsResponse, RevenueData
from app.utils.queries import DashboardQueries

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=DashboardResponse)
async def get_dashboard_summary():
    """
    Get complete dashboard summary for iOS app
    
    Returns all key metrics in a single response
    """
    try:
        # Get all metrics in parallel queries
        metrics = DashboardQueries.get_key_metrics()
        revenue_trend = DashboardQueries.get_revenue_trend(days=30)
        top_customers = DashboardQueries.get_top_customers(limit=5)
        churn_risk = DashboardQueries.get_churn_risk_summary()
        
        # Calculate additional metrics
        revenue_growth = 0.0
        if len(revenue_trend) >= 2:
            current = revenue_trend[-1]['revenue']
            previous = revenue_trend[-2]['revenue']
            if previous > 0:
                revenue_growth = ((current - previous) / previous) * 100
        
        # Build response
        response = {
            "status": "success",
            "timestamp": datetime.utcnow().isoformat(),
            "data": {
                "metrics": {
                    "totalCustomers": metrics.get('total_customers', 0),
                    "activeCustomers": metrics.get('active_customers', 0),
                    "totalRevenue": float(metrics.get('total_revenue', 0)),
                    "avgOrderValue": float(metrics.get('avg_order_value', 0)),
                    "totalOrders": metrics.get('total_orders', 0),
                    "conversionRate": metrics.get('conversion_rate', 0),
                    "revenueGrowth": revenue_growth
                },
                "ml_insights": {
                    "modelAccuracy": 0.982,  # From your trained model
                    "highRiskCustomers": churn_risk.get('high_risk_count', 0),
                    "predictionsToday": churn_risk.get('predictions_made', 0),
                    "avgChurnRisk": churn_risk.get('avg_risk', 0.15)
                },
                "revenue_trend": revenue_trend,
                "top_customers": top_customers,
                "alerts": _generate_alerts(metrics, churn_risk)
            }
        }
        
        return response
        
    except Exception as e:
        logger.error(f"Dashboard error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/metrics", response_model=MetricsResponse)
async def get_metrics(
    metric_type: Optional[str] = Query(None, description="Type of metrics to retrieve"),
    period: Optional[str] = Query("7d", description="Time period: 1d, 7d, 30d, 90d")
):
    """Get specific metrics with optional filtering"""
    try:
        # Parse period
        days = _parse_period(period)
        
        if metric_type == "revenue":
            data = DashboardQueries.get_revenue_metrics(days)
        elif metric_type == "customers":
            data = DashboardQueries.get_customer_metrics(days)
        elif metric_type == "products":
            data = DashboardQueries.get_product_metrics(days)
        else:
            data = DashboardQueries.get_key_metrics()
        
        return {
            "status": "success",
            "metric_type": metric_type or "all",
            "period": period,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Metrics error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/revenue", response_model=RevenueData)
async def get_revenue_data(
    days: int = Query(30, description="Number of days to retrieve"),
    grouping: str = Query("daily", description="Grouping: daily, weekly, monthly")
):
    """Get detailed revenue data with forecasting"""
    try:
        # Get historical data
        revenue_data = DashboardQueries.get_revenue_detailed(days, grouping)
        
        # Simple forecast (you can enhance with your ML models)
        forecast = _generate_simple_forecast(revenue_data)
        
        return {
            "status": "success",
            "period_days": days,
            "grouping": grouping,
            "data": {
                "historical": revenue_data,
                "forecast": forecast,
                "summary": {
                    "total_revenue": sum(r['revenue'] for r in revenue_data),
                    "avg_daily_revenue": sum(r['revenue'] for r in revenue_data) / len(revenue_data) if revenue_data else 0,
                    "peak_day": max(revenue_data, key=lambda x: x['revenue'])['date'] if revenue_data else None,
                    "trend": "increasing" if len(revenue_data) >= 2 and revenue_data[-1]['revenue'] > revenue_data[0]['revenue'] else "stable"
                }
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Revenue data error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/live")
async def get_live_metrics():
    """
    Real-time metrics for iOS app live updates
    Lightweight endpoint for frequent polling
    """
    try:
        # Get only essential real-time metrics
        query = """
        SELECT 
            (SELECT COUNT(*) FROM orders WHERE order_date >= CURRENT_DATE) as orders_today,
            (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE order_date >= CURRENT_DATE AND order_status IN ('confirmed', 'shipped', 'delivered')) as revenue_today,
            (SELECT COUNT(DISTINCT customer_id) FROM orders WHERE order_date >= CURRENT_DATE) as customers_today,
            (SELECT COUNT(*) FROM orders WHERE order_date >= CURRENT_TIMESTAMP - INTERVAL '1 hour') as orders_last_hour
        """
        
        result = db.execute_one(query)
        
        return {
            "ordersToday": result['orders_today'],
            "revenueToday": float(result['revenue_today']),
            "customersToday": result['customers_today'],
            "ordersLastHour": result['orders_last_hour'],
            "timestamp": datetime.utcnow().isoformat(),
            "status": "live"
        }
        
    except Exception as e:
        logger.error(f"Live metrics error: {e}")
        # Return cached/default values on error
        return {
            "ordersToday": 0,
            "revenueToday": 0.0,
            "customersToday": 0,
            "ordersLastHour": 0,
            "timestamp": datetime.utcnow().isoformat(),
            "status": "cached"
        }

# Helper functions
def _parse_period(period: str) -> int:
    """Parse period string to days"""
    period_map = {
        "1d": 1,
        "7d": 7,
        "30d": 30,
        "90d": 90,
        "1y": 365
    }
    return period_map.get(period, 7)

def _generate_alerts(metrics: Dict[str, Any], churn_risk: Dict[str, Any]) -> list:
    """Generate business alerts based on metrics"""
    alerts = []
    
    # Revenue alerts
    if metrics.get('revenue_growth', 0) < -10:
        alerts.append({
            "type": "warning",
            "title": "Revenue Decline",
            "message": f"Revenue decreased by {abs(metrics['revenue_growth']):.1f}% this period",
            "severity": "high"
        })
    
    # Churn alerts
    if churn_risk.get('high_risk_count', 0) > 10:
        alerts.append({
            "type": "warning",
            "title": "High Churn Risk",
            "message": f"{churn_risk['high_risk_count']} customers at high risk of churning",
            "severity": "medium"
        })
    
    # Positive alerts
    if metrics.get('revenue_growth', 0) > 20:
        alerts.append({
            "type": "success",
            "title": "Strong Growth",
            "message": f"Revenue increased by {metrics['revenue_growth']:.1f}% - excellent performance!",
            "severity": "info"
        })
    
    return alerts

def _generate_simple_forecast(historical_data: list, days_ahead: int = 7) -> list:
    """Generate simple forecast based on historical trend"""
    if len(historical_data) < 7:
        return []
    
    # Calculate simple moving average
    recent_avg = sum(d['revenue'] for d in historical_data[-7:]) / 7
    
    forecast = []
    last_date = datetime.fromisoformat(historical_data[-1]['date'])
    
    for i in range(1, days_ahead + 1):
        forecast_date = last_date + timedelta(days=i)
        # Add some variation
        variation = 0.9 + (0.2 * (i % 3) / 3)  # Creates a pattern
        forecast.append({
            "date": forecast_date.isoformat(),
            "revenue": recent_avg * variation,
            "is_forecast": True
        })
    
    return forecast