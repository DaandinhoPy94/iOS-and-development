# routes/products.py
"""Product API endpoints"""

from fastapi import APIRouter, HTTPException
# # from app.database import db

router = APIRouter()

@router.get("/")
async def get_products():
    """Get product list"""
    try:
        query = """
        SELECT 
            p.product_id,
            p.product_name,
            p.brand,
            cat.category_name,
            p.selling_price,
            COUNT(oi.order_item_id) as times_sold,
            COALESCE(SUM(oi.quantity), 0) as units_sold
        FROM products p
        JOIN categories cat ON p.category_id = cat.category_id
        LEFT JOIN order_items oi ON p.product_id = oi.product_id
        WHERE p.is_active = true
        GROUP BY p.product_id, p.product_name, p.brand, cat.category_name, p.selling_price
        ORDER BY units_sold DESC
        LIMIT 50
        """
        
        results = db.execute_query(query)
        return {
            "status": "success",
            "products": results,
            "total": len(results)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# routes/analytics.py
"""Analytics API endpoints"""

from fastapi import APIRouter, HTTPException
# # from app.database import db

router = APIRouter()

@router.get("/churn-predictions")
async def get_churn_predictions():
    """Get ML churn predictions"""
    # Placeholder - integrate your ML model here
    return {
        "status": "success",
        "predictions": [
            {
                "customer_id": 123,
                "churn_probability": 0.75,
                "risk_level": "High",
                "recommended_action": "Send win-back campaign"
            }
        ],
        "model_version": "1.0.0",
        "accuracy": 0.982
    }

@router.get("/sales-forecast")
async def get_sales_forecast():
    """Get sales forecast"""
    # Placeholder - integrate your forecasting model
    return {
        "status": "success",
        "forecast": [
            {
                "date": "2024-07-12",
                "predicted_revenue": 15234.50,
                "confidence_interval": [14000, 16500]
            }
        ],
        "model": "gradient_boosting",
        "mape": 0.085
    }