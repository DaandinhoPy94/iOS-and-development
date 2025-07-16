"""
Customer API endpoints
Manage customer data and analytics
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
import logging

from app.database import db
from app.models import Customer, CustomerListResponse

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=CustomerListResponse)
async def get_customers(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    tier: Optional[str] = Query(None, description="Filter by customer tier"),
    sort_by: str = Query("total_spent", description="Sort field: total_spent, registration_date, total_orders")
):
    """Get paginated list of customers"""
    try:
        # Build query with filters
        where_clause = ""
        params = []
        
        if tier:
            where_clause = "WHERE c.customer_tier = %s"
            params.append(tier)
        
        # Calculate offset
        offset = (page - 1) * page_size
        
        # Get total count
        count_query = f"""
        SELECT COUNT(*) as total
        FROM customers c
        {where_clause}
        """
        
        total_result = db.execute_one(count_query, tuple(params) if params else None)
        total = total_result['total']
        
        # Get customers with stats
        query = f"""
        SELECT 
            c.customer_id,
            c.email,
            c.first_name,
            c.last_name,
            c.customer_tier,
            c.registration_date,
            COUNT(o.order_id) as total_orders,
            COALESCE(SUM(o.total_amount), 0) as total_spent
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id 
            AND o.order_status IN ('confirmed', 'shipped', 'delivered')
        {where_clause}
        GROUP BY c.customer_id, c.email, c.first_name, c.last_name, 
                 c.customer_tier, c.registration_date
        ORDER BY {sort_by} DESC
        LIMIT %s OFFSET %s
        """
        
        params.extend([page_size, offset])
        results = db.execute_query(query, tuple(params))
        
        customers = [
            Customer(
                customer_id=row['customer_id'],
                email=row['email'],
                first_name=row['first_name'],
                last_name=row['last_name'],
                customer_tier=row['customer_tier'],
                registration_date=row['registration_date'],
                total_orders=row['total_orders'],
                total_spent=float(row['total_spent'])
            )
            for row in results
        ]
        
        return CustomerListResponse(
            status="success",
            customers=customers,
            total=total,
            page=page,
            page_size=page_size
        )
        
    except Exception as e:
        logger.error(f"Error fetching customers: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{customer_id}")
async def get_customer_detail(customer_id: int):
    """Get detailed customer information"""
    try:
        query = """
        SELECT 
            c.*,
            COUNT(o.order_id) as total_orders,
            COALESCE(SUM(o.total_amount), 0) as total_spent,
            COALESCE(AVG(o.total_amount), 0) as avg_order_value,
            MAX(o.order_date) as last_order_date,
            COUNT(DISTINCT oi.product_id) as unique_products_purchased
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id 
            AND o.order_status IN ('confirmed', 'shipped', 'delivered')
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        WHERE c.customer_id = %s
        GROUP BY c.customer_id
        """
        
        result = db.execute_one(query, (customer_id,))
        
        if not result:
            raise HTTPException(status_code=404, detail="Customer not found")
        
        # Calculate churn risk (simplified)
        days_since_last_order = None
        churn_risk = None
        
        if result['last_order_date']:
            from datetime import datetime
            days_since = (datetime.now().date() - result['last_order_date']).days
            days_since_last_order = days_since
            
            if days_since > 120:
                churn_risk = 0.8
            elif days_since > 60:
                churn_risk = 0.5
            else:
                churn_risk = 0.2
        
        return {
            "status": "success",
            "data": {
                "customer": {
                    "customer_id": result['customer_id'],
                    "email": result['email'],
                    "first_name": result['first_name'],
                    "last_name": result['last_name'],
                    "customer_tier": result['customer_tier'],
                    "registration_date": result['registration_date'].isoformat(),
                    "is_active": result['is_active']
                },
                "statistics": {
                    "total_orders": result['total_orders'],
                    "total_spent": float(result['total_spent']),
                    "avg_order_value": float(result['avg_order_value']),
                    "unique_products": result['unique_products_purchased'],
                    "days_since_last_order": days_since_last_order,
                    "churn_risk": churn_risk
                }
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching customer {customer_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/at-risk")
async def get_at_risk_customers(
    limit: int = Query(20, ge=1, le=100, description="Number of customers to return")
):
    """Get customers at high risk of churning"""
    try:
        query = """
        WITH customer_activity AS (
            SELECT 
                c.customer_id,
                c.first_name,
                c.last_name,
                c.email,
                c.customer_tier,
                COUNT(o.order_id) as total_orders,
                COALESCE(SUM(o.total_amount), 0) as total_spent,
                MAX(o.order_date) as last_order_date,
                CURRENT_DATE - MAX(o.order_date) as days_since_last_order
            FROM customers c
            LEFT JOIN orders o ON c.customer_id = o.customer_id
                AND o.order_status IN ('confirmed', 'shipped', 'delivered')
            GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.customer_tier
            HAVING COUNT(o.order_id) > 0  -- Only customers who have ordered
        )
        SELECT 
            *,
            CASE 
                WHEN EXTRACT(DAYS FROM days_since_last_order) > 120 THEN 0.8
                WHEN EXTRACT(DAYS FROM days_since_last_order) > 90 THEN 0.7
                WHEN EXTRACT(DAYS FROM days_since_last_order) > 60 THEN 0.5
                ELSE 0.2
            END as churn_probability
        FROM customer_activity
        WHERE EXTRACT(DAYS FROM days_since_last_order) > 60  -- At risk threshold
        ORDER BY churn_probability DESC, total_spent DESC
        LIMIT %s
        """
        
        results = db.execute_query(query, (limit,))
        
        at_risk_customers = [
            {
                "customer_id": row['customer_id'],
                "name": f"{row['first_name']} {row['last_name']}",
                "email": row['email'],
                "tier": row['customer_tier'],
                "total_spent": float(row['total_spent']),
                "total_orders": row['total_orders'],
                "days_since_last_order": row['days_since_last_order'],
                "churn_probability": row['churn_probability'],
                "risk_level": "High" if row['churn_probability'] > 0.7 else "Medium"
            }
            for row in results
        ]
        
        return {
            "status": "success",
            "data": {
                "at_risk_customers": at_risk_customers,
                "total_at_risk": len(at_risk_customers),
                "recommendations": [
                    "Send personalized re-engagement emails",
                    "Offer exclusive discounts to high-value at-risk customers",
                    "Analyze purchase patterns to understand churn reasons"
                ]
            }
        }
        
    except Exception as e:
        logger.error(f"Error fetching at-risk customers: {e}")
        raise HTTPException(status_code=500, detail=str(e))