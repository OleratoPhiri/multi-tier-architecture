# ===== DB SUBNET GROUP =====
resource "aws_db_subnet_group" "main" {
    name        = "multi-tier-db-subnet-group"
    subnet_ids  = [
        aws_subnet.private_1.id,
        aws_subnet.private_2.id 
    ]

    tags = {
        Name = "multi-tier-db-subnet-group"
    }
}

# ===== RDS INSTANCE =====
resource "aws_db_instance" "main" {
    identifier = "multi-tier-db"

    # Database engine
    engine          = "mysql"
    engine_version  = "8.0"
    instance_class  = "db.t3.micro"

    # Storage
    allocated_storage       = 20
    max_allocated_storage   = 100
    storage_type            = "gp2"
    storage_encrypted       = true

    # Database credentials
    db_name     = "appdb"
    username    = "admin"
    password    = var.db_password

    # Networking
    db_subnet_group_name    = aws_db_subnet_group.main.name
    vpc_security_group_ids  = [aws_security_group.rds.id]
    publicly_accessible     = false

    # High Availability - replicates to a second AZ automatically
    multi_az = true

    # Backups - retained for 7 days
    backup_retention_period = 0
    backup_window           = "03:00-04:00"
    maintenance_window      = "Mon:04:00-Mon:05:00"

    # Protection
    deletion_protection         = false
    skip_final_snapshot         = true
    delete_automated_backups    = true

    tags = {
        Name = "multi-tier-db"
    }
}