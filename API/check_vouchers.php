<?php
require_once 'config/db_connect.php';

echo "=== VOUCHER STATUS ===\n";

$query = "SELECT * FROM vouchers ORDER BY id DESC LIMIT 5";
$result = mysqli_query($conn, $query);

while($row = mysqli_fetch_assoc($result)) {
    echo "ID: " . $row['id'] . "\n";
    echo "Code: " . $row['voucher_code'] . "\n";
    echo "Start: " . $row['start_date'] . "\n";
    echo "End: " . $row['end_date'] . "\n";
    echo "Quantity: " . $row['quantity'] . "\n";
    echo "---\n";
}

// Check current time
echo "Current time: " . date('Y-m-d H:i:s') . "\n";

mysqli_close($conn);
?> 