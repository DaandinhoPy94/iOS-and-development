"""
AI Analytics API
Professional REST API for iOS and web applications
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime
from contextlib import asynccontextmanager
import logging

from app.config import settings
from app.routes import dashboard, customers, products, analytics
from app.routes import websocket

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Starting AI Analytics API...")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"API Version: {settings.API_VERSION}")
    
    # Test database connection
    try:
        conn = psycopg2.connect(settings.DATABASE_URL)
        conn.close()
        logger.info("✅ Database connection successful")
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
    
    yield
    
    # Shutdown
    logger.info("👋 Shutting down AI Analytics API...")

# Create FastAPI app
app = FastAPI(
    title="AI Analytics API",
    description="Professional REST API for AI-powered e-commerce analytics",
    version=settings.API_VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your iOS app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoint
@app.get("/")
async def root():
    """Welcome endpoint with API information"""
    return {
        "message": "Welcome to AI Analytics API",
        "version": settings.API_VERSION,
        "status": "operational",
        "timestamp": datetime.utcnow().isoformat(),
        "endpoints": {
            "dashboard": "/api/v1/dashboard",
            "customers": "/api/v1/customers",
            "products": "/api/v1/products",
            "analytics": "/api/v1/analytics",
            "health": "/health",
            "docs": "/docs"
        }
    }

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": settings.API_VERSION,
        "environment": settings.ENVIRONMENT
    }
    
    # Check database connection
    try:
        conn = psycopg2.connect(settings.DATABASE_URL)
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        conn.close()
        health_status["database"] = "connected"
    except Exception as e:
        health_status["status"] = "unhealthy"
        health_status["database"] = f"error: {str(e)}"
        return JSONResponse(status_code=503, content=health_status)
    
    return health_status

# Include routers
app.include_router(
    dashboard.router,
    prefix="/api/v1/dashboard",
    tags=["Dashboard"]
)

app.include_router(
    customers.router,
    prefix="/api/v1/customers",
    tags=["Customers"]
)

app.include_router(
    products.router,
    prefix="/api/v1/products",
    tags=["Products"]
)

app.include_router(
    analytics.router,
    prefix="/api/v1/analytics",
    tags=["Analytics"]
)

app.include_router(
    websocket.router,
    prefix="",  # No prefix - WebSocket op root level
    tags=["WebSocket"]
)

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": str(exc) if settings.DEBUG else "An error occurred",
            "timestamp": datetime.utcnow().isoformat()
        }
    )

# 404 handler
@app.exception_handler(404)
async def not_found_handler(request, exc):
    return JSONResponse(
        status_code=404,
        content={
            "error": "Not found",
            "message": "The requested resource was not found",
            "timestamp": datetime.utcnow().isoformat()
        }
    )