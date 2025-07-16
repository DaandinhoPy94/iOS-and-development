"""
SQL queries for dashboard analytics
Centralized query management for maintainability
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import logging

from app.database import db

logger = logging.getLogger(__name__)

class DashboardQueries:
    """Dashboard-specific queries"""
    
    @staticmethod
    def get_key_metrics() -> Dict[str, Any]:
        """Get key business metrics"""
        query = """
        SELECT 
            (SELECT COUNT(*) FROM customers) as total_customers,
            (SELECT COUNT(DISTINCT customer_id) FROM orders WHERE order_status IN ('confirmed', 'shipped', 'delivered')) as active_customers,
            (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE order_status IN ('confirmed', 'shipped', 'delivered')) as total_revenue,
            (SELECT COALESCE(AVG(total_amount), 0) FROM orders WHERE order_status IN ('confirmed', 'shipped', 'delivered')) as avg_order_value,
            (SELECT COUNT(*) FROM orders WHERE order_status IN ('confirmed', 'shipped', 'delivered')) as total_orders,
            (SELECT 
                CASE 
                    WHEN COUNT(*) > 0 THEN 
                        ROUND(COUNT(DISTINCT customer_id)::numeric / COUNT(*)::numeric * 100, 2)
                    ELSE 0 
                END 
             FROM customers) as conversion_rate
        """
        
        result = db.execute_one(query)
        return {
            'total_customers': result['total_customers'],
            'active_customers': result['active_customers'],
            'total_revenue': float(result['total_revenue']),
            'avg_order_value': float(result['avg_order_value']),
            'total_orders': result['total_orders'],
            'conversion_rate': float(result['conversion_rate'])
        }
    
    @staticmethod
    def get_revenue_trend(days: int = 30) -> List[Dict[str, Any]]:
        """Get revenue trend for specified days"""
        query = """
        SELECT 
            DATE(order_date) as date,
            COUNT(*) as orders,
            COALESCE(SUM(total_amount), 0) as revenue
        FROM orders
        WHERE order_status IN ('confirmed', 'shipped', 'delivered')
            AND order_date >= CURRENT_DATE - INTERVAL '%s days'
        GROUP BY DATE(order_date)
        ORDER BY date
        """
        
        results = db.execute_query(query, (days,))
        return [
            {
                'date': row['date'].isoformat(),
                'revenue': float(row['revenue']),
                'orders': row['orders']
            }
            for row in results
        ]
    
    @staticmethod
    def get_top_customers(limit: int = 10) -> List[Dict[str, Any]]:
        """Get top customers by revenue"""
        query = """
        SELECT 
            c.customer_id,
            c.first_name || ' ' || c.last_name as name,
            c.customer_tier as tier,
            COUNT(o.order_id) as total_orders,
            COALESCE(SUM(o.total_amount), 0) as total_spent
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id 
            AND o.order_status IN ('confirmed', 'shipped', 'delivered')
        GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_tier
        HAVING COUNT(o.order_id) > 0
        ORDER BY total_spent DESC
        LIMIT %s
        """
        
        results = db.execute_query(query, (limit,))
        return [
            {
                'customer_id': row['customer_id'],
                'name': row['name'],
                'tier': row['tier'],
                'total_orders': row['total_orders'],
                'total_spent': float(row['total_spent'])
            }
            for row in results
        ]
    
    @staticmethod
    def get_churn_risk_summary() -> Dict[str, Any]:
        """Get churn risk summary"""
        query = """
        WITH customer_activity AS (
            SELECT 
                c.customer_id,
                MAX(o.order_date) as last_order_date,
                COUNT(o.order_id) as total_orders,
                CURRENT_DATE - MAX(o.order_date) as days_since_last_order
            FROM customers c
            LEFT JOIN orders o ON c.customer_id = o.customer_id
                AND o.order_status IN ('confirmed', 'shipped', 'delivered')
            GROUP BY c.customer_id
            HAVING COUNT(o.order_id) > 0
        )
        SELECT 
            COUNT(CASE WHEN EXTRACT(DAYS FROM days_since_last_order) > 120 THEN 1 END) as high_risk_count,
            COUNT(CASE WHEN EXTRACT(DAYS FROM days_since_last_order) BETWEEN 60 AND 120 THEN 1 END) as medium_risk_count,
            COUNT(CASE WHEN EXTRACT(DAYS FROM days_since_last_order) < 60 THEN 1 END) as low_risk_count,
            COUNT(*) as total_analyzed,
            AVG(CASE 
                WHEN EXTRACT(DAYS FROM days_since_last_order) > 120 THEN 0.8
                WHEN EXTRACT(DAYS FROM days_since_last_order) > 60 THEN 0.5
                ELSE 0.2
            END) as avg_risk
        FROM customer_activity
        """
        
        result = db.execute_one(query)
        return {
            'high_risk_count': result['high_risk_count'] or 0,
            'medium_risk_count': result['medium_risk_count'] or 0,
            'low_risk_count': result['low_risk_count'] or 0,
            'predictions_made': result['total_analyzed'] or 0,
            'avg_risk': float(result['avg_risk'] or 0.15)
        }
    
    @staticmethod
    def get_revenue_metrics(days: int) -> Dict[str, Any]:
        """Get detailed revenue metrics"""
        query = """
        WITH period_data AS (
            SELECT 
                COUNT(*) as orders,
                COUNT(DISTINCT customer_id) as unique_customers,
                COALESCE(SUM(total_amount), 0) as revenue,
                COALESCE(AVG(total_amount), 0) as avg_order_value,
                COALESCE(SUM(discount_amount), 0) as total_discounts
            FROM orders
            WHERE order_status IN ('confirmed', 'shipped', 'delivered')
                AND order_date >= CURRENT_DATE - INTERVAL '%s days'
        ),
        previous_period AS (
            SELECT COALESCE(SUM(total_amount), 0) as prev_revenue
            FROM orders
            WHERE order_status IN ('confirmed', 'shipped', 'delivered')
                AND order_date >= CURRENT_DATE - INTERVAL '%s days'
                AND order_date < CURRENT_DATE - INTERVAL '%s days'
        )
        SELECT 
            p.*,
            pp.prev_revenue,
            CASE 
                WHEN pp.prev_revenue > 0 THEN 
                    ROUND(((p.revenue - pp.prev_revenue) / pp.prev_revenue) * 100, 2)
                ELSE 0
            END as growth_rate
        FROM period_data p, previous_period pp
        """
        
        result = db.execute_one(query, (days, days*2, days))
        return {
            'period_days': days,
            'total_revenue': float(result['revenue']),
            'total_orders': result['orders'],
            'unique_customers': result['unique_customers'],
            'avg_order_value': float(result['avg_order_value']),
            'total_discounts': float(result['total_discounts']),
            'growth_rate': float(result['growth_rate'])
        }
    
    @staticmethod
    def get_customer_metrics(days: int) -> Dict[str, Any]:
        """Get customer-specific metrics"""
        query = """
        WITH new_customers AS (
            SELECT COUNT(*) as count
            FROM customers
            WHERE registration_date >= CURRENT_DATE - INTERVAL '%s days'
        ),
        active_customers AS (
            SELECT COUNT(DISTINCT customer_id) as count
            FROM orders
            WHERE order_date >= CURRENT_DATE - INTERVAL '%s days'
                AND order_status IN ('confirmed', 'shipped', 'delivered')
        ),
        tier_breakdown AS (
            SELECT 
                customer_tier,
                COUNT(*) as count
            FROM customers
            GROUP BY customer_tier
        )
        SELECT 
            (SELECT count FROM new_customers) as new_customers,
            (SELECT count FROM active_customers) as active_customers,
            (SELECT COUNT(*) FROM customers) as total_customers,
            (SELECT json_object_agg(customer_tier, count) FROM tier_breakdown) as tier_breakdown
        """
        
        result = db.execute_one(query, (days, days))
        return {
            'period_days': days,
            'new_customers': result['new_customers'],
            'active_customers': result['active_customers'],
            'total_customers': result['total_customers'],
            'tier_breakdown': result['tier_breakdown'] or {}
        }
    
    @staticmethod
    def get_product_metrics(days: int) -> Dict[str, Any]:
        """Get product performance metrics"""
        query = """
        WITH period_sales AS (
            SELECT 
                p.product_id,
                p.product_name,
                p.brand,
                cat.category_name,
                COUNT(oi.order_item_id) as units_sold,
                COALESCE(SUM(oi.line_total), 0) as revenue
            FROM products p
            JOIN categories cat ON p.category_id = cat.category_id
            LEFT JOIN order_items oi ON p.product_id = oi.product_id
            LEFT JOIN orders o ON oi.order_id = o.order_id
            WHERE o.order_date >= CURRENT_DATE - INTERVAL '%s days'
                AND o.order_status IN ('confirmed', 'shipped', 'delivered')
            GROUP BY p.product_id, p.product_name, p.brand, cat.category_name
            ORDER BY revenue DESC
            LIMIT 10
        )
        SELECT 
            (SELECT COUNT(DISTINCT product_id) FROM order_items oi
             JOIN orders o ON oi.order_id = o.order_id
             WHERE o.order_date >= CURRENT_DATE - INTERVAL '%s days') as products_sold,
            (SELECT COUNT(*) FROM products WHERE is_active = true) as total_active_products,
            (SELECT json_agg(row_to_json(ps)) FROM period_sales ps) as top_products
        """
        
        result = db.execute_one(query, (days, days))
        return {
            'period_days': days,
            'products_sold': result['products_sold'],
            'total_active_products': result['total_active_products'],
            'top_products': result['top_products'] or []
        }
    
    @staticmethod
    def get_revenue_detailed(days: int, grouping: str = 'daily') -> List[Dict[str, Any]]:
        """Get detailed revenue data with custom grouping"""
        
        # Determine date truncation based on grouping
        date_trunc = {
            'daily': 'day',
            'weekly': 'week',
            'monthly': 'month'
        }.get(grouping, 'day')
        
        query = f"""
        SELECT 
            DATE_TRUNC('{date_trunc}', order_date) as period,
            COUNT(*) as orders,
            COUNT(DISTINCT customer_id) as customers,
            COALESCE(SUM(total_amount), 0) as revenue
        FROM orders
        WHERE order_status IN ('confirmed', 'shipped', 'delivered')
            AND order_date >= CURRENT_DATE - INTERVAL '%s days'
        GROUP BY DATE_TRUNC('{date_trunc}', order_date)
        ORDER BY period
        """
        
        results = db.execute_query(query, (days,))
        return [
            {
                'date': row['period'].isoformat(),
                'orders': row['orders'],
                'customers': row['customers'],
                'revenue': float(row['revenue'])
            }
            for row in results
        ]