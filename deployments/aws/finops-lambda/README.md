# AWS FinOps Cost Anomaly Lambda

This deployment showcases an AWS Lambda function (Python) that analyzes AWS Cost Explorer data, detects cost anomalies, and sends alert emails via Amazon SES.

## Features
- Scheduled daily cost anomaly detection
 - Scheduled to run daily at 1pm EET (11:00 UTC)
- Email alerts for anomalies (SES)
- Easily configurable threshold and recipient

## Setup Steps
1. **Verify Email in SES**: Ensure your alert email is verified in Amazon SES.
2. **Build Lambda Package**:
    - Create `lambda.zip` for deployment:
       - **PowerShell (Windows):**
          1. Open PowerShell in this directory (`deployments/aws/finops-lambda`).
          2. Run:
               ```powershell
               Compress-Archive -Path lambda_function.py -DestinationPath lambda.zip
               ```
       - **Linux/macOS:**
          1. Open a terminal in this directory.
          2. Run:
               ```bash
               zip lambda.zip lambda_function.py
               ```
       - If your Lambda uses dependencies, package them as well (see AWS docs for details).
    - This step is required because Terraform references `lambda.zip` in `main.tf`:
       ```terraform
       filename         = "${path.module}/lambda.zip"
       source_code_hash = filebase64sha256("${path.module}/lambda.zip")
       ```
3. **Configure Terraform Variables**:
   - Set `alert_email` to your SES-verified address.
   - Optionally adjust `anomaly_threshold`.
4. **Deploy with Terraform**:
   - `terraform init`
   - `terraform apply -var="alert_email=your@email.com"`

## Files
- `lambda_function.py`: Python Lambda code
- `main.tf`: Terraform resources
- `variables.tf`: Input variables

## Notes
- Lambda runs daily via CloudWatch Events.
- The schedule is set to 1pm EET (11:00 UTC) using a cron expression in Terraform:
   ```hcl
   schedule_expression = "cron(0 11 * * ? *)"
   ```

### Other Example Schedules

- **7am UTC every day:**
   ```hcl
   schedule_expression = "cron(0 7 * * ? *)"
   ```

- **5am UTC every Sunday at 23:59:**
   ```hcl
   schedule_expression = "cron(59 23 ? * SUN *)"
   ```
- Alerts are sent only if cost anomaly detected.
- SES must be set up in the region used for Lambda.