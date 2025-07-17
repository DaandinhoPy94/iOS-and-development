"""
WebSocket endpoints for real-time data streaming
Enables live updates to iOS app
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import List, Dict, Set
import json
import asyncio
import logging
from datetime import datetime
from collections import defaultdict

from app.database import db

logger = logging.getLogger(__name__)
router = APIRouter()

class ConnectionManager:
    """Manages WebSocket connections and broadcasting"""
    
    def __init__(self):
        # Active connections by client ID
        self.active_connections: Dict[str, WebSocket] = {}
        # Subscriptions by message type
        self.subscriptions: Dict[str, Set[str]] = defaultdict(set)
        # Connection metadata
        self.connection_metadata: Dict[str, Dict] = {}
        
    async def connect(self, websocket: WebSocket, client_id: str):
        """Accept new WebSocket connection"""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        self.connection_metadata[client_id] = {
            "connected_at": datetime.utcnow(),
            "last_ping": datetime.utcnow()
        }
        logger.info(f"Client {client_id} connected. Total connections: {len(self.active_connections)}")
        
    def disconnect(self, client_id: str):
        """Remove WebSocket connection"""
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            # Remove from all subscriptions
            for message_type in self.subscriptions:
                self.subscriptions[message_type].discard(client_id)
            if client_id in self.connection_metadata:
                del self.connection_metadata[client_id]
            logger.info(f"Client {client_id} disconnected. Remaining: {len(self.active_connections)}")
            
    async def send_personal_message(self, message: dict, client_id: str):
        """Send message to specific client"""
        if client_id in self.active_connections:
            websocket = self.active_connections[client_id]
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(f"Error sending to {client_id}: {e}")
                self.disconnect(client_id)
                
    async def broadcast(self, message: dict, message_type: str = None):
        """Broadcast message to all connected clients or subscribers"""
        if message_type and message_type in self.subscriptions:
            # Send only to subscribers of this message type
            recipients = self.subscriptions[message_type]
        else:
            # Send to all connected clients
            recipients = set(self.active_connections.keys())
            
        disconnected_clients = []
        
        for client_id in recipients:
            if client_id in self.active_connections:
                try:
                    await self.active_connections[client_id].send_json(message)
                except Exception as e:
                    logger.error(f"Error broadcasting to {client_id}: {e}")
                    disconnected_clients.append(client_id)
                    
        # Clean up disconnected clients
        for client_id in disconnected_clients:
            self.disconnect(client_id)
            
    def subscribe(self, client_id: str, message_types: List[str]):
        """Subscribe client to specific message types"""
        for message_type in message_types:
            self.subscriptions[message_type].add(client_id)
        logger.info(f"Client {client_id} subscribed to: {message_types}")
        
    def unsubscribe(self, client_id: str, message_types: List[str]):
        """Unsubscribe client from message types"""
        for message_type in message_types:
            self.subscriptions[message_type].discard(client_id)

# Global connection manager
manager = ConnectionManager()

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """Main WebSocket endpoint"""
    # Generate unique client ID
    client_id = f"client_{datetime.utcnow().timestamp()}"
    
    await manager.connect(websocket, client_id)
    
    # Send initial connection message
    await manager.send_personal_message({
        "type": "connection",
        "data": {
            "client_id": client_id,
            "status": "connected"
        },
        "timestamp": datetime.utcnow().isoformat()
    }, client_id)
    
    # Start background tasks for this client
    metrics_task = asyncio.create_task(send_metrics_updates(client_id))
    
    try:
        while True:
            # Receive messages from client
            data = await websocket.receive_json()
            
            # Handle different message types
            if data.get("action") == "subscribe":
                message_types = data.get("types", [])
                manager.subscribe(client_id, message_types)
                
            elif data.get("action") == "unsubscribe":
                message_types = data.get("types", [])
                manager.unsubscribe(client_id, message_types)
                
            elif data.get("action") == "ping":
                # Respond to ping
                await manager.send_personal_message({
                    "type": "pong",
                    "timestamp": datetime.utcnow().isoformat()
                }, client_id)
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)
        metrics_task.cancel()
        
    except Exception as e:
        logger.error(f"WebSocket error for {client_id}: {e}")
        manager.disconnect(client_id)
        metrics_task.cancel()

async def send_metrics_updates(client_id: str):
    """Send periodic metrics updates to client"""
    while client_id in manager.active_connections:
        try:
            # Get latest metrics from database
            metrics = await get_live_metrics()
            
            # Send metrics update
            await manager.send_personal_message({
                "type": "metrics",
                "data": metrics,
                "timestamp": datetime.utcnow().isoformat()
            }, client_id)
            
            # Wait 5 seconds before next update
            await asyncio.sleep(5)
            
        except Exception as e:
            logger.error(f"Error sending metrics to {client_id}: {e}")
            break

async def get_live_metrics() -> dict:
    """Get real-time metrics from database"""
    try:
        query = """
        SELECT 
            (SELECT COUNT(*) FROM orders WHERE order_date >= CURRENT_DATE) as orders_today,
            (SELECT COALESCE(SUM(total_amount), 0) FROM orders 
             WHERE order_date >= CURRENT_DATE 
             AND order_status IN ('confirmed', 'shipped', 'delivered')) as revenue_today,
            (SELECT COUNT(DISTINCT customer_id) FROM orders WHERE order_date >= CURRENT_DATE) as customers_today,
            (SELECT COUNT(*) FROM orders WHERE order_date >= CURRENT_TIMESTAMP - INTERVAL '1 hour') as orders_last_hour,
            (SELECT COALESCE(SUM(total_amount), 0) FROM orders 
             WHERE order_date >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
             AND order_status IN ('confirmed', 'shipped', 'delivered')) as last_hour_revenue
        """
        
        # Run async database query
        result = await asyncio.get_event_loop().run_in_executor(
            None, db.execute_one, query
        )
        
        return {
            "ordersToday": result['orders_today'],
            "revenueToday": float(result['revenue_today']),
            "customersToday": result['customers_today'],
            "ordersLastHour": result['orders_last_hour'],
            "lastHourRevenue": float(result['last_hour_revenue']),
            "totalRevenue": float(result['revenue_today']),  # For compatibility
            "activeCustomers": result['customers_today']
        }
    except Exception as e:
        logger.error(f"Error getting live metrics: {e}")
        return {}

# Broadcast functions for other parts of the application

async def broadcast_order_update(order_data: dict):
    """Broadcast new order to all subscribers"""
    message = {
        "type": "order_placed",
        "data": {
            "orderId": order_data.get("order_id"),
            "orderAmount": order_data.get("total_amount"),
            "customerName": order_data.get("customer_name"),
            "productCount": order_data.get("item_count")
        },
        "timestamp": datetime.utcnow().isoformat()
    }
    await manager.broadcast(message, "order_placed")

async def broadcast_revenue_milestone(milestone_data: dict):
    """Broadcast revenue milestone achievement"""
    message = {
        "type": "alert",
        "data": {
            "alertTitle": "🎉 Revenue Milestone!",
            "alertMessage": milestone_data.get("message"),
            "alertSeverity": "success",
            "milestoneAmount": milestone_data.get("amount")
        },
        "timestamp": datetime.utcnow().isoformat()
    }
    await manager.broadcast(message, "alert")

async def broadcast_churn_alert(customer_data: dict):
    """Broadcast high churn risk alert"""
    message = {
        "type": "alert",
        "data": {
            "alertTitle": "⚠️ Churn Risk Alert",
            "alertMessage": f"{customer_data.get('count')} customers at high risk",
            "alertSeverity": "high",
            "customerIds": customer_data.get("customer_ids", [])
        },
        "timestamp": datetime.utcnow().isoformat()
    }
    await manager.broadcast(message, "alert")

# Background task to monitor for alerts
async def monitor_business_metrics():
    """Background task to monitor metrics and send alerts"""
    while True:
        try:
            # Check for revenue milestones
            revenue_check = """
            SELECT SUM(total_amount) as daily_revenue
            FROM orders 
            WHERE order_date >= CURRENT_DATE
            AND order_status IN ('confirmed', 'shipped', 'delivered')
            """
            
            result = await asyncio.get_event_loop().run_in_executor(
                None, db.execute_one, revenue_check
            )
            
            daily_revenue = float(result['daily_revenue'] or 0)
            
            # Check milestones (25k, 50k, 100k, etc.)
            milestones = [25000, 50000, 100000, 250000, 500000]
            for milestone in milestones:
                if daily_revenue >= milestone and daily_revenue < milestone * 1.1:
                    await broadcast_revenue_milestone({
                        "amount": milestone,
                        "message": f"Daily revenue exceeded €{milestone:,}!"
                    })
                    break
            
            # Check for high-risk customers
            churn_check = """
            SELECT COUNT(*) as high_risk_count
            FROM customers c
            JOIN orders o ON c.customer_id = o.customer_id
            WHERE o.order_date < CURRENT_DATE - INTERVAL '90 days'
            GROUP BY c.customer_id
            HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL '90 days'
            """
            
            # Add more monitoring logic here
            
            # Wait 60 seconds before next check
            await asyncio.sleep(60)
            
        except Exception as e:
            logger.error(f"Error in metrics monitor: {e}")
            await asyncio.sleep(60)

# API endpoints to trigger broadcasts

@router.post("/broadcast/test")
async def test_broadcast():
    """Test endpoint to trigger a broadcast"""
    test_message = {
        "type": "alert",
        "data": {
            "alertTitle": "🧪 Test Alert",
            "alertMessage": "WebSocket connection is working perfectly!",
            "alertSeverity": "info"
        },
        "timestamp": datetime.utcnow().isoformat()
    }
    
    await manager.broadcast(test_message)
    
    return {
        "status": "success",
        "message": "Test broadcast sent",
        "connected_clients": len(manager.active_connections)
    }

@router.get("/connections")
async def get_connections():
    """Get current WebSocket connections info"""
    return {
        "total_connections": len(manager.active_connections),
        "clients": list(manager.active_connections.keys()),
        "subscriptions": {
            message_type: len(subscribers) 
            for message_type, subscribers in manager.subscriptions.items()
        }
    }