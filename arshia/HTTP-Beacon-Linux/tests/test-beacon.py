#!/usr/bin/env python3
"""
Basic test script for HTTP Beacon
Tests beacon functionality without needing C2 server running
"""

import sys
import os

# Add parent directory to path to import beacon
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from beacon import Beacon

def test_command_execution():
    """Test that command execution works"""
    print("[TEST] Testing command execution...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 30)
    
    # Test simple command
    result = beacon.execute_command("echo 'Hello World'")
    assert "Hello World" in result, "Echo command failed"
    print("✓ Echo command works")
    
    # Test command with output
    result = beacon.execute_command("whoami")
    assert len(result) > 0, "Whoami command failed"
    print(f"✓ Whoami command works: {result.strip()}")
    
    # Test command that doesn't exist
    result = beacon.execute_command("nonexistentcommand123")
    assert "ERROR" in result or "not found" in result.lower(), "Error handling failed"
    print("✓ Error handling works")
    
    print("\n[PASS] All command execution tests passed!\n")

def test_jitter():
    """Test that jitter is working"""
    print("[TEST] Testing jitter...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 60)
    
    # Generate 10 jittered intervals
    intervals = [beacon.add_jitter() for _ in range(10)]
    
    # Check they're all different
    assert len(set(intervals)) > 5, "Jitter not random enough"
    print(f"✓ Jitter working: {intervals[:5]}")
    
    # Check they're within expected range (60 ± 18)
    assert all(42 <= i <= 78 for i in intervals), "Jitter out of range"
    print("✓ Jitter within expected range")
    
    print("\n[PASS] All jitter tests passed!\n")

if __name__ == '__main__':
    print("\n" + "="*50)
    print("HTTP Beacon Test Suite")
    print("="*50 + "\n")
    
    try:
        test_command_execution()
        test_jitter()
        
        print("="*50)
        print("ALL TESTS PASSED!")
        print("="*50 + "\n")
        
    except AssertionError as e:
        print(f"\n[FAIL] Test failed: {e}\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] Unexpected error: {e}\n")
        sys.exit(1)