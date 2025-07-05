<?php
// Direct test for BACoin Packages API (no HTTP requests)
echo "<h1>Direct Test BACoin Packages API</h1>";

// Include required files
require_once 'config/db_connect.php';
require_once 'utils/response.php';

// Test 1: Get all packages directly
echo "<h2>Test 1: Get all packages directly from database</h2>";
try {
    $stmt = $conn->prepare("SELECT * FROM bacoin_packages ORDER BY price_vnd ASC");
    $stmt->execute();
    $result = $stmt->get_result();
    $packages = [];
    while ($row = $result->fetch_assoc()) {
        $packages[] = $row;
    }
    
    echo "<pre>Packages found: " . count($packages) . "</pre>";
    echo "<pre>" . json_encode($packages, JSON_PRETTY_PRINT) . "</pre>";
} catch (Exception $e) {
    echo "<pre>Error: " . $e->getMessage() . "</pre>";
}

// Test 2: Add new package directly
echo "<h2>Test 2: Add new package directly to database</h2>";
try {
    $package_name = 'Gói Test Direct 150K';
    $price_vnd = 150000;
    $bacoin_amount = 180000;
    $description = 'Gói test trực tiếp';
    
    // Check if package exists
    $stmt = $conn->prepare("SELECT id FROM bacoin_packages WHERE package_name = ?");
    $stmt->bind_param("s", $package_name);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->fetch_assoc()) {
        echo "<pre>Package already exists</pre>";
    } else {
        // Add new package
        $stmt = $conn->prepare("INSERT INTO bacoin_packages (package_name, price_vnd, bacoin_amount, description) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("sdds", $package_name, $price_vnd, $bacoin_amount, $description);
        $stmt->execute();
        
        $package_id = $conn->insert_id;
        echo "<pre>Package added successfully with ID: " . $package_id . "</pre>";
        
        // Get the added package
        $stmt = $conn->prepare("SELECT * FROM bacoin_packages WHERE id = ?");
        $stmt->bind_param("i", $package_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $new_package = $result->fetch_assoc();
        
        echo "<pre>New package: " . json_encode($new_package, JSON_PRETTY_PRINT) . "</pre>";
    }
} catch (Exception $e) {
    echo "<pre>Error: " . $e->getMessage() . "</pre>";
}

// Test 3: Update package directly
echo "<h2>Test 3: Update package directly in database</h2>";
try {
    $id = 1; // Update first package
    $new_name = 'Gói 50K Updated Direct';
    $new_price = 55000;
    $new_bacoin = 65000;
    $new_description = 'Gói 50K đã được cập nhật trực tiếp';
    
    // Check if package exists
    $stmt = $conn->prepare("SELECT id FROM bacoin_packages WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    if (!$result->fetch_assoc()) {
        echo "<pre>Package not found</pre>";
    } else {
        // Update package
        $stmt = $conn->prepare("UPDATE bacoin_packages SET package_name = ?, price_vnd = ?, bacoin_amount = ?, description = ? WHERE id = ?");
        $stmt->bind_param("sddsi", $new_name, $new_price, $new_bacoin, $new_description, $id);
        $stmt->execute();
        
        echo "<pre>Package updated successfully</pre>";
        
        // Get the updated package
        $stmt = $conn->prepare("SELECT * FROM bacoin_packages WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $updated_package = $result->fetch_assoc();
        
        echo "<pre>Updated package: " . json_encode($updated_package, JSON_PRETTY_PRINT) . "</pre>";
    }
} catch (Exception $e) {
    echo "<pre>Error: " . $e->getMessage() . "</pre>";
}

// Test 4: Delete package directly
echo "<h2>Test 4: Delete package directly from database</h2>";
try {
    $id = 6; // Delete the test package we added
    
    // Check if package exists
    $stmt = $conn->prepare("SELECT id FROM bacoin_packages WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    if (!$result->fetch_assoc()) {
        echo "<pre>Package not found for deletion</pre>";
    } else {
        // Delete package
        $stmt = $conn->prepare("DELETE FROM bacoin_packages WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        
        echo "<pre>Package deleted successfully</pre>";
    }
} catch (Exception $e) {
    echo "<pre>Error: " . $e->getMessage() . "</pre>";
}

echo "<h2>Final Database State</h2>";
try {
    $stmt = $conn->prepare("SELECT * FROM bacoin_packages ORDER BY price_vnd ASC");
    $stmt->execute();
    $result = $stmt->get_result();
    
    echo "<table border='1'>";
    echo "<tr><th>ID</th><th>Package Name</th><th>Price VND</th><th>BACoin Amount</th><th>Description</th></tr>";
    while ($package = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $package['id'] . "</td>";
        echo "<td>" . $package['package_name'] . "</td>";
        echo "<td>" . $package['price_vnd'] . "</td>";
        echo "<td>" . $package['bacoin_amount'] . "</td>";
        echo "<td>" . ($package['description'] ?? '') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} catch (Exception $e) {
    echo "Database error: " . $e->getMessage();
}
?> 