FROM public.ecr.aws/lambda/python:3.12

COPY requirements.txt ${LAMBDA_TASK_ROOT}

RUN pip install uv
RUN uv venv
RUN uv pip install -r requirements.txt

COPY .prefect/ ${LAMBDA_TASK_ROOT}/.prefect/
COPY entrypoint.py ${LAMBDA_TASK_ROOT}

ENV PREFECT_HOME=${LAMBDA_TASK_ROOT}/.prefect

CMD [ "entrypoint.lambda_handler" ]