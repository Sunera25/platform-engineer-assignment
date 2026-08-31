import os
import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')


def lambda_handler(event, context):
    logger.info(f"Received CloudWatch Alarm event: {json.dumps(event)}")

    cluster_name = os.environ.get('CLUSTER_NAME')
    service_name = os.environ.get('SERVICE_NAME')

    if not cluster_name or not service_name:
        logger.error("Missing required environment variables: CLUSTER_NAME or SERVICE_NAME")
        return {"statusCode": 500, "body": "Configuration Error"}

    try:
        services = ecs_client.describe_services(cluster=cluster_name, services=[service_name])
        if not services.get('services'):
            logger.error(f"Service {service_name} not found in cluster {cluster_name}")
            return {"statusCode": 404, "body": "Service Not Found"}

        current_task_def_arn = services['services'][0]['taskDefinition']
        logger.info(f"Active Task Definition ARN: {current_task_def_arn}")

        task_def_resp = ecs_client.describe_task_definition(taskDefinition=current_task_def_arn)
        task_def = task_def_resp['taskDefinition']

        current_cpu = int(task_def.get('cpu', '256'))
        current_memory = int(task_def.get('memory', '512'))

        # Double allocation each trigger, capped at reasonable maximums
        new_cpu = min(current_cpu * 2, 2048)
        new_memory = min(current_memory * 2, 4096)

        logger.info(
            f"Scaling from CPU={current_cpu} Memory={current_memory} "
            f"to CPU={new_cpu} Memory={new_memory}"
        )

        container_defs = task_def['containerDefinitions']
        for container in container_defs:
            container['cpu'] = new_cpu
            container['memory'] = new_memory

        register_params = {
            'family': task_def['family'],
            'taskRoleArn': task_def.get('taskRoleArn', ''),
            'executionRoleArn': task_def.get('executionRoleArn', ''),
            'networkMode': task_def.get('networkMode', 'bridge'),
            'containerDefinitions': container_defs,
            'requiresCompatibilities': task_def.get('requiresCompatibilities', ['EC2']),
            'cpu': str(new_cpu),
            'memory': str(new_memory),
        }
        # Strip empty optional fields — ECS rejects empty string ARNs
        register_params = {k: v for k, v in register_params.items() if v}

        reg_resp = ecs_client.register_task_definition(**register_params)
        new_task_def_arn = reg_resp['taskDefinition']['taskDefinitionArn']
        logger.info(f"Registered new Task Definition: {new_task_def_arn}")

        update_resp = ecs_client.update_service(
            cluster=cluster_name,
            service=service_name,
            taskDefinition=new_task_def_arn,
            forceNewDeployment=True,
        )
        logger.info(f"Forced redeployment: {update_resp['service']['serviceArn']}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Vertical scaling executed successfully",
                "newTaskDefinition": new_task_def_arn,
                "cpu": new_cpu,
                "memory": new_memory,
            })
        }

    except Exception as e:
        logger.error(f"Error executing vertical scaling: {str(e)}", exc_info=True)
        return {"statusCode": 500, "body": str(e)}
