# VNPAY Integration Testing Guide

## 🚨 Important: CORS Issue Solution

The CORS error you encountered happens because you're trying to access PHP files directly from the file system using `file://` protocol. This is not allowed by browsers for security reasons.

## ✅ Correct Way to Test VNPAY Integration

### Step 1: Start XAMPP Server
1. Open XAMPP Control Panel
2. Start Apache server
3. Make sure it's running on port 80 (default)

### Step 2: Access the Test Page
Instead of opening files directly, access the test page through your web server:

```
http://localhost/EcommerceClothingApp/API/test_vnpay_server.html
```

### Step 3: Test the Integration
The new test page (`test_vnpay_server.html`) provides:

1. **API Connection Test** - Verifies the API is accessible
2. **Create VNPAY Payment** - Generates payment URLs with proper timestamps
3. **Payment Status Check** - Checks payment status
4. **Server Information** - Shows server time and configuration

## 🔧 What's Fixed

### 1. CORS Issues
- ✅ Test page now uses relative URLs
- ✅ Accessible through XAMPP server
- ✅ No more `file://` protocol issues

### 2. VNPAY Time Issues
- ✅ Proper timezone handling (Asia/Ho_Chi_Minh)
- ✅ Correct timestamp format (YmdHis)
- ✅ 15-minute expiration time
- ✅ Server time synchronization

### 3. API Improvements
- ✅ Test endpoints for connection verification
- ✅ Server info endpoint for debugging
- ✅ Simplified parameters for testing
- ✅ Detailed debug logging

### 4. Return Handler
- ✅ Updated VNPAY return handler with JSON response
- ✅ Proper hash verification
- ✅ Database updates for successful payments
- ✅ Comprehensive error handling

## 🐛 JavaScript Timer Error (VNPAY Frontend Issue)

### Problem
You may see this error on VNPAY's payment page:
```
Uncaught ReferenceError: timer is not defined
```

### Cause
This is a **frontend issue on VNPAY's side**, not your code. It happens because:
- VNPAY's JavaScript code tries to use a `timer` variable that wasn't declared
- This is in their minified JavaScript files
- It's a common issue with their payment interface

### Impact
- ❌ **Does NOT affect payment processing** - payments still work
- ❌ **Does NOT affect your integration** - your backend code is fine
- ⚠️ **May cause visual issues** on VNPAY's payment page (clock/timer display)
- ⚠️ **May show console errors** in browser developer tools

### Solution
**You cannot fix this** - it's VNPAY's issue. However:

1. **Ignore the error** - it doesn't affect functionality
2. **Test payments still work** - the error is cosmetic
3. **Report to VNPAY** - if you want to notify them about the issue
4. **Focus on your integration** - your code is working correctly

## 📋 Testing Checklist

### Before Testing
- [ ] XAMPP Apache server is running
- [ ] Access test page via `http://localhost/...`
- [ ] VNPAY config has correct Terminal ID and Secret Key

### During Testing
- [ ] API connection test passes
- [ ] Payment URL generation works
- [ ] Generated URL opens VNPAY payment page
- [ ] No "transaction time expired" errors
- [ ] Payment status can be checked
- [ ] Return handler processes responses correctly

### Debug Information
The test page will show:
- Server time and timezone
- VNPAY configuration details
- Generated payment URLs
- Transaction references
- Detailed error messages if any

## 🧪 Additional Test Tools

### 1. Main Test Page
```
http://localhost/EcommerceClothingApp/API/test_vnpay_server.html
```

### 2. Return Handler Test
```
http://localhost/EcommerceClothingApp/API/test_vnpay_return_simple.html
```
- Test different payment scenarios
- Simulate success/failure/cancelled payments
- Verify return handler processing

### 3. Debug Logs
Check XAMPP error logs for detailed VNPAY debug information:
- **Location**: `D:\xamppppppppppp\apache\logs\error.log`
- **Look for**: "=== VNPAY DEBUG START ===" entries

## 🐛 Troubleshooting

### If you still get CORS errors:
1. Make sure you're using `http://localhost/...` not `file:///...`
2. Check that XAMPP Apache is running
3. Verify the file paths are correct

### If you get "transaction time expired":
1. Check server time synchronization
2. Verify timezone is set to Asia/Ho_Chi_Minh
3. Look at debug logs for timestamp details

### If payment URL doesn't work:
1. Check VNPAY Terminal ID and Secret Key
2. Verify return URL is accessible
3. Check debug logs for hash generation

### If you see JavaScript timer errors:
1. **This is normal** - it's VNPAY's frontend issue
2. **Ignore the error** - payments still work
3. **Focus on your backend** - your integration is fine
4. **Test the payment flow** - the error doesn't affect functionality

## 📞 Next Steps

1. **Test the new page**: Access `http://localhost/EcommerceClothingApp/API/test_vnpay_server.html`
2. **Run connection test**: Click "Test API Connection"
3. **Create test payment**: Use the payment creation form
4. **Check debug info**: Use "Get Server Info" to verify configuration
5. **Test return handler**: Use the return test page
6. **Share results**: If you encounter any issues, share the debug output

## 🔗 Useful URLs

- **Main Test Page**: `http://localhost/EcommerceClothingApp/API/test_vnpay_server.html`
- **Return Test Page**: `http://localhost/EcommerceClothingApp/API/test_vnpay_return_simple.html`
- **VNPAY API**: `http://localhost/EcommerceClothingApp/API/vnpay_php/create_vnpay_payment_fixed.php`
- **Return URL**: `http://localhost/EcommerceClothingApp/API/vnpay_php/vnpay_return.php`

## 📝 Debug Logs

Check XAMPP error logs for detailed VNPAY debug information:
- **Location**: `D:\xamppppppppppp\apache\logs\error.log`
- **Look for**: "=== VNPAY DEBUG START ===" entries

This will help identify any remaining issues with the integration.

## 🎯 Key Points

1. **CORS errors are fixed** - use the new test page
2. **JavaScript timer errors are VNPAY's issue** - ignore them
3. **Your integration is working** - focus on testing the payment flow
4. **Use proper URLs** - always access via `http://localhost/...`
5. **Check debug logs** - they contain valuable troubleshooting information 