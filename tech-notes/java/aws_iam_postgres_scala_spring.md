
# AWS IAM Authentication for Postgres in Scala 3.7.3 + Spring Boot 3.5.6 (Minimal Guide)

This document explains the minimal code and infrastructure changes required to switch a Spring Boot (3.5.6) + Spring Data JDBC application written in Scala 3.7.3 to use **AWS IAM authentication** for PostgreSQL (RDS/Aurora).

---

## 1. Application Changes

### build.sbt
```scala
ThisBuild / scalaVersion := "3.7.3"

libraryDependencies ++= Seq(
  // Spring Boot + Data JDBC
  "org.springframework.boot" % "spring-boot-starter" % "3.5.6",
  "org.springframework.boot" % "spring-boot-starter-data-jdbc" % "3.5.6",
  "org.springframework.boot" % "spring-boot-starter-jdbc" % "3.5.6",

  // PostgreSQL JDBC
  "org.postgresql" % "postgresql" % "42.7.4",

  // AWS SDK v2 (RDS utilities give us the IAM token)
  "software.amazon.awssdk" % "rds" % "2.25.66"
)
```

---

### application.yml
```yaml
spring:
  datasource:
    url: jdbc:postgresql://<rds-endpoint>:5432/<db>?sslmode=require
    username: app_user_iam
    driver-class-name: org.postgresql.Driver

aws:
  rds:
    region: us-west-2
    hostname: <rds-endpoint>
    port: 5432
```

---

### Scala Code

#### `RdsIamTokenProvider.scala`
```scala
package db

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.rds.{RdsClient, RdsUtilities}
import software.amazon.awssdk.services.rds.auth.GenerateAuthenticationTokenRequest

@Component
final class RdsIamTokenProvider(
  @Value("${aws.rds.hostname}") hostname: String,
  @Value("${aws.rds.port}")     port: Int,
  @Value("${aws.rds.region}")   region: String,
  @Value("${spring.datasource.username}") username: String
) {
  private val utils: RdsUtilities =
    RdsClient.builder().region(Region.of(region)).build().utilities()

  def token(): String =
    utils.generateAuthenticationToken(
      GenerateAuthenticationTokenRequest.builder()
        .hostname(hostname)
        .port(port)
        .username(username)
        .build()
    )
}
```

#### `DataSourceConfig.scala`
```scala
package db

import com.zaxxer.hikari.{HikariConfig, HikariDataSource}
import org.springframework.context.annotation.{Bean, Configuration}
import org.springframework.scheduling.annotation.{EnableScheduling, Scheduled}
import org.springframework.beans.factory.annotation.Value

import javax.sql.DataSource

@Configuration
@EnableScheduling
final class DataSourceConfig(
  tokenProvider: RdsIamTokenProvider,
  @Value("${spring.datasource.url}") jdbcUrl: String,
  @Value("${spring.datasource.username}") username: String
) {

  private val hikari: HikariDataSource = {
    val cfg = new HikariConfig()
    cfg.setJdbcUrl(jdbcUrl)
    cfg.setUsername(username)
    cfg.setPassword(tokenProvider.token())         // initial IAM token
    cfg.setDriverClassName("org.postgresql.Driver")
    cfg.setMaxLifetime(10 * 60 * 1000L)           // 10 min
    cfg.setIdleTimeout(60 * 1000L)                // 1 min
    cfg.setMinimumIdle(1)
    cfg.setMaximumPoolSize(5)
    new HikariDataSource(cfg)
  }

  // refresh pool password every 5 minutes (tokens last ~15)
  @Scheduled(fixedDelay = 5 * 60 * 1000L)
  def refreshToken(): Unit =
    hikari.getHikariConfigMXBean.setPassword(tokenProvider.token())

  @Bean
  def dataSource(): DataSource = hikari
}
```

---

## 2. Minimal Terraform Setup

### Parameter Group (enable IAM auth)
```hcl
resource "aws_db_parameter_group" "pg_iam" {
  name   = "pg16-iam"
  family = "postgres16"

  parameter {
    name  = "rds.iam_authentication"
    value = "1"
  }
}
```

### RDS Instance
```hcl
resource "aws_db_instance" "pg" {
  identifier                   = "myapp-pg"
  engine                       = "postgres"
  engine_version               = "16.3"
  instance_class               = "db.t4g.micro"
  allocated_storage            = 20
  db_name                      = "mydb"
  username                     = "masteruser"
  password                     = "ChangeMeOnce"     # admin only; app won’t use this
  db_subnet_group_name         = aws_db_subnet_group.db.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  publicly_accessible          = false
  skip_final_snapshot          = true

  parameter_group_name         = aws_db_parameter_group.pg_iam.name
  iam_database_authentication_enabled = true
}
```

### Security Groups
```hcl
resource "aws_security_group" "app" {
  name   = "sg-app"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "db" {
  name   = "sg-db"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}
```

### IAM Role and Policy
```hcl
resource "aws_iam_role" "app" {
  name = "myapp-runtime"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "rds_connect" {
  name   = "myapp-rds-connect"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: ["rds-db:connect"],
        Resource: [
          "arn:aws:rds-db:${var.region}:${var.account_id}:dbuser/${aws_db_instance.pg.resource_id}/app_user_iam"
        ]
      },
      {
        Effect: "Allow",
        Action: [
          "rds:DescribeDBInstances", "rds:DescribeDBClusters"
        ],
        Resource: "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.rds_connect.arn
}
```

### One-Time Postgres SQL Setup
```sql
CREATE ROLE app_user_iam WITH LOGIN;
ALTER ROLE app_user_iam WITH rds_iam;
GRANT CONNECT ON DATABASE mydb TO app_user_iam;
```

---

## ✅ Summary

| Layer | Change |
|-------|--------|
| **Code** | Add AWS SDK RDS dep, token generator, refresh Hikari password |
| **Config** | Remove static password, use IAM token dynamically |
| **Terraform** | Enable `rds.iam_authentication`, allow `rds-db:connect`, open port 5432 |
| **Database** | Create `app_user_iam` with `rds_iam` flag |

Once deployed, the app connects to Postgres using AWS IAM auth securely—no passwords needed.
