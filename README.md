## Steps to deploy a Lambda function to AWS using a container image and the AWS CLI:

### Step 1: Prerequisites
- Ensure you have an AWS account

### Step 2: Create a Dockerfile

#### `Dockerfile`:
```Dockerfile
FROM public.ecr.aws/lambda/python:3.12

COPY requirements.txt ${LAMBDA_TASK_ROOT}

RUN pip install uv
RUN uv venv
RUN uv pip install -r requirements.txt

COPY .prefect/ ${LAMBDA_TASK_ROOT}/.prefect/
COPY handlers.py ${LAMBDA_TASK_ROOT}

ENV PREFECT_HOME=${LAMBDA_TASK_ROOT}

CMD [ "handlers.lambda_handler" ]
```

> [!NOTE]
> What is `uv` you ask? [Change your life](https://github.com/astral-sh/uv?tab=readme-ov-file#getting-started) today.

### Step 3: Write your Lambda function code
- Create a new file named `lambda_function.py` (or any desired name) and write your Lambda function code.
- Example Lambda function code:
```python
from prefect import flow

@flow(log_prints=True)
def lambda_handler(event, context):
    """AWS Lambda function entrypoint"""
    print(f"{event=}, {context=}")

    return {"message": "Hello, World!"}
```

> [!TIP]
> To do the rest of the steps automatically, see [this](.github/workflows/deploy.yaml) GitHub Action. Also, use `gh secret set -f .env` to set all environment variables in your `.env` file as GitHub Actions secrets.

<details>
<summary>Manual steps</summary>

### Step 4: Build the Docker image
- Build the Docker image using the Dockerfile.
```console
docker build \
  --platform linux/amd64 \
  --tag your-account-id.dkr.ecr.your-region.amazonaws.com/my-lambda-function:latest \
  .
```

### Step 5: Create an Amazon ECR repository
- Create a new Amazon ECR repository to store your Docker image.
```console
aws ecr create-repository --repository-name my-lambda-function
```

### Step 6: Authenticate with Amazon ECR
- Authenticate your Docker client with Amazon ECR.
```console
aws ecr get-login-password --region your-region | docker login --username AWS --password-stdin your-account-id.dkr.ecr.your-region.amazonaws.com
```


### Step 7: Push the Docker image to Amazon ECR
- Push the tagged Docker image to your Amazon ECR repository.
```console
docker push your-account-id.dkr.ecr.your-region.amazonaws.com/my-lambda-function:latest
```

### Step 8: Create the Lambda function
- Create the Lambda function using the AWS CLI, specifying the function name, package type, code image URI, and IAM role.
```console
aws lambda create-function --function-name my-lambda-function \
  --package-type Image \
  --code ImageUri=your-account-id.dkr.ecr.your-region.amazonaws.com/my-lambda-function:latest \
  --role arn:aws:iam::your-account-id:role/my-lambda-role
```

### Step 9: Set environment variables for the Lambda function
- Set the environment variables for your Lambda function using the AWS CLI.
```console
aws lambda update-function-configuration --function-name my-lambda-function \
  --environment "Variables={ENV_VAR1=value1,ENV_VAR2=value2}"
```

### Step 10: Test the Lambda function
- Invoke the Lambda function to test its functionality.
```console
aws lambda invoke --function-name my-lambda-function response.json
```
- Check the `response.json` file for the function's output.

### Step 11: Update the Lambda function (if needed)
- If you make changes to your Lambda function code or environment variables, rebuild the Docker image, push it to Amazon ECR, and update the function using the AWS CLI.
```console
docker build \
  --platform linux/amd64 \
  --tag your-account-id.dkr.ecr.your-region.amazonaws.com/my-lambda-function:latest .

docker push your-account-id.dkr.ecr.your-region.amazonaws.com/my-lambda-function:latest

aws lambda update-function-code \
  --function-name my-lambda-function \
  --image-uri your-account-id.dkr.ecr.your-region.amazonaws.com/my-lambda-function:latest

aws lambda update-function-configuration \
 --function-name my-lambda-function \
 --environment "Variables={ENV_VAR1=value1,ENV_VAR2=value2}"
```

</details>

Remember to replace `your-region`, `your-account-id`, and other placeholders with your actual AWS region, account ID, and other relevant information. Also, ensure that you have the necessary IAM permissions and follow best practices for securing your Lambda function and associated resources.