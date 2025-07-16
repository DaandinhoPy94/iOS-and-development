#!/usr/bin/env python
"""
Development server runner
Makes it easy to start the API locally
"""

import uvicorn
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

if __name__ == "__main__":
    # Get port from environment or default
    port = int(os.getenv("PORT", 8000))
    
    # Development settings
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        reload=True,  # Auto-reload on code changes
        log_level="info",
        access_log=True
    )