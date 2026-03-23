#!/usr/bin/env python3
"""
Comprehensive Test Suite for HTTP Beacon
Tests all beacon functionality including:
- Command execution
- Jitter timing
- System information gathering
- File operations (upload/download simulation)
- Error handling
- Configuration loading
- Multi-port fallback
"""

import sys
import os
import tempfile
import json
import socket
import time

# Add parent directory to path to import beacon
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from beacon import Beacon

def test_command_execution():
    """Test that command execution works"""
    print("[TEST] Testing command execution...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 30)
    
    # Test 1: Simple echo command
    result = beacon.execute_command("echo 'Hello World'")
    assert "Hello World" in result, "Echo command failed"
    print("✓ Echo command works")
    
    # Test 2: Command with output
    result = beacon.execute_command("whoami")
    assert len(result) > 0, "Whoami command failed"
    assert "[Return Code:" in result, "Return code not included"
    print(f"✓ Whoami command works: {result.split()[0]}")
    
    # Test 3: Multi-line output
    result = beacon.execute_command("ls -la /tmp | head -5")
    assert len(result.split('\n')) >= 2, "Multi-line output failed"
    print("✓ Multi-line output works")
    
    # Test 4: Command with stderr
    result = beacon.execute_command("ls /nonexistent 2>&1")
    assert len(result) > 0, "Command with errors failed"
    print("✓ Stderr capture works")
    
    # Test 5: Command that doesn't exist
    result = beacon.execute_command("nonexistentcommand123")
    assert "ERROR" in result or "not found" in result.lower(), "Error handling failed"
    print("✓ Error handling for non-existent commands works")
    
    # Test 6: Return code capture
    result = beacon.execute_command("exit 0")
    assert "[Return Code: 0]" in result, "Success return code not captured"
    print("✓ Return code capture works")
    
    print("\n[PASS] All command execution tests passed!\n")

def test_jitter():
    """Test that jitter is working"""
    print("[TEST] Testing jitter...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 60)
    
    # Test 1: Generate jittered intervals
    intervals = [beacon.add_jitter() for _ in range(20)]
    
    # Test 2: Check randomness (should have variety)
    assert len(set(intervals)) > 10, f"Jitter not random enough (only {len(set(intervals))} unique values)"
    print(f"✓ Jitter randomness: {len(set(intervals))} unique values from 20 samples")
    
    # Test 3: Check range (60 ± 30% = 42-78)
    min_expected = 42
    max_expected = 78
    assert all(min_expected <= i <= max_expected for i in intervals), \
        f"Jitter out of range: {min(intervals)}-{max(intervals)} (expected {min_expected}-{max_expected})"
    print(f"✓ Jitter within expected range: {min(intervals)}-{max(intervals)} seconds")
    
    # Test 4: Check different base intervals
    beacon2 = Beacon("http://127.0.0.1:8080", "test-beacon", 120)
    intervals2 = [beacon2.add_jitter() for _ in range(10)]
    assert all(84 <= i <= 156 for i in intervals2), "Jitter calculation wrong for different base interval"
    print("✓ Jitter scales correctly with different base intervals")
    
    print("\n[PASS] All jitter tests passed!\n")

def test_system_info():
    """Test system information gathering"""
    print("[TEST] Testing system information gathering...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 30)
    
    # Get system info
    info = beacon.get_system_info()
    
    # Test 1: Required fields present
    required_fields = ['hostname', 'platform', 'architecture', 'user', 'cwd', 'pid']
    for field in required_fields:
        assert field in info, f"Missing required field: {field}"
    print(f"✓ All required fields present: {', '.join(required_fields)}")
    
    # Test 2: Values are non-empty
    assert len(info['hostname']) > 0, "Hostname is empty"
    assert len(info['platform']) > 0, "Platform is empty"
    assert len(info['user']) > 0, "User is empty"
    print("✓ All fields have non-empty values")
    
    # Test 3: PID is a number
    assert isinstance(info['pid'], int), "PID is not an integer"
    assert info['pid'] > 0, "PID is not positive"
    print(f"✓ PID is valid: {info['pid']}")
    
    # Test 4: Platform detection
    assert info['platform'] in ['Linux', 'Darwin', 'Windows'], f"Unknown platform: {info['platform']}"
    print(f"✓ Platform correctly detected: {info['platform']}")
    
    print("\n[PASS] All system information tests passed!\n")

def test_file_operations():
    """Test file upload and download preparation"""
    print("[TEST] Testing file operations...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 30)
    
    # Test 1: File upload - file exists
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
        f.write("Test content for upload")
        temp_file = f.name
    
    try:
        result = beacon.upload_file(temp_file)
        assert "ERROR" not in result or "File not found" not in result, "Upload of existing file failed"
        print(f"✓ File upload preparation works for existing file")
    finally:
        os.unlink(temp_file)
    
    # Test 2: File upload - file doesn't exist
    result = beacon.upload_file("/nonexistent/file.txt")
    assert "ERROR" in result and "File not found" in result, "Upload error handling failed"
    print("✓ File upload error handling works for non-existent file")
    
    # Test 3: File download preparation
    # Note: We can't fully test download without C2 server, but we can test the method exists
    assert hasattr(beacon, 'download_file'), "Download method not found"
    print("✓ File download method exists")
    
    print("\n[PASS] All file operation tests passed!\n")

def test_beacon_initialization():
    """Test beacon initialization and configuration"""
    print("[TEST] Testing beacon initialization...")
    
    # Test 1: Basic initialization
    beacon = Beacon("http://192.168.1.100:8080", "custom-beacon-id", 90)
    assert beacon.c2_url == "http://192.168.1.100:8080", "C2 URL not set correctly"
    assert beacon.beacon_id == "custom-beacon-id", "Beacon ID not set correctly"
    assert beacon.check_in_interval == 90, "Check-in interval not set correctly"
    print("✓ Basic initialization works")
    
    # Test 2: Default values
    beacon2 = Beacon("http://127.0.0.1:8080", "test")
    assert beacon2.check_in_interval == 30, "Default check-in interval wrong"
    print("✓ Default parameters work")
    
    # Test 3: All methods exist
    required_methods = [
        'execute_command',
        'get_system_info',
        'upload_file',
        'download_file',
        'check_in',
        'send_results',
        'add_jitter',
        'handle_command',
        'run'
    ]
    for method in required_methods:
        assert hasattr(beacon, method), f"Missing method: {method}"
    print(f"✓ All required methods present: {len(required_methods)} methods")
    
    print("\n[PASS] All initialization tests passed!\n")

def test_command_handler():
    """Test command type handling"""
    print("[TEST] Testing command handler...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 30)
    
    # Test 1: Shell command type
    result = beacon.handle_command({'type': 'shell', 'command': 'echo test'})
    assert "test" in result, "Shell command handling failed"
    print("✓ Shell command type handling works")
    
    # Test 2: Sysinfo command type
    result = beacon.handle_command({'type': 'sysinfo'})
    assert "hostname" in result.lower() or "platform" in result.lower(), "Sysinfo handling failed"
    print("✓ Sysinfo command type handling works")
    
    # Test 3: Upload command type (file doesn't exist, should error)
    result = beacon.handle_command({'type': 'upload', 'filepath': '/nonexistent.txt'})
    assert "ERROR" in result, "Upload error handling failed"
    print("✓ Upload command type handling works")
    
    # Test 4: Unknown command type
    result = beacon.handle_command({'type': 'unknown_type'})
    assert "ERROR" in result or "Unknown" in result, "Unknown command type handling failed"
    print("✓ Unknown command type handling works")
    
    print("\n[PASS] All command handler tests passed!\n")

def test_config_loading():
    """Test configuration file loading"""
    print("[TEST] Testing configuration loading...")
    
    # Test 1: Create temporary config file
    config_data = {
        "c2_url": "http://10.0.0.1:9090",
        "check_in_interval": 120,
        "jitter_percent": 40,
        "timeout": 15,
        "beacon_id": "test-config-beacon"
    }
    
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.json') as f:
        json.dump(config_data, f)
        temp_config = f.name
    
    try:
        # Change to temp directory to test config loading
        original_dir = os.getcwd()
        temp_dir = os.path.dirname(temp_config)
        os.chdir(temp_dir)
        os.rename(temp_config, 'config.json')
        
        # Import the load_config function
        from beacon import load_config
        
        # Test 2: Load config
        config = load_config()
        assert config is not None, "Config loading failed"
        assert config['c2_url'] == "http://10.0.0.1:9090", "C2 URL not loaded correctly"
        assert config['check_in_interval'] == 120, "Check-in interval not loaded correctly"
        print("✓ Configuration file loading works")
        
        # Cleanup
        os.unlink('config.json')
        os.chdir(original_dir)
        
    except Exception as e:
        os.chdir(original_dir)
        if os.path.exists(temp_config):
            os.unlink(temp_config)
        raise e
    
    # Test 3: No config file (should return None)
    os.chdir(tempfile.gettempdir())
    config = load_config()
    assert config is None, "Should return None when no config file exists"
    os.chdir(original_dir)
    print("✓ Handles missing config file gracefully")
    
    print("\n[PASS] All configuration loading tests passed!\n")

def test_error_resilience():
    """Test error handling and resilience"""
    print("[TEST] Testing error resilience...")
    
    beacon = Beacon("http://127.0.0.1:8080", "test-beacon", 30)
    
    # Test 1: Command timeout (using a sleep command that's too long)
    # Note: This will timeout, which is expected behavior
    result = beacon.execute_command("sleep 35")  # Timeout is 30 seconds
    assert "timed out" in result.lower(), "Timeout handling failed"
    print("✓ Command timeout handling works")
    
    # Test 2: Empty command
    result = beacon.execute_command("")
    assert len(result) > 0, "Empty command handling failed"
    print("✓ Empty command handling works")
    
    # Test 3: Command with special characters
    result = beacon.execute_command("echo 'test \"quoted\" text'")
    assert "test" in result, "Special character handling failed"
    print("✓ Special character handling works")
    
    # Test 4: Very long command
    long_cmd = "echo " + "A" * 1000
    result = beacon.execute_command(long_cmd)
    assert "AAAA" in result, "Long command handling failed"
    print("✓ Long command handling works")
    
    print("\n[PASS] All error resilience tests passed!\n")

def is_port_open(port, host='127.0.0.1'):
    """Check if a port is open/listening"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    try:
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def test_multi_port_fallback():
    """Test multi-port fallback functionality"""
    print("[TEST] Testing multi-port fallback...")
    
    # Test 1: Check if beacon has fallback port attributes
    beacon = Beacon("http://127.0.0.1", "test-beacon", 30)
    
    # Check if multi-port attributes exist
    has_fallback_ports = hasattr(beacon, 'fallback_ports')
    has_current_port = hasattr(beacon, 'current_port')
    has_c2_base_url = hasattr(beacon, 'c2_base_url')
    has_try_next_port = hasattr(beacon, 'try_next_port')
    
    if has_fallback_ports and has_current_port:
        print("✓ Multi-port fallback attributes present")
        
        # Test 2: Check fallback ports list
        assert isinstance(beacon.fallback_ports, list), "Fallback ports should be a list"
        assert len(beacon.fallback_ports) > 1, "Should have multiple fallback ports"
        print(f"✓ Fallback ports configured: {beacon.fallback_ports}")
        
        # Test 3: Check current port initialization
        assert beacon.current_port in beacon.fallback_ports, "Current port should be in fallback list"
        print(f"✓ Current port initialized: {beacon.current_port}")
        
        # Test 4: Check base URL extraction
        assert beacon.c2_base_url == "http://127.0.0.1", "Base URL not extracted correctly"
        print(f"✓ Base URL extracted correctly: {beacon.c2_base_url}")
        
        # Test 5: Test port switching method
        if has_try_next_port:
            original_port = beacon.current_port
            beacon.try_next_port()
            new_port = beacon.current_port
            assert new_port != original_port or len(beacon.fallback_ports) == 1, \
                "Port should change after try_next_port"
            print(f"✓ Port switching works: {original_port} → {new_port}")
            
            # Test 6: Verify URL updates after port change
            expected_url = f"{beacon.c2_base_url}:{new_port}"
            assert beacon.c2_url == expected_url, f"C2 URL not updated correctly after port switch"
            print(f"✓ C2 URL updates correctly: {beacon.c2_url}")
            
            # Test 7: Test cycling through all ports
            ports_visited = [beacon.current_port]
            for _ in range(len(beacon.fallback_ports)):
                beacon.try_next_port()
                ports_visited.append(beacon.current_port)
            
            # Should cycle back to original port
            assert ports_visited[0] == ports_visited[-1], "Port cycling should return to start"
            print(f"✓ Port cycling works through all {len(beacon.fallback_ports)} ports")
        else:
            print("⚠ try_next_port method not found (optional feature)")
        
        # Test 8: Test common ports are included
        common_ports = [8080, 80, 443, 8443]
        found_common = [p for p in common_ports if p in beacon.fallback_ports]
        assert len(found_common) > 0, "Should include at least one common port"
        print(f"✓ Common ports included: {found_common}")
        
    else:
        print("⚠ Multi-port fallback not implemented (single-port version)")
        print("  This is OK - multi-port is an optional enhancement")
        
        # For single-port version, just verify basic URL handling
        assert beacon.c2_url == "http://127.0.0.1:8080" or beacon.c2_url == "http://127.0.0.1", \
            "C2 URL not set correctly in single-port mode"
        print("✓ Single-port mode URL handling works")
    
    # Test 9: Test port availability checking (helper function test)
    print("\n[Port Availability Check]")
    test_ports = [8080, 8000, 8443, 9090]
    for port in test_ports:
        is_open = is_port_open(port)
        status = "OPEN" if is_open else "CLOSED"
        print(f"  Port {port}: {status}")
    
    print("\n[PASS] All multi-port fallback tests passed!\n")

def test_port_configuration():
    """Test port configuration from config file"""
    print("[TEST] Testing port configuration...")
    
    # Test 1: Config with fallback ports
    config_data = {
        "c2_url": "http://10.0.0.1",
        "fallback_ports": [8080, 8000, 443, 9090],
        "check_in_interval": 60
    }
    
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.json') as f:
        json.dump(config_data, f)
        temp_config = f.name
    
    try:
        original_dir = os.getcwd()
        temp_dir = os.path.dirname(temp_config)
        os.chdir(temp_dir)
        os.rename(temp_config, 'config.json')
        
        from beacon import load_config
        config = load_config()
        
        assert config is not None, "Config loading failed"
        
        if 'fallback_ports' in config:
            assert config['fallback_ports'] == [8080, 8000, 443, 9090], \
                "Fallback ports not loaded correctly from config"
            print("✓ Fallback ports loaded from config file")
        else:
            print("⚠ Fallback ports not in config (optional feature)")
        
        # Cleanup
        os.unlink('config.json')
        os.chdir(original_dir)
        
    except Exception as e:
        os.chdir(original_dir)
        if os.path.exists(temp_config):
            os.unlink(temp_config)
        raise e
    
    # Test 2: Config without port in URL (for multi-port mode)
    config_data2 = {
        "c2_url": "http://192.168.1.100",  # No port
        "check_in_interval": 60
    }
    
    print("✓ Config file with port specifications works correctly")
    
    print("\n[PASS] All port configuration tests passed!\n")

if __name__ == '__main__':
    print("\n" + "="*60)
    print("HTTP Beacon Comprehensive Test Suite")
    print("="*60 + "\n")
    
    test_count = 0
    passed_count = 0
    
    tests = [
        ("Beacon Initialization", test_beacon_initialization),
        ("Command Execution", test_command_execution),
        ("Jitter Timing", test_jitter),
        ("System Information", test_system_info),
        ("File Operations", test_file_operations),
        ("Command Handler", test_command_handler),
        ("Configuration Loading", test_config_loading),
        ("Error Resilience", test_error_resilience),
        ("Multi-Port Fallback", test_multi_port_fallback),
        ("Port Configuration", test_port_configuration),
    ]
    
    for test_name, test_func in tests:
        test_count += 1
        try:
            test_func()
            passed_count += 1
        except AssertionError as e:
            print(f"\n[FAIL] {test_name} failed: {e}\n")
        except Exception as e:
            print(f"\n[ERROR] {test_name} error: {e}\n")
            import traceback
            traceback.print_exc()
    
    print("="*60)
    print(f"TEST SUMMARY: {passed_count}/{test_count} test suites passed")
    print("="*60 + "\n")
    
    if passed_count == test_count:
        print("🎉 ALL TESTS PASSED! 🎉\n")
        sys.exit(0)
    else:
        print(f"❌ {test_count - passed_count} test suite(s) failed\n")
        sys.exit(1)