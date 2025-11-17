# Lambda function to monitor AWS costs and send email alerts on anomalies
import boto3 # AWS SDK for Python
import os # Operating system interface
import json # JSON handling
from datetime import datetime, timedelta # Date and time handling


# Environment variables
EMAIL_TO = os.environ.get('ALERT_EMAIL')  # Email address to send alerts to
THRESHOLD = float(os.environ.get('ANOMALY_THRESHOLD', '1.2'))  # 20% increase

cost_client = boto3.client('ce')  # Cost Explorer client
ses_client = boto3.client('ses')  # Simple Email Service client

# Function to get cost data for the last 7 days
def get_cost_data():
    today = datetime.utcnow().date()
    start = (today - timedelta(days=7)).strftime('%Y-%m-%d')
    end = today.strftime('%Y-%m-%d')
    response = cost_client.get_cost_and_usage(
        TimePeriod={'Start': start, 'End': end},
        Granularity='DAILY',
        Metrics=['UnblendedCost']  # Metric to track unblended cost
    )
    return response['ResultsByTime']

# Function to detect anomalies based on threshold
def detect_anomaly(cost_data):
    costs = []
    for day in cost_data:
        try:
            amount = float(day['Total']['UnblendedCost']['Amount'])
            costs.append(amount)
        except (KeyError, TypeError, ValueError) as e:
            print(f"Skipping day due to missing or invalid data: {e}")
    if len(costs) < 2:
        return False, 0
    # Use mean of previous days for anomaly detection
    if mean_prev > 0 and costs[-1] > mean_prev * THRESHOLD:
        return True, costs[-1]
    return False, costs[-1]


    subject = 'AWS Cost Anomaly Detected'
    body = f"Alert: Cost anomaly detected. Latest daily cost: ${cost:.2f}"
    ses_client.send_email(
        Source=EMAIL_TO,
        Destination={'ToAddresses': [EMAIL_TO]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Text': {'Data': body}}
        }
    )

# Lambda handler function
def lambda_handler(event, context):
    cost_data = get_cost_data()
    anomaly, cost = detect_anomaly(cost_data)
    if anomaly:
        send_email_alert(cost)
    return {
        'statusCode': 200,
        'body': json.dumps({'anomaly': anomaly, 'cost': cost})
    }
