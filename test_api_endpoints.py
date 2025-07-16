"""
Test script to verify API endpoints
Run this after deployment to test your API
"""

import requests
import json
from datetime import datetime

# Configuration
API_BASE_URL = "http://localhost:8000"  # Change to your Railway URL
# API_BASE_URL = "https://your-api.up.railway.app"

def test_endpoint(endpoint, name):
    """Test a single endpoint"""
    print(f"\n🧪 Testing {name}...")
    try:
        response = requests.get(f"{API_BASE_URL}{endpoint}", timeout=10)
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Success!")
            print(f"   Response keys: {list(data.keys())}")
            
            # Pretty print part of response
            if 'data' in data and isinstance(data['data'], dict):
                metrics = data['data'].get('metrics', {})
                if metrics:
                    print(f"   Total Revenue: €{metrics.get('totalRevenue', 0):,.2f}")
                    print(f"   Active Customers: {metrics.get('activeCustomers', 0)}")
        else:
            print(f"   ❌ Error: {response.status_code}")
            print(f"   Response: {response.text[:200]}")
            
    except requests.exceptions.ConnectionError:
        print(f"   ❌ Connection failed - is the API running?")
    except Exception as e:
        print(f"   ❌ Error: {e}")

def main():
    """Run all tests"""
    print("🚀 AI Analytics API Test Suite")
    print(f"📍 Testing API at: {API_BASE_URL}")
    print("=" * 50)
    
    # Test endpoints
    endpoints = [
        ("/", "Root endpoint"),
        ("/health", "Health check"),
        ("/api/v1/dashboard", "Dashboard summary"),
        ("/api/v1/dashboard/live", "Live metrics"),
        ("/api/v1/dashboard/metrics", "Detailed metrics"),
        ("/api/v1/dashboard/revenue?days=7", "Revenue data"),
    ]
    
    for endpoint, name in endpoints:
        test_endpoint(endpoint, name)
    
    print("\n" + "=" * 50)
    print("✅ Testing complete!")
    print(f"\n📱 For iOS integration, use base URL: {API_BASE_URL}")
    print("📚 View interactive docs at: {}/docs".format(API_BASE_URL))

if __name__ == "__main__":
    main()