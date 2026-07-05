### 📜 Automated Bootstrapping via EC2 User Data

To achieve complete hand-off automation during instances initialization, an advanced **Bash User Data Script** was integrated into the Launch Template. This script runs implicitly with root privileges upon instance startup, provisioning the core runtime engine, installing application logic, and configuring database abstraction.

#### 🛠️ Automation Workflow Breakdown:
1. **System & Security Patching:** Executes an absolute yum update cycle to patch underlying Linux kernel vulnerabilities.
2. **Runtime Engine Provisioning:** Automates downstream compilation for Apache (`httpd`), PHP runtime engines, and the MySQLi abstract communication library components (`php-mysqli`).
3. **Storage Permissive Hardening:** Overrides default `/var/www/html/` permission hierarchies using sticky bit modifications (`2775`) and systemic ownership shifts (`ec2-user:apache`).
4. **Dynamic Application Deployment:** Injects an optimized **PHP To-Do Task Application Dashboard** directly into runtime web storage spaces, complete with relational schema creation routines (`demo_db.tasks`).

---

### 💻 Infrastructure-As-Code User Data Script

```bash
#!/bin/bash
# 1. System Synchronization and Package Verification
sudo yum update -y
sudo yum install -y httpd php php-mysqli git

# 2. Daemon Lifecycle Management
sudo systemctl start httpd
sudo systemctl enable httpd

# 3. Storage Hierarchy Permission Hardening
sudo chown -R ec2-user:apache /var/www/html
sudo chmod 2775 /var/www/html

# 4. Ingress Environment Database Configuration String Injection
cat << 'EOF' > /var/www/html/config.php
<?php
define('DB_SERVER', 'YOUR_RDS_ENDPOINT_HERE');      // Amazon RDS Private Endpoint URL
define('DB_USERNAME', 'YOUR_MASTER_USERNAME');      // Hardened Master Database Operator Username
define('DB_PASSWORD', 'YOUR_MASTER_PASSWORD');      // Vaulted Database Access Secret Key   

$link = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD);
if($link === false){ die("ERROR: Could not connect. " . mysqli_connect_error()); }

// Structural Schema Initialization Engine
mysqli_query($link, "CREATE DATABASE IF NOT EXISTS demo_db");
mysqli_select_db($link, "demo_db");
?>
EOF

# 5. Ingress Dynamic Frontend Interface Injection
cat << 'EOF' > /var/www/html/index.php
<?php
require_once "config.php";
$title = ""; $title_err = "";
if($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['add_task'])){
    $input_title = trim($_POST["title"]);
    if(empty($input_title)){ $title_err = "Please enter a task."; } else { $title = $input_title; }
    if(empty($title_err)){
        $sql = "INSERT INTO tasks (title) VALUES (?)";
        if($stmt = mysqli_prepare($link, $sql)){
            mysqli_stmt_bind_param($stmt, "s", $param_title);
            $param_title = $title;
            if(mysqli_stmt_execute($stmt)){ header("location: index.php"); exit(); }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>AWS Two-Tier Demo App</title>
    <link rel="stylesheet" href="[https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css](https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css)">
    <style> body { font: 14px sans-serif; background-color: #f8f9fa; } .wrapper { width: 600px; margin: 50px auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); } </style>
</head>
<body>
    <div class="wrapper">
        <div class="text-center mb-4">
            <h2 class="text-primary">AWS Two-Tier Architecture Demo</h2>
            <p class="text-muted">Connected to Backend Amazon RDS Instance</p>
            <span class="badge badge-info">Served by EC2 Instance IP: <?php echo $_SERVER['SERVER_ADDR']; ?></span>
        </div>
        <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="post" class="mb-4">
            <div class="input-group">
                <input type="text" name="title" class="form-control <?php echo (!empty($title_err)) ? 'is-invalid' : ''; ?>" value="<?php echo $title; ?>" placeholder="Enter a new task items...">
                <div class="input-group-append"><input type="submit" name="add_task" class="btn btn-success" value="Add to DB"></div>
                <span class="invalid-feedback"><?php echo $title_err;?></span>
            </div>
        </form>
        <h4>Stored Tasks:</h4>
        <?php
        mysqli_query($link, "CREATE TABLE IF NOT EXISTS tasks (id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(255) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
        $sql = "SELECT * FROM tasks ORDER BY created_at DESC";
        if($result = mysqli_query($link, $sql)){
            if(mysqli_num_rows($result) > 0){
                echo '<ul class="list-group">';
                while($row = mysqli_fetch_array($result)){
                    echo '<li class="list-group-item d-flex justify-content-between align-items-center">' . htmlspecialchars($row['title']) . '<small class="text-muted">' . $row['created_at'] . '</small></li>';
                }
                echo '</ul>';
                mysqli_free_result($result);
            } else { echo '<div class="alert alert-warning">No tasks found in the database.</div>'; }
        }
        mysqli_close($link);
        ?>
    </div>
</body>
</html>
EOF

# 6. Web Engine File Permissions Initialization Restructure
sudo chown -R apache:apache /var/www/html/